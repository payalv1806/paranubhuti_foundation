const { initializeApp, getApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

// Initialize default Firebase Admin app safely.
let app;
try {
  app = getApp();
} catch (_) {
  app = initializeApp();
}

const db = getFirestore(app);

// Limit concurrent function instances to minimize cost and keep concurrency controlled.
setGlobalOptions({ maxInstances: 5 });

// Firebase Secrets (defined via Firebase Secrets Manager or process.env fallback).
const razorpayKeyId = defineSecret("RAZORPAY_KEY_ID");
const razorpayKeySecret = defineSecret("RAZORPAY_KEY_SECRET");
const razorpayWebhookSecret = defineSecret("RAZORPAY_WEBHOOK_SECRET");
const razorpayDonationPageUrl = defineSecret("RAZORPAY_DONATION_PAGE_URL");

/**
 * Helper to safely retrieve secret values from Cloud Secret Manager or environment variables.
 */
function resolveSecret(secretParam, envName) {
  try {
    const val = secretParam.value();
    if (val && typeof val === "string" && val.trim().length > 0) {
      return val.trim();
    }
  } catch (_) {
    // Secret not bound in this environment (e.g., local emulator)
  }
  return (process.env[envName] || "").trim();
}

// =============================================================================
// STEP 1 & 2: Create Fundraiser Payment Link (Customer decides amount >= ₹100)
// =============================================================================
/**
 * Callable function to create a Razorpay Payment Link for a fundraiser.
 * Enables partial payments so donors can decide any custom amount with a minimum of ₹100.
 * Saves the generated shareable URL directly to the fundraiser document.
 */
exports.createFundraiserPaymentLink = onCall(
  {
    region: "us-central1",
    secrets: [razorpayKeyId, razorpayKeySecret, razorpayDonationPageUrl],
  },
  async (request) => {
    // 1. Verify user authentication.
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Please sign in before creating a payment link."
      );
    }

    const fundraiserId = request.data?.fundraiserId;
    if (
      typeof fundraiserId !== "string" ||
      fundraiserId.trim().length === 0
    ) {
      throw new HttpsError(
        "invalid-argument",
        "A valid fundraiser ID is required."
      );
    }

    const cleanFundraiserId = fundraiserId.trim();

    try {
      // 2. Fetch the fundraiser from Firestore.
      const fundraiserRef = db.collection("fundraisers").doc(cleanFundraiserId);
      const fundraiserSnap = await fundraiserRef.get();

      if (!fundraiserSnap.exists) {
        throw new HttpsError("not-found", "Fundraiser not found.");
      }

      const fundraiser = fundraiserSnap.data();

      // 3. Verify creator ownership or admin privilege.
      const isAdmin =
        request.auth.token.email?.toLowerCase() ===
        "info@paranubhutifoundation.org";

      if (fundraiser.userId !== request.auth.uid && !isAdmin) {
        throw new HttpsError(
          "permission-denied",
          "You cannot create a payment link for this fundraiser."
        );
      }

      // 4. Verify fundraiser status.
      if (fundraiser.status !== "active") {
        throw new HttpsError(
          "failed-precondition",
          "This fundraiser is not active."
        );
      }

      // Hosted Razorpay Donation Page (Customer Decides Amount).
      // Razorpay Payment Pages natively let the donor enter any custom amount with minimum ₹100.
      const defaultPage = "https://pages.razorpay.com/pl_TubwVN0NmxjOSy/view";
      let hostedPageUrl =
        resolveSecret(razorpayDonationPageUrl, "RAZORPAY_DONATION_PAGE_URL") ||
        process.env.RAZORPAY_DONATION_PAGE_URL;

      if (!hostedPageUrl) {
        try {
          const configSnap = await db.collection("config").doc("razorpay").get();
          if (configSnap.exists) {
            hostedPageUrl = configSnap.data()?.donationPageUrl;
          }
        } catch (_) {}
      }

      if (!hostedPageUrl || typeof hostedPageUrl !== "string" || !hostedPageUrl.startsWith("http")) {
        hostedPageUrl = defaultPage;
      }

      // Reuse an existing payment link ONLY if it is already using the clean Payment Page.
      // If it still has an old invoice/payment-link URL, upgrade it to the new clean Donation Page.
      const existingLink = fundraiser.razorpayPaymentLink;
      if (
        existingLink &&
        typeof existingLink === "string" &&
        (existingLink.includes("pages.razorpay.com") || existingLink.includes("rzp.io/rzp"))
      ) {
        return {
          paymentLink: existingLink,
        };
      }

      // Generate the clean Donation Page URL (open amount, no goal due shown).
      const cleanBase = hostedPageUrl.trim();
      const sep = cleanBase.includes("?") ? "&" : "?";
      const shareableUrl = `${cleanBase}${sep}fundraiser_id=${cleanFundraiserId}&title=${encodeURIComponent(
        fundraiser.title || "Birthday Fundraiser"
      )}`;

      await fundraiserRef.update({
        razorpayPaymentLink: shareableUrl,
        razorpayPaymentLinkType: "payment_page",
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        paymentLink: shareableUrl,
      };

      // 5. Calculate goal & amounts in paise.
      // Minimum donation: ₹100 = 10000 paise.
      const MIN_DONATION_PAISE = 10000;
      const goalAmount = Number(fundraiser.goalAmount);
      const totalRaised = Number(fundraiser.totalRaised || 0);

      if (
        !Number.isFinite(goalAmount) ||
        !Number.isFinite(totalRaised) ||
        goalAmount <= 0 ||
        totalRaised < 0
      ) {
        throw new HttpsError(
          "failed-precondition",
          "The fundraiser amount is invalid."
        );
      }

      const remainingRupees = goalAmount - totalRaised;
      if (remainingRupees <= 0) {
        throw new HttpsError(
          "failed-precondition",
          "This fundraiser has already reached its goal."
        );
      }

      // Target amount in paise (must be at least MIN_DONATION_PAISE).
      const remainingPaise = Math.round(remainingRupees * 100);
      const targetAmountPaise = Math.max(remainingPaise, MIN_DONATION_PAISE);
      const minPartialPaise = Math.min(MIN_DONATION_PAISE, targetAmountPaise);

      // 6. Initialize Razorpay client.
      const keyId =
        resolveSecret(razorpayKeyId, "RAZORPAY_KEY_ID") ||
        "rzp_test_TtLTtbKxe7GUIK";
      const keySecret = resolveSecret(razorpayKeySecret, "RAZORPAY_KEY_SECRET");

      if (!keySecret) {
        console.error("Missing RAZORPAY_KEY_SECRET in Secret Manager.");
        throw new HttpsError(
          "failed-precondition",
          "Razorpay API secret is not configured. Please run: firebase functions:secrets:set RAZORPAY_KEY_SECRET"
        );
      }

      const Razorpay = require("razorpay");
      const razorpay = new Razorpay({
        key_id: keyId,
        key_secret: keySecret,
      });

      // 7. Create Payment Link with Customer Decides Amount (partial payments >= ₹100).
      // Unique reference ID (max 40 chars) to prevent "reference_id already exists" on retries.
      const uniqueRefId = `fund_${cleanFundraiserId}_${Date.now()}`.slice(0, 40);

      const paymentLink = await razorpay.paymentLink.create({
        amount: targetAmountPaise,
        currency: "INR",
        accept_partial: true,
        first_min_partial_amount: minPartialPaise, // ₹100 minimum donation
        reference_id: uniqueRefId,
        description:
          "Donation: " +
          String(fundraiser.title || "Birthday Fundraiser").slice(0, 200),
        reminder_enable: false,
        notes: {
          fundraiserId: cleanFundraiserId,
          causeId: fundraiser.causeId || "",
          creatorUid: fundraiser.userId || request.auth.uid,
          causeTitle: fundraiser.causeTitle || "",
        },
      });

      if (!paymentLink.short_url) {
        throw new Error("Razorpay did not return a valid short_url.");
      }

      // 8. Associate and save the shareable URL in the fundraiser doc.
      await fundraiserRef.update({
        razorpayPaymentLink: paymentLink.short_url,
        razorpayPaymentLinkId: paymentLink.id,
        razorpayPaymentLinkStatus: paymentLink.status || "created",
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        paymentLink: paymentLink.short_url,
      };
    } catch (error) {
      if (error instanceof HttpsError || error?.httpErrorCode) {
        throw error;
      }

      console.error(
        "Payment link creation failed details:",
        error?.error || error?.message || error
      );

      const errorDescription =
        error?.error?.description ||
        error?.description ||
        error?.message ||
        "Unable to create the donation link. Please verify Razorpay API keys.";

      throw new HttpsError("failed-precondition", errorDescription);
    }
  }
);

// =============================================================================
// STEP 3 & 4 & 5 & 6: Firebase HTTPS Webhook for Razorpay
// =============================================================================
/**
 * HTTPS Webhook endpoint to receive Razorpay events.
 * 1. Verifies Razorpay webhook signatures against raw request body with timing-safe comparison.
 * 2. Saves successful donations in Firestore (rejects invalid/unsuccessful payment events).
 * 3. Safely updates fundraiser totals using Firestore transactions (prevents duplicates).
 */
exports.razorpayWebhook = onRequest(
  {
    region: "us-central1",
    secrets: [razorpayWebhookSecret, razorpayKeyId, razorpayKeySecret],
  },
  async (req, res) => {
    // Only accept POST requests from Razorpay.
    if (req.method !== "POST") {
      res.setHeader("Allow", "POST");
      return res.status(405).send("Method Not Allowed. Use POST.");
    }

    // -------------------------------------------------------------------------
    // Step 4: Verify Razorpay Webhook Signatures
    // -------------------------------------------------------------------------
    const signature = req.headers["x-razorpay-signature"];

    if (!signature || typeof signature !== "string") {
      console.warn("[Webhook] Missing x-razorpay-signature header.");
      return res.status(400).send("Missing x-razorpay-signature header.");
    }

    const webhookSecret = resolveSecret(
      razorpayWebhookSecret,
      "RAZORPAY_WEBHOOK_SECRET"
    );

    if (!webhookSecret) {
      console.error(
        "[Webhook] RAZORPAY_WEBHOOK_SECRET is not configured on the server."
      );
      return res.status(500).send("Server webhook secret unconfigured.");
    }

    const crypto = require("crypto");

    // Verify against the raw request body Buffer.
    const rawPayload = Buffer.isBuffer(req.rawBody)
      ? req.rawBody
      : Buffer.from(req.rawBody || JSON.stringify(req.body || {}));

    const expectedSignature = crypto
      .createHmac("sha256", webhookSecret)
      .update(rawPayload)
      .digest("hex");

    let isSignatureValid = false;
    try {
      const sigBuffer = Buffer.from(signature, "utf8");
      const expectedBuffer = Buffer.from(expectedSignature, "utf8");

      if (sigBuffer.length === expectedBuffer.length) {
        // Timing-safe comparison to prevent timing attacks.
        isSignatureValid = crypto.timingSafeEqual(sigBuffer, expectedBuffer);
      }
    } catch (err) {
      console.error("[Webhook] Signature verification error:", err);
      isSignatureValid = false;
    }

    if (!isSignatureValid) {
      console.warn("[Webhook] Webhook signature verification failed.");
      return res.status(400).send("Invalid webhook signature.");
    }

    // -------------------------------------------------------------------------
    // Step 5: Process Events & Reject Invalid/Unsuccessful Payments
    // -------------------------------------------------------------------------
    const event = req.body;
    const eventType = event?.event;

    console.log(`[Webhook] Verified event received: ${eventType}`);

    // If the payment failed or is in an unsuccessful state, do NOT record as completed donation.
    if (eventType === "payment.failed") {
      const failedPayment = event.payload?.payment?.entity;
      console.warn(
        `[Webhook] Payment failed: ${failedPayment?.id}, reason: ${failedPayment?.error_description}`
      );
      // Return 200 OK so Razorpay stops retrying failed payment notifications.
      return res.status(200).json({
        received: true,
        status: "ignored_failed_payment",
      });
    }

    // Only process successful payment events.
    const SUCCESSFUL_EVENTS = ["payment.captured", "payment_link.paid", "order.paid"];

    if (!SUCCESSFUL_EVENTS.includes(eventType)) {
      console.log(`[Webhook] Ignored non-payment event: ${eventType}`);
      return res.status(200).json({
        received: true,
        status: "ignored_unhandled_event",
      });
    }

    const paymentEntity = event.payload?.payment?.entity;
    const paymentLinkEntity = event.payload?.payment_link?.entity;

    if (!paymentEntity || !paymentEntity.id) {
      console.warn("[Webhook] No payment entity found in payload.");
      return res.status(200).json({
        received: true,
        status: "missing_payment_entity",
      });
    }

    // Ensure payment status is actually captured/successful.
    if (paymentEntity.status !== "captured" && paymentEntity.captured !== true) {
      console.warn(
        `[Webhook] Payment ${paymentEntity.id} is not captured (status: ${paymentEntity.status}). Skipping.`
      );
      return res.status(200).json({
        received: true,
        status: "payment_not_captured",
      });
    }

    const paymentId = String(paymentEntity.id).trim();
    const amountInPaise = Number(paymentEntity.amount || 0);
    const amountInRupees = Math.round(amountInPaise) / 100;

    if (!Number.isFinite(amountInRupees) || amountInRupees <= 0) {
      console.warn(`[Webhook] Invalid donation amount: ${amountInPaise} paise.`);
      return res.status(200).json({
        received: true,
        status: "invalid_amount",
      });
    }

    // Resolve fundraiser ID flexibly from:
    // 1. Any note key containing "fundraiserid" or "fundraiser" (case-insensitive, e.g. "Fundraiser ID", "fundraiser_id")
    // 2. Reference ID formatted like "fund_<id>_<timestamp>" or "fund_<id>"
    // 3. Payment link ID lookup in Firestore (razorpayPaymentLinkId)
    // 4. Payment link URL lookup in Firestore (razorpayPaymentLink)
    let fundraiserId = null;
    const allNotes = {
      ...(paymentLinkEntity?.notes || {}),
      ...(paymentEntity?.notes || {}),
    };

    for (const [key, value] of Object.entries(allNotes)) {
      if (typeof value === "string" && value.trim().length > 0) {
        const cleanKey = key.toLowerCase().replace(/[^a-z0-9]/g, "");
        if (cleanKey === "fundraiserid" || cleanKey === "fundraiser") {
          fundraiserId = value.trim();
          break;
        }
      }
    }

    if (!fundraiserId) {
      const candidates = [
        paymentLinkEntity?.reference_id,
        paymentEntity?.description,
        allNotes?.reference_id,
        allNotes?.referenceId,
      ];
      for (const cand of candidates) {
        if (typeof cand === "string" && cand.trim().length > 0) {
          const match = cand.match(/^fund_([A-Za-z0-9_-]+?)(?:_\d+)?$/);
          if (match && match[1]) {
            fundraiserId = match[1].trim();
            break;
          }
        }
      }
    }

    if (!fundraiserId && paymentLinkEntity?.id) {
      try {
        const plinkMatchSnap = await db
          .collection("fundraisers")
          .where("razorpayPaymentLinkId", "==", paymentLinkEntity.id)
          .limit(1)
          .get();
        if (!plinkMatchSnap.empty) {
          fundraiserId = plinkMatchSnap.docs[0].id;
        }
      } catch (err) {
        console.warn("[Webhook] Error looking up fundraiser by razorpayPaymentLinkId:", err);
      }
    }

    if (!fundraiserId && paymentLinkEntity?.short_url) {
      try {
        const urlMatchSnap = await db
          .collection("fundraisers")
          .where("razorpayPaymentLink", "==", paymentLinkEntity.short_url)
          .limit(1)
          .get();
        if (!urlMatchSnap.empty) {
          fundraiserId = urlMatchSnap.docs[0].id;
        }
      } catch (err) {
        console.warn("[Webhook] Error looking up fundraiser by razorpayPaymentLink:", err);
      }
    }

    let causeId = null;
    for (const [key, value] of Object.entries(allNotes)) {
      if (typeof value === "string" && value.trim().length > 0) {
        const cleanKey = key.toLowerCase().replace(/[^a-z0-9]/g, "");
        if (cleanKey === "causeid" || cleanKey === "cause") {
          causeId = value.trim();
          break;
        }
      }
    }

    let donorName = null;
    for (const [key, value] of Object.entries(allNotes)) {
      if (typeof value === "string" && value.trim().length > 0) {
        const cleanKey = key.toLowerCase().replace(/[^a-z0-9]/g, "");
        if (cleanKey === "donorname" || cleanKey === "donor" || cleanKey === "fullname" || cleanKey === "name") {
          donorName = value.trim();
          break;
        }
      }
    }
    if (!donorName) {
      donorName = paymentEntity.email ? paymentEntity.email.split("@")[0] : "Kind Supporter";
    }

    const donorEmail = paymentEntity.email || null;
    const donorPhone = paymentEntity.contact || null;
    const paymentMethod = paymentEntity.method || "online";
    const isAnonymous =
      allNotes?.anonymous === "true" ||
      allNotes?.anonymous === true;
    const userId =
      allNotes?.userId ||
      allNotes?.creatorUid ||
      null;

    // -------------------------------------------------------------------------
    // Step 6: Update Fundraiser Totals Safely Using Firestore Transactions
    // -------------------------------------------------------------------------
    try {
      let isDuplicate = false;
      let updatedTotal = null;

      await db.runTransaction(async (transaction) => {
        // Use paymentId as the document ID for strictly guaranteed idempotency.
        const donationRef = db.collection("donations").doc(paymentId);
        const donationSnap = await transaction.get(donationRef);

        // Prevent duplicate donation records and duplicate total updates.
        if (
          donationSnap.exists &&
          donationSnap.data().paymentStatus === "completed"
        ) {
          isDuplicate = true;
          console.log(
            `[Webhook] Donation ${paymentId} already processed. Duplicate skipped.`
          );
          return;
        }

        // If associated with a fundraiser, update its running total atomically.
        if (fundraiserId && typeof fundraiserId === "string" && fundraiserId.trim().length > 0) {
          const cleanFid = fundraiserId.trim();
          const fundraiserRef = db.collection("fundraisers").doc(cleanFid);
          const fundraiserSnap = await transaction.get(fundraiserRef);

          if (fundraiserSnap.exists) {
            const fundraiserData = fundraiserSnap.data();
            const currentTotal = Number(fundraiserData.totalRaised || 0);
            const newTotal = currentTotal + amountInRupees;
            const goalAmount = Number(fundraiserData.goalAmount || 0);
            const currentDonorCount = Number(fundraiserData.donorCount || 0);

            const fundraiserUpdates = {
              totalRaised: newTotal,
              donorCount: currentDonorCount + 1,
              lastDonationAt: FieldValue.serverTimestamp(),
            };

            if (goalAmount > 0 && newTotal >= goalAmount) {
              fundraiserUpdates.isGoalReached = true;
            }

            transaction.update(fundraiserRef, fundraiserUpdates);
            updatedTotal = newTotal;

            // Also increment cause total if linked to a cause doc.
            const linkedCauseId = fundraiserData.causeId || causeId;
            if (linkedCauseId) {
              const causeRef = db.collection("causes").doc(linkedCauseId);
              const causeSnap = await transaction.get(causeRef);
              if (causeSnap.exists) {
                const currentCauseTotal = Number(causeSnap.data().totalRaised || 0);
                transaction.update(causeRef, {
                  totalRaised: currentCauseTotal + amountInRupees,
                });
              }
            }
          } else {
            console.warn(`[Webhook] Fundraiser ${cleanFid} document not found.`);
          }
        }

        // Write verified donation record to Firestore.
        transaction.set(donationRef, {
          paymentId: paymentId,
          razorpayPaymentId: paymentId,
          fundraiserId: fundraiserId ? fundraiserId.trim() : null,
          causeId: causeId || null,
          amount: amountInRupees,
          amountPaise: amountInPaise,
          currency: paymentEntity.currency || "INR",
          donorName: donorName,
          donorEmail: donorEmail,
          donorPhone: donorPhone,
          paymentMethod: paymentMethod,
          paymentStatus: "completed",
          anonymous: isAnonymous,
          userId: userId,
          createdAt: FieldValue.serverTimestamp(),
          verifiedAt: FieldValue.serverTimestamp(),
          source: "razorpay_webhook",
          razorpayEvent: eventType,
        });
      });

      if (isDuplicate) {
        return res.status(200).json({
          received: true,
          status: "duplicate_skipped",
          paymentId: paymentId,
        });
      }

      console.log(
        `[Webhook] Successfully saved donation ${paymentId} of ₹${amountInRupees} (Fundraiser: ${fundraiserId})`
      );

      return res.status(200).json({
        received: true,
        status: "success",
        paymentId: paymentId,
        fundraiserId: fundraiserId || null,
        amount: amountInRupees,
        newFundraiserTotal: updatedTotal,
      });
    } catch (transactionError) {
      console.error(
        `[Webhook] Firestore transaction failed for ${paymentId}:`,
        transactionError
      );
      // Return 500 so Razorpay retries if an intermittent Firestore error occurs.
      return res.status(500).send("Database transaction failed. Please retry.");
    }
  }
);

// =============================================================================
// RECONCILIATION: Reconcile Fundraiser Total Against Successful Donations
// =============================================================================
/**
 * Callable function to reconcile a fundraiser's totalRaised against all verified
 * donations in Firestore. Fixes any discrepancies and recalculates total raised.
 */
exports.reconcileFundraiserTotal = onCall(
  {
    region: "us-central1",
    secrets: [razorpayKeyId, razorpayKeySecret],
  },
  async (request) => {
    // 1. Verify user authentication.
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required to reconcile fundraiser."
      );
    }

    const fundraiserId = request.data?.fundraiserId;
    if (
      typeof fundraiserId !== "string" ||
      fundraiserId.trim().length === 0
    ) {
      throw new HttpsError(
        "invalid-argument",
        "A valid fundraiser ID is required."
      );
    }

    const cleanFundraiserId = fundraiserId.trim();

    const fundraiserRef = db.collection("fundraisers").doc(cleanFundraiserId);
    const fundraiserSnap = await fundraiserRef.get();

    if (!fundraiserSnap.exists) {
      throw new HttpsError("not-found", "Fundraiser not found.");
    }

    const fundraiser = fundraiserSnap.data();
    const isAdmin =
      request.auth.token.email?.toLowerCase() ===
      "info@paranubhutifoundation.org";

    if (fundraiser.userId !== request.auth.uid && !isAdmin) {
      throw new HttpsError(
        "permission-denied",
        "You do not have permission to reconcile this fundraiser."
      );
    }

    // Direct Sync: check Razorpay API for captured payments matching this fundraiser
    const keyId =
      resolveSecret(razorpayKeyId, "RAZORPAY_KEY_ID") ||
      "rzp_test_TtLTtbKxe7GUIK";
    const keySecret = resolveSecret(razorpayKeySecret, "RAZORPAY_KEY_SECRET");

    if (keySecret) {
      try {
        const Razorpay = require("razorpay");
        const rzp = new Razorpay({ key_id: keyId, key_secret: keySecret });
        const paymentsResponse = await rzp.payments.all({ count: 50 });
        const payments = paymentsResponse.items || [];

        for (const payment of payments) {
          if (payment.status !== "captured") continue;

          let matches = false;
          const pNotes = payment.notes || {};
          for (const [k, v] of Object.entries(pNotes)) {
            const cleanK = k.toLowerCase().replace(/[^a-z0-9]/g, "");
            if (
              (cleanK === "fundraiserid" || cleanK === "fundraiser") &&
              String(v).trim() === cleanFundraiserId
            ) {
              matches = true;
              break;
            }
          }

          if (
            !matches &&
            fundraiser.razorpayPaymentLinkId &&
            (payment.description?.includes(fundraiser.razorpayPaymentLinkId) ||
              payment.notes?.payment_link_id === fundraiser.razorpayPaymentLinkId)
          ) {
            matches = true;
          }

          if (!matches && payment.description) {
            const m = payment.description.match(/^fund_([A-Za-z0-9_-]+?)(?:_\d+)?$/);
            if (m && m[1] === cleanFundraiserId) {
              matches = true;
            }
          }

          if (matches) {
            const donRef = db.collection("donations").doc(payment.id);
            const donSnap = await donRef.get();
            if (!donSnap.exists) {
              const pAmt = Math.round(Number(payment.amount || 0)) / 100;
              await donRef.set({
                paymentId: payment.id,
                razorpayPaymentId: payment.id,
                fundraiserId: cleanFundraiserId,
                causeId: fundraiser.causeId || null,
                amount: pAmt,
                amountPaise: payment.amount,
                currency: payment.currency || "INR",
                donorName: payment.email
                  ? payment.email.split("@")[0]
                  : "Kind Supporter",
                donorEmail: payment.email || null,
                donorPhone: payment.contact || null,
                paymentMethod: payment.method || "online",
                paymentStatus: "completed",
                anonymous: false,
                userId: fundraiser.userId || null,
                createdAt: FieldValue.serverTimestamp(),
                verifiedAt: FieldValue.serverTimestamp(),
                source: "razorpay_reconciliation",
              });
              console.log(
                `[Reconcile] Restored missing donation ${payment.id} of ₹${pAmt} for fundraiser ${cleanFundraiserId}`
              );
            }
          }
        }
      } catch (rzpErr) {
        console.warn("[Reconcile] Could not query Razorpay API:", rzpErr.message);
      }
    }

    // 2. Query all completed donations for this fundraiser.
    const donationsSnap = await db
      .collection("donations")
      .where("fundraiserId", "==", cleanFundraiserId)
      .where("paymentStatus", "==", "completed")
      .get();

    let reconciledTotal = 0;
    const uniqueDonors = new Set();

    donationsSnap.forEach((doc) => {
      const data = doc.data();
      const amount = Number(data.amount || 0);
      if (Number.isFinite(amount) && amount > 0) {
        reconciledTotal += amount;
      }
      if (data.donorEmail) {
        uniqueDonors.add(data.donorEmail);
      } else if (data.userId) {
        uniqueDonors.add(data.userId);
      } else {
        uniqueDonors.add(doc.id);
      }
    });

    const goalAmount = Number(fundraiser.goalAmount || 0);
    const isGoalReached = goalAmount > 0 && reconciledTotal >= goalAmount;

    // 3. Atomically update the reconciled values on the fundraiser doc.
    await fundraiserRef.update({
      totalRaised: Math.round(reconciledTotal * 100) / 100,
      donorCount: donationsSnap.size,
      isGoalReached: isGoalReached,
      lastReconciledAt: FieldValue.serverTimestamp(),
    });

    return {
      fundraiserId: cleanFundraiserId,
      reconciledTotal: Math.round(reconciledTotal * 100) / 100,
      donationCount: donationsSnap.size,
      uniqueDonorCount: uniqueDonors.size,
      isGoalReached: isGoalReached,
    };
  }
);


const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const Razorpay = require("razorpay");

// Initialize Firebase Admin.
initializeApp();

const db = getFirestore();

// Limit function instances.
setGlobalOptions({ maxInstances: 3 });

// Firebase Secrets.
const razorpayKeyId = defineSecret("RAZORPAY_KEY_ID");
const razorpayKeySecret = defineSecret("RAZORPAY_KEY_SECRET");

// Create fundraiser payment link.
exports.createFundraiserPaymentLink = onCall(
  {
    region: "us-central1",
    secrets: [razorpayKeyId, razorpayKeySecret],
  },
  async (request) => {
    // Check authentication.
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

    try {
      // Get fundraiser from Firestore.
      const fundraiserRef = db
        .collection("fundraisers")
        .doc(fundraiserId.trim());

      const fundraiserSnap = await fundraiserRef.get();

      if (!fundraiserSnap.exists) {
        throw new HttpsError("not-found", "Fundraiser not found.");
      }

      const fundraiser = fundraiserSnap.data();

      // Check fundraiser ownership.
      if (fundraiser.userId !== request.auth.uid) {
        throw new HttpsError(
          "permission-denied",
          "You cannot create a payment link for this fundraiser."
        );
      }

      // Check fundraiser status.
      if (fundraiser.status !== "active") {
        throw new HttpsError(
          "failed-precondition",
          "This fundraiser is not active."
        );
      }

      // Reuse an existing payment link.
      if (fundraiser.razorpayPaymentLink) {
        return {
          paymentLink: fundraiser.razorpayPaymentLink,
        };
      }

      // Calculate remaining fundraiser amount.
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

      const remainingAmount = Math.round(
        (goalAmount - totalRaised) * 100
      );

      if (remainingAmount <= 0) {
        throw new HttpsError(
          "failed-precondition",
          "This fundraiser has already reached its goal."
        );
      }

      // Initialize Razorpay.
      const razorpay = new Razorpay({
        key_id: razorpayKeyId.value(),
        key_secret: razorpayKeySecret.value(),
      });

      // Create payment link with partial payments enabled.
      const paymentLink = await razorpay.paymentLink.create({
        amount: remainingAmount,
        currency: "INR",
        accept_partial: true,
        first_min_partial_amount: 100,
        reference_id: fundraiserId.trim(),
        description:
          "Donation: " +
          String(fundraiser.title || "Birthday Fundraiser").slice(0, 200),
        reminder_enable: false,
        notes: {
          fundraiserId: fundraiserId.trim(),
          creatorUid: request.auth.uid,
        },
      });

      if (!paymentLink.short_url) {
        throw new Error("Razorpay did not return a payment URL.");
      }

      // Save payment link in Firestore.
      await fundraiserRef.update({
        razorpayPaymentLink: paymentLink.short_url,
        razorpayPaymentLinkId: paymentLink.id,
        razorpayPaymentLinkStatus: paymentLink.status,
      });

      return {
        paymentLink: paymentLink.short_url,
      };
    } catch (error) {
      // Preserve Firebase errors.
      if (error instanceof HttpsError) {
        throw error;
      }

      console.error("Payment link creation failed:", error);

      throw new HttpsError(
        "internal",
        "Unable to create the donation link. Please try again."
      );
    }
  }
);

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const Razorpay = require('razorpay');

const app = express();
const PORT = process.env.PORT || 5000;

// CORS configuration
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
  : ['http://localhost:3000', 'http://localhost:5000', 'http://localhost:8080'];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (like mobile apps or curl) or if origin is in list/netlify
      if (!origin || allowedOrigins.includes(origin) || origin.endsWith('.netlify.app')) {
        return callback(null, true);
      }
      return callback(null, true); // Permissive in dev to avoid blocking frontend
    },
    credentials: true,
  })
);

app.use(express.json());

// Initialize Razorpay instance if keys are provided
const getRazorpayInstance = () => {
  const key_id = process.env.RAZORPAY_KEY_ID;
  const key_secret = process.env.RAZORPAY_KEY_SECRET;
  if (!key_id || !key_secret) {
    throw new Error('RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET must be set in environment variables');
  }
  return new Razorpay({ key_id, key_secret });
};

// Health Check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    app: 'Pranubhuti Foundation API',
    timestamp: new Date().toISOString(),
    razorpayConfigured: Boolean(process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET),
  });
});

// Public payment config (safe key ID only)
app.get('/api/payment/config', (req, res) => {
  res.json({
    success: true,
    keyId: process.env.RAZORPAY_KEY_ID || '',
    currency: 'INR',
    foundation: 'Paranubhuti Foundation',
  });
});

// 1. Create Razorpay Order
app.post('/api/payment/create-order', async (req, res) => {
  try {
    const { amount, currency = 'INR', donationId, causeId } = req.body;

    if (!amount || Number(amount) <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid donation amount' });
    }

    const rzp = getRazorpayInstance();
    const amountInPaise = Math.round(Number(amount) * 100);
    const receipt = `rcpt_${(donationId || Date.now().toString()).slice(-10)}_${Date.now().toString().slice(-4)}`;

    const options = {
      amount: amountInPaise,
      currency,
      receipt,
      notes: {
        donationId: donationId || `PF_${Date.now()}`,
        causeId: causeId || 'general',
        foundation: 'Paranubhuti Foundation',
      },
    };

    const order = await rzp.orders.create(options);

    res.json({
      success: true,
      orderId: order.id,
      amount: order.amount,
      currency: order.currency,
      keyId: process.env.RAZORPAY_KEY_ID,
    });
  } catch (error) {
    console.error('Error creating Razorpay order:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to create Razorpay order',
    });
  }
});

// 2. Verify Razorpay Payment Signature
app.post('/api/payment/verify-payment', (req, res) => {
  try {
    const {
      razorpay_order_id,
      orderId = razorpay_order_id,
      razorpay_payment_id,
      paymentId = razorpay_payment_id,
      razorpay_signature,
      signature = razorpay_signature,
      donationId,
    } = req.body;

    const key_secret = process.env.RAZORPAY_KEY_SECRET;
    if (!key_secret) {
      return res.status(500).json({
        success: false,
        error: 'RAZORPAY_KEY_SECRET is not configured on the server',
      });
    }

    if (!orderId || !paymentId || !signature) {
      return res.status(400).json({
        success: false,
        error: 'Missing required parameters: orderId, paymentId, or signature',
      });
    }

    // HMAC SHA-256 verification
    const generatedSignature = crypto
      .createHmac('sha256', key_secret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');

    const isValid = generatedSignature === signature;

    if (!isValid) {
      return res.status(400).json({
        success: false,
        verified: false,
        error: 'Payment verification failed: Invalid signature',
      });
    }

    res.json({
      success: true,
      verified: true,
      message: 'Payment signature verified successfully',
      orderId,
      paymentId,
      donationId,
      verifiedAt: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Error verifying payment:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Internal server error verifying payment',
    });
  }
});

app.listen(PORT, () => {
  console.log(`Pranubhuti Foundation Backend running on port ${PORT}`);
});

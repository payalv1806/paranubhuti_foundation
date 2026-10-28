const crypto = require('crypto');

exports.handler = async (event, context) => {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Content-Type': 'application/json',
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ success: false, error: 'Method not allowed' }),
    };
  }

  try {
    const keySecret = process.env.RAZORPAY_KEY_SECRET;

    if (!keySecret) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          success: false,
          error: 'Payment secret not configured on the server. Please set RAZORPAY_KEY_SECRET.',
        }),
      };
    }

    const data = JSON.parse(event.body || '{}');
    const orderId = data.razorpay_order_id || data.orderId;
    const paymentId = data.razorpay_payment_id || data.paymentId;
    const signature = data.razorpay_signature || data.signature;
    const donationId = data.donationId;

    if (!orderId || !paymentId || !signature) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          success: false,
          error: 'Missing required payment verification parameters (orderId, paymentId, signature).',
        }),
      };
    }

    // Cryptographic signature verification: HMAC SHA256 of "orderId|paymentId" with keySecret
    const expectedSignature = crypto
      .createHmac('sha256', keySecret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');

    const isMatch = expectedSignature === signature;

    if (!isMatch) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          success: false,
          verified: false,
          error: 'Cryptographic signature mismatch. Payment verification failed.',
        }),
      };
    }

    // Payment signature is 100% verified and authentic
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        success: true,
        verified: true,
        message: 'Payment signature verified successfully.',
        paymentId,
        orderId,
        donationId,
        verifiedAt: new Date().toISOString(),
      }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        success: false,
        error: error.message || 'Internal server error verifying payment',
      }),
    };
  }
};

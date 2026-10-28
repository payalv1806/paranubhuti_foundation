const https = require('https');

exports.handler = async (event, context) => {
  // CORS Headers
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
    const keyId = process.env.RAZORPAY_KEY_ID;
    const keySecret = process.env.RAZORPAY_KEY_SECRET;

    if (!keyId || !keySecret) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          success: false,
          error: 'Razorpay keys not configured. Please set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET in environment variables.',
        }),
      };
    }

    const data = JSON.parse(event.body || '{}');
    const amount = Number(data.amount);
    const currency = data.currency || 'INR';
    const donationId = data.donationId || `PF_${Date.now()}`;
    const causeId = data.causeId || 'general';

    if (!amount || amount <= 0) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ success: false, error: 'Invalid donation amount' }),
      };
    }

    // Razorpay amounts are in the smallest currency unit (paise for INR)
    const amountInPaise = Math.round(amount * 100);
    const receipt = `rcpt_${donationId.slice(-10)}_${Date.now().toString().slice(-4)}`;

    const postData = JSON.stringify({
      amount: amountInPaise,
      currency,
      receipt,
      notes: {
        donationId,
        causeId,
        foundation: 'Paranubhuti Foundation',
      },
    });

    const authHeader = 'Basic ' + Buffer.from(`${keyId}:${keySecret}`).toString('base64');

    const orderResponse = await new Promise((resolve, reject) => {
      const options = {
        hostname: 'api.razorpay.com',
        port: 443,
        path: '/v1/orders',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData),
          'Authorization': authHeader,
        },
      };

      const req = https.request(options, (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          try {
            const parsed = JSON.parse(body);
            if (res.statusCode >= 200 && res.statusCode < 300) {
              resolve(parsed);
            } else {
              reject(new Error(parsed.error ? parsed.error.description : 'Failed to create Razorpay order'));
            }
          } catch (e) {
            reject(new Error('Invalid response from Razorpay: ' + body));
          }
        });
      });

      req.on('error', (err) => reject(err));
      req.write(postData);
      req.end();
    });

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        success: true,
        orderId: orderResponse.id,
        amount: orderResponse.amount,
        currency: orderResponse.currency,
        keyId: keyId, // Safe to send public key ID to client
      }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        success: false,
        error: error.message || 'Error creating donation payment order',
      }),
    };
  }
};

exports.handler = async (event, context) => {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Content-Type': 'application/json',
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers, body: '' };
  }

  const keyId = process.env.RAZORPAY_KEY_ID || '';

  return {
    statusCode: 200,
    headers,
    body: JSON.stringify({
      success: true,
      keyId: keyId,
      currency: 'INR',
      foundation: 'Paranubhuti Foundation',
    }),
  };
};

# Pranubhuti Foundation Backend Server

This is the Node.js / Express backend server for Pranubhuti Foundation. It provides secure Razorpay payment order creation and server-side cryptographic signature verification.

## 🚀 Running Locally

1. Open a terminal in the `server` directory:
   ```bash
   cd server
   npm install
   ```

2. Create a `.env` file from `.env.example`:
   ```bash
   cp .env.example .env
   ```

3. Fill in your Razorpay Test Key ID and Key Secret from the [Razorpay Dashboard](https://dashboard.razorpay.com/app/keys).

4. Start the server:
   ```bash
   npm start
   ```
   The backend will run on `http://localhost:5000`.

---

## ☁️ Deploying to Render (Free / Recommended)

1. Go to [Render.com](https://render.com) and click **New +** -> **Web Service**.
2. Connect your GitHub repository (`paranubhuti_foundation`).
3. Set the following settings:
   - **Root Directory**: `server`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `node index.js`
4. Under **Environment Variables**, add:
   - `RAZORPAY_KEY_ID`: Your Razorpay Key ID
   - `RAZORPAY_KEY_SECRET`: Your Razorpay Key Secret
   - `ALLOWED_ORIGINS`: Your Netlify frontend URL (e.g. `https://paranubhutifoundation.netlify.app`)
5. Click **Deploy Web Service**. You will receive a URL like `https://paranubhuti-backend.onrender.com`.

---

## ⚡ Built-In Netlify Alternative (Zero Hosting Needed)

If you host your frontend on Netlify, serverless functions are already set up in `netlify/functions/`:
- `create-order`: `/.netlify/functions/create-order`
- `verify-payment`: `/.netlify/functions/verify-payment`
- `config`: `/.netlify/functions/config`

Simply add `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` in **Netlify Dashboard -> Site Configuration -> Environment Variables**.
No separate hosting server is required!

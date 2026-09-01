# Razorpay setup

This backend uses Razorpay Standard Checkout with server-side order creation, server-side signature verification, and a durable webhook inbox.

## 1. Environment variables

Copy `.env.example` to `.env` and set:

- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `RAZORPAY_WEBHOOK_SECRET`
- `RAZORPAY_AMOUNT_PAISE` (for example `99900` = INR 999)
- `RAZORPAY_CURRENCY=INR`
- `RAZORPAY_DEFAULT_PLAN=Starter`

Never expose `RAZORPAY_KEY_SECRET` or `RAZORPAY_WEBHOOK_SECRET` to the browser.

## 2. Database

Run:

`supabase/migrations/20260812_production_saas.sql`

in the existing Supabase project.

## 3. Create a payment order

Frontend calls:

`POST /api/payments/razorpay/create-order`

Body:

```json
{
  "business_name": "Glow Beauty Studio",
  "owner_name": "Anmol Das",
  "email": "owner@example.com",
  "phone": "+919876543210",
  "industry": "beauty",
  "plan": "Starter"
}
```

The response contains `order_id`, `amount`, `currency`, and the public `key_id` needed by Razorpay Checkout.

## 4. Open Razorpay Checkout

Load Razorpay's official Checkout script in the website and pass the server-created `order_id` to Checkout. The secret key never goes to the browser.

After success, send these three values to the backend:

`razorpay_order_id`, `razorpay_payment_id`, `razorpay_signature`

## 5. Verify payment

Frontend calls:

`POST /api/payments/razorpay/verify`

The backend:

1. Loads the order from Supabase using the server-side order ID.
2. Verifies the HMAC-SHA256 checkout signature.
3. Fetches the payment from Razorpay.
4. Requires `captured` status.
5. Checks order ID, amount, and currency.
6. Creates the client in Supabase.
7. Returns `client_id` and a 24-hour onboarding setup token.

## 6. Webhook

Configure this Razorpay webhook URL:

`https://YOUR_API_DOMAIN/api/payments/razorpay/webhook`

Use a strong webhook secret and subscribe at minimum to:

- `payment.captured`
- `payment.failed`

The backend verifies the raw-body webhook signature, stores the event in a durable Supabase inbox, returns HTTP 200 immediately, and processes the inbox asynchronously.

## 7. Client onboarding

After payment verification, send the customer to your onboarding page with the returned setup token. The setup token is used by the registration endpoint to bind the owner account to the newly-created `client_id`.

## Test mode first

Use Razorpay Test Mode until the complete flow passes:

Payment → verified payment → client created → onboarding token → owner registration → Google OAuth → configuration.

Only then switch to Live Mode and configure the production HTTPS webhook.

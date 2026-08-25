# Deploy Firebase Python Functions

## One-time project setup

Gen-2 functions require the Compute Engine API plus Mollie and Resend secrets:

```sh
gcloud services enable compute.googleapis.com --project rize-11838
firebase functions:secrets:set MOLLIE_API_KEY
firebase functions:secrets:set RESEND_API_KEY
```

If `gcloud` is not installed, enable `compute.googleapis.com` in the Google
Cloud API Library for project `rize-11838`, wait a few minutes, and continue.

Never put Mollie or Resend keys into `main.py` or a checked-in `.env` file.
Rotate the previously committed Mollie test key before the next deployment.

Before enabling invoice email, verify a domain in Resend (SPF and DKIM) and
configure the non-secret runtime values for the Functions environment:

```sh
RESEND_FROM_EMAIL="RIZE · Coach Flo <rechnung@coach-flo.de>"
BILLING_REPLY_TO="info@coach-flo.de"
PUBLIC_FUNCTIONS_BASE_URL="https://europe-west1-rize-11838.cloudfunctions.net"
APP_RETURN_URL="https://rize-11838.web.app/payment-complete"
```

`RESEND_FROM_EMAIL` must use a domain that is verified in the Resend account.
The payment return URL must be deployed before live Mollie payments are enabled.
The invoice issuer fields from the reference document are the defaults and can
be overridden with `INVOICE_LEGAL_NAME`, `INVOICE_STREET`,
`INVOICE_POSTAL_CITY`, `INVOICE_PHONE`, `INVOICE_EMAIL`, `INVOICE_WEBSITE`,
`INVOICE_BANK_NAME`, `INVOICE_IBAN`, `INVOICE_BIC`, and `INVOICE_TAX_NOTE`.

# 1. Navigate to functions folder
cd functions

# 2. Activate virtual environment (if used)
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Login to Firebase (if needed)
firebase login

# 5. Select Firebase project (if needed)
firebase use <your-project-id>

# 6. Deploy specific function
firebase deploy --only functions

---

# Optional: View logs
firebase functions:log

## Billing endpoints

All user endpoints require `Authorization: Bearer <Firebase ID token>`.

- `update_billing_profile` - store the invoice recipient name/address.
- `list_invoices` - list up to 50 invoices for the signed-in user.
- `download_invoice?invoiceId=<Mollie payment id>` - download the owner's PDF.
- `resend_invoice` - resend an existing invoice to the owner's auth email.
- `create_invoice` - admin-only backfill from a verified paid Mollie payment;
  requires an `admin` or `billingAdmin` custom claim.

Paid Mollie webhooks create one immutable invoice per payment, allocate an
annual sequential invoice number, and send the PDF via Resend. Initial payment,
renewal, payment failure, user cancellation, and Mollie-side subscription end
have dedicated email templates. A daily reconciliation function checks Mollie
subscription state because classic subscription webhooks report payments, not
subscription status changes.

# Deploy Firebase Python Functions

## One-time project setup

Gen-2 functions require the Compute Engine API and a Mollie secret:

```sh
gcloud services enable compute.googleapis.com --project rize-11838
firebase functions:secrets:set MOLLIE_API_KEY
```

If `gcloud` is not installed, enable `compute.googleapis.com` in the Google
Cloud API Library for project `rize-11838`, wait a few minutes, and continue.

Never put a Mollie key into `main.py` or a checked-in `.env` file.

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

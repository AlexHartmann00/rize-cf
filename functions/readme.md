# Deploy Firebase Python Scheduled Function

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
firebase deploy --only functions:send_spin_reminders

---

# Optional: View logs
firebase functions:log
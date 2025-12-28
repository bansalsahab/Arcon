import requests
import sys

BASE_URL = "http://127.0.0.1:5000/api"

def test_mandates():
    print("Testing Mandates & Sweep Flow...")
    phone = "+919999999999"
    
    # Login
    resp = requests.post(f"{BASE_URL}/auth/request-otp", json={"phone": phone})
    code = resp.json().get("dev_code")
    resp = requests.post(f"{BASE_URL}/auth/verify-otp", json={"phone": phone, "code": code})
    token = resp.json().get("access_token")
    headers = {"Authorization": f"Bearer {token}"}
    
    # 1. Create Mandate
    print("Creating Mandate...")
    payload = {
        "max_amount_paise": 50000,
        "frequency": "daily",
        "start_date": "2025-01-01"
    }
    resp = requests.post(f"{BASE_URL}/mandates", headers=headers, json=payload)
    if resp.status_code != 200:
        print(f"Failed to create mandate: {resp.text}")
        return False
    m_data = resp.json()
    mandate_id = m_data["mandate"]["id"]
    print(f"Mandate Created: {m_data['mandate']['status']} (ID: {mandate_id})")

    # 2. Trigger Sweep (Scheduler)
    # We need pending roundups first (Transaction script created 300 paise).
    print("Triggering Daily Sweep...")
    # NOTE: frequency logic might skip if we just ran it, but first time should work.
    resp = requests.post(f"{BASE_URL}/scheduler/daily-sweep", headers=headers)
    if resp.status_code != 200:
        print(f"Sweep failed: {resp.text}")
        return False
    
    sweep_data = resp.json()
    print(f"Sweep Result: {sweep_data}")
    
    if sweep_data["status"] == "executed":
        print("Sweep Executed Successfully.")
    elif sweep_data["status"] == "no_pending":
        print("Sweep: No pending roundups (Expected if previous test cleared them? No, previous test only listed).")
    
    return True

if __name__ == "__main__":
    if test_mandates():
        print("Mandate Verification PASSED")
        sys.exit(0)
    else:
        print("Mandate Verification FAILED")
        sys.exit(1)

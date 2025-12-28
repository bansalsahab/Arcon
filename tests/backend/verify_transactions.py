import requests
import sys

BASE_URL = "http://127.0.0.1:5000/api"

def test_transactions():
    print("Testing Transaction & Roundup Flow...")
    phone = "+919999999999"
    
    # 1. Login
    resp = requests.post(f"{BASE_URL}/auth/request-otp", json={"phone": phone})
    code = resp.json().get("dev_code")
    resp = requests.post(f"{BASE_URL}/auth/verify-otp", json={"phone": phone, "code": code})
    token = resp.json().get("access_token")
    headers = {"Authorization": f"Bearer {token}"}
    
    print("Logged in.")

    # 2. Set Rounding Base to 10
    print("Setting rounding base to 10...")
    requests.patch(f"{BASE_URL}/user/settings", headers=headers, json={"rounding_base": 10})
    
    # 3. Create Transaction (247 INR) -> Expect 3 INR Roundup (250 - 247)
    print("Creating Transaction of 247 INR...")
    payload = {"amount": 247, "merchant": "Test Merchant"}
    resp = requests.post(f"{BASE_URL}/transactions", headers=headers, json=payload)
    if resp.status_code != 200:
        print(f"Failed to create transaction: {resp.text}")
        return False
    data = resp.json()
    print(f"Transaction Response: {data}")
    
    roundup = data.get("roundup")
    if not roundup:
        print("No roundup created!")
        return False
    
    expected_paise = 300 # 3 INR
    if roundup["amount_paise"] != expected_paise:
        print(f"Roundup mismatch. Expected {expected_paise}, got {roundup['amount_paise']}")
        return False
    
    # 4. Check Pending Roundups
    print("Checking Pending Roundups...")
    resp = requests.get(f"{BASE_URL}/roundups/pending", headers=headers)
    pending_data = resp.json()
    print(f"Pending: {pending_data}")
    
    # Ensure our 300 paise is in total (might be more if re-run)
    if pending_data["total_paise"] < 300:
        print("Pending total is less than expected.")
        return False

    return True

if __name__ == "__main__":
    if test_transactions():
        print("Transaction Verification PASSED")
        sys.exit(0)
    else:
        print("Transaction Verification FAILED")
        sys.exit(1)

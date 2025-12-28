import requests
import sys
import time

BASE_URL = "http://127.0.0.1:5000/api"

def test_investments():
    print("Testing Investment Integration...")
    phone = "+919999999999"
    
    # Login
    resp = requests.post(f"{BASE_URL}/auth/request-otp", json={"phone": phone})
    code = resp.json().get("dev_code")
    resp = requests.post(f"{BASE_URL}/auth/verify-otp", json={"phone": phone, "code": code})
    token = resp.json().get("access_token")
    headers = {"Authorization": f"Bearer {token}"}
    
    # 1. Ensure we have pending roundups
    # Create a transaction 1247 -> 3.00 roundup
    print("Creating Transaction...")
    requests.post(f"{BASE_URL}/transactions", headers=headers, json={"amount": 1247, "merchant": "Inv Test"})
    
    # 2. Trigger Sweep (Execute directly to bypass frequency)
    print("Triggering Investment Execution...")
    resp = requests.post(f"{BASE_URL}/investments/execute", headers=headers, json={"product_type": "mf"})
    
    # 3. Check Orders
    print("Checking Investment Orders...")
    resp = requests.get(f"{BASE_URL}/investments", headers=headers)
    if resp.status_code != 200:
         print(f"Failed to list investments: {resp.text}")
         return False
    
    orders = resp.json()
    print(f"Orders found: {len(orders)}")
    if not orders:
        print("No orders found. Sweep might have been skipped or failed.")
        # If skipped, we can't verify unless we force or check logs.
        # But verify_mandates created one, so we should see at least one.
        return False
        
    latest_order = orders[0]
    print(f"Latest Order: {latest_order}")
    
    if not latest_order.get("external_order_id"):
         print("External Order ID missing! Provider integration failed.")
         return False
         
    if not str(latest_order.get("external_order_id")).startswith("MOCK-"):
         print("External Order ID format unknown (expected MOCK- prefix).")
         return False
         
    print("Investment Verification PASSED")
    return True

if __name__ == "__main__":
    if test_investments():
        sys.exit(0)
    else:
        print("Investment Verification FAILED")
        sys.exit(1)

"""
Test Razorpay mandate creation via HTTP API
"""
import requests
import json

BASE_URL = "http://127.0.0.1:5000"

print("\n" + "="*70)
print("RAZORPAY UPI AUTOPAY - END-TO-END TEST")
print("="*70)

# Step 1: Login to get auth token
print("\n[STEP 1] Logging in...")
try:
    # Request OTP
    res = requests.post(f"{BASE_URL}/api/auth/request-otp", json={"phone": "9414956366"})
    otp_data = res.json()
    dev_code = otp_data.get("dev_code")
    print(f"  OTP: {dev_code}")
    
    # Verify OTP
    res = requests.post(f"{BASE_URL}/api/auth/verify-otp", json={"phone": "9414956366", "code": dev_code})
    auth_data = res.json()
    token = auth_data["access_token"]
    print(f"  ✓ Logged in, token: {token[:20]}...")
except Exception as e:
    print(f"  ✗ Login failed: {e}")
    exit(1)

# Step 2: Create Mandate
print("\n[STEP 2] Creating UPI AutoPay mandate...")
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

try:
    res = requests.post(
        f"{BASE_URL}/api/mandates",
        headers=headers,
        json={}  # Use defaults
    )
    
    if res.status_code != 200:
        print(f"  ✗ Failed: {res.status_code} - {res.text}")
        exit(1)
    
    mandate_data = res.json()
    print(f"\n  ✓ Mandate created successfully!")
    print(f"\n  📋 Mandate Details:")
    print(json.dumps(mandate_data, indent=4))
    
    auth_link = mandate_data.get("auth_link")
    if auth_link:
        print(f"\n  🔗 UPI Authorization Link:")
        print(f"  {auth_link}")
        print(f"\n  👉 Open this link in browser to authorize the mandate!")
        print(f"  👉 Or test in Flutter app's Mandates screen")
    else:
        print(f"\n  ⚠️  No auth_link - check if UPI_PROVIDER=razorpay in .env")
    
    # Step 3: List mandates
    print("\n[STEP 3] Listing mandates...")
    res = requests.get(f"{BASE_URL}/api/mandates", headers=headers)
    mandates = res.json()
    print(f"  ✓ Found {len(mandates)} mandate(s)")
    
    if mandates:
        for m in mandates:
            print(f"    - ID: {m['id']}, Status: {m['status']}, Max: ₹{m['max_amount_paise']/100}")
    
    print("\n" + "="*70)
    print("✅ TEST COMPLETED SUCCESSFULLY")
    print("="*70)
    print("\nNext: Open the auth_link above to authorize the mandate in UPI app")
    print("Or go to Mandates screen in Flutter app and create a mandate there")
    
except Exception as e:
    print(f"  ✗ Error: {e}")
    import traceback
    traceback.print_exc()

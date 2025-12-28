import requests
import sys

BASE_URL = "http://127.0.0.1:5000/api"

def test_profile_kyc():
    print("Testing Profile & KYC Flow...")
    phone = "+919999999999"
    
    # Login again to get token
    # 1. Request OTP
    resp = requests.post(f"{BASE_URL}/auth/request-otp", json={"phone": phone})
    data = resp.json()
    code = data.get("dev_code")
    
    # 2. Verify OTP
    resp = requests.post(f"{BASE_URL}/auth/verify-otp", json={"phone": phone, "code": code})
    auth_data = resp.json()
    token = auth_data.get("access_token")
    headers = {"Authorization": f"Bearer {token}"}
    
    print("Logged in.")

    # 3. Get Profile
    print("Getting Profile...")
    resp = requests.get(f"{BASE_URL}/user/profile", headers=headers)
    if resp.status_code != 200:
        print(f"Failed to get profile: {resp.text}")
        return False
    print(f"Profile: {resp.json()}")

    # 4. Update Profile
    print("Updating Profile...")
    new_name = "Test User Updated"
    resp = requests.patch(f"{BASE_URL}/user/profile", headers=headers, json={"full_name": new_name})
    if resp.status_code != 200:
        print(f"Failed to update profile: {resp.text}")
        return False
    if resp.json().get("full_name") != new_name:
        print("Profile name mismatch")
        return False
    print("Profile Updated.")

    # 5. Check KYC (Empty)
    print("Checking initial KYC...")
    resp = requests.get(f"{BASE_URL}/kyc", headers=headers)
    kyc_data = resp.json()
    print(f"Initial KYC Status: {kyc_data.get('status')}")

    # 6. Start KYC
    print("Starting KYC...")
    kyc_payload = {"pan": "ABCDE1234F", "aadhaar_last4": "1234"}
    resp = requests.post(f"{BASE_URL}/kyc/start", headers=headers, json=kyc_payload)
    if resp.status_code != 200:
        print(f"Failed to start KYC: {resp.text}")
        return False
    print(f"KYC Started: {resp.json()}")

    # 7. Verify KYC
    print("Verifying KYC...")
    resp = requests.post(f"{BASE_URL}/kyc/verify", headers=headers)
    if resp.status_code != 200:
        print(f"Failed to verify KYC: {resp.text}")
        return False
    final_kyc = resp.json()
    print(f"Final KYC Status: {final_kyc.get('status')}")
    
    if final_kyc.get("status") != "verified":
        print("KYC verification failed (status not verified)")
        return False

    return True

if __name__ == "__main__":
    if test_profile_kyc():
        print("Profile & KYC Verification PASSED")
        sys.exit(0)
    else:
        print("Profile & KYC Verification FAILED")
        sys.exit(1)

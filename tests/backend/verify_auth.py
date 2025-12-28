import requests
import sys

BASE_URL = "http://127.0.0.1:5000/api"

def test_auth_flow():
    print("Testing Auth Flow...")
    phone = "+919999999999"
    
    # 1. Request OTP
    print(f"Requesting OTP for {phone}...")
    resp = requests.post(f"{BASE_URL}/auth/request-otp", json={"phone": phone})
    if resp.status_code != 200:
        print(f"Failed to request OTP: {resp.text}")
        return False
    data = resp.json()
    print(f"OTP Response: {data}")
    code = data.get("dev_code")
    if not code:
        print("No dev_code returned (is app in debug mode?)")
        return False

    # 2. Verify OTP
    print(f"Verifying OTP {code}...")
    resp = requests.post(f"{BASE_URL}/auth/verify-otp", json={"phone": phone, "code": code})
    if resp.status_code != 200:
        print(f"Failed to verify OTP: {resp.text}")
        return False
    
    auth_data = resp.json()
    token = auth_data.get("access_token")
    user = auth_data.get("user")
    print(f"Login Success! User ID: {user['id']}")

    # 3. Check /me
    print("Checking /me endpoint...")
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.get(f"{BASE_URL}/auth/me", headers=headers)
    if resp.status_code != 200:
        print(f"Failed to get /me: {resp.text}")
        return False
    
    print(f"User Details: {resp.json()}")
    return True

if __name__ == "__main__":
    try:
        if test_auth_flow():
            print("Auth Verification PASSED")
            sys.exit(0)
        else:
            print("Auth Verification FAILED")
            sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

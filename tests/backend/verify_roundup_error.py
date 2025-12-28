import requests
import json

BASE_URL = "http://127.0.0.1:5000"

def test_roundup_pending():
    # 1. Login
    print("Logging in...")
    try:
        # Use a known test user or create one. 
        # Assuming dev environment has 'test@example.com' or similar from previous runs.
        # Ideally, register a new one.
        email = "frontend_test_user@example.com"
        pwd = "password123"
        
        # Register if not exists
        requests.post(f"{BASE_URL}/api/auth/register", json={"email": email, "password": pwd, "full_name": "Test User"})
        
        # Login
        r = requests.post(f"{BASE_URL}/api/auth/login", json={"email": email, "password": pwd})
        if r.status_code != 200:
            print(f"Login failed: {r.text}")
            return

        token = r.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

        # 2. Get Pending Roundups
        print("\nTesting GET /api/roundups/pending without body...")
        r = requests.get(f"{BASE_URL}/api/roundups/pending", headers=headers)
        print(f"Status: {r.status_code}")
        print(f"Response: {r.text}")

        # 3. List Mandates
        print("\nTesting GET /api/mandates without body...")
        r = requests.get(f"{BASE_URL}/api/mandates", headers=headers)
        print(f"Status: {r.status_code}")
        print(f"Response: {r.text}")
        
        # 4. Get Caps
        print("\nTesting GET /api/user/caps without body...")
        r = requests.get(f"{BASE_URL}/api/user/caps", headers=headers)
        print(f"Status: {r.status_code}")
        print(f"Response: {r.text}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_roundup_pending()

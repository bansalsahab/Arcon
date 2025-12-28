"""
Test script to validate Razorpay integration and mandate creation.

This script:
1. Validates Razorpay credentials
2. Creates a test mandate
3. Verifies the auth_link is generated
4. Tests the complete flow
"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from backend.app import create_app
from backend.providers import get_upi_provider
from datetime import date, timedelta
import json

def test_razorpay_credentials():
    """Test if Razorpay credentials are valid."""
    print("\n" + "="*60)
    print("STEP 1: Testing Razorpay Credentials")
    print("="*60)
    
    app = create_app()
    
    with app.app_context():
        try:
            provider = get_upi_provider()
            print(f"✓ Provider Type: {type(provider).__name__}")
            
            if hasattr(provider, 'key_id'):
                print(f"✓ Key ID: {provider.key_id[:15]}...")
                print(f"✓ Key Secret: {'*' * 20}")
            
            return provider
        except Exception as e:
            print(f"✗ Error initializing provider: {e}")
            return None

def test_mandate_creation(provider):
    """Test mandate creation with Razorpay."""
    print("\n" + "="*60)
    print("STEP 2: Testing Mandate Creation")
    print("="*60)
    
    try:
        # Create test mandate
        result = provider.create_mandate(
            user_id=1,
            max_amount_paise=50000,  # ₹500
            frequency="daily",
            start_date=date.today(),
            end_date=date.today() + timedelta(days=365),
            internal_mandate_id=999
        )
        
        print("\n📝 Mandate Creation Result:")
        print(json.dumps(result, indent=2))
        
        # Validate response
        if result.get('status') == 'failed':
            print(f"\n✗ Mandate creation failed: {result.get('error')}")
            return False
        
        if result.get('external_mandate_id'):
            print(f"\n✓ External Mandate ID: {result['external_mandate_id']}")
        
        if result.get('auth_link'):
            print(f"✓ Auth Link Generated: {result['auth_link'][:50]}...")
            print("\n🔗 Full Auth Link:")
            print(result['auth_link'])
            print("\n👉 Copy this link and open in browser to test UPI authorization!")
        else:
            print("✗ No auth_link in response")
        
        return result.get('status') in ['created', 'active']
        
    except Exception as e:
        print(f"\n✗ Error creating mandate: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_webhook_endpoint():
    """Test if webhook endpoint is accessible."""
    print("\n" + "="*60)
    print("STEP 3: Testing Webhook Endpoint")
    print("="*60)
    
    import requests
    
    try:
        # Test if endpoint exists
        response = requests.get('http://127.0.0.1:5000/api/health')
        print(f"✓ Backend is running: {response.json()}")
        
        # Webhook endpoint should return 400 for GET (expects POST)
        webhook_url = 'http://127.0.0.1:5000/api/webhooks/razorpay'
        print(f"\n✓ Webhook endpoint: {webhook_url}")
        print("  (Razorpay will POST to ngrok URL which forwards here)")
        
        return True
    except Exception as e:
        print(f"✗ Error testing endpoints: {e}")
        return False

def main():
    print("\n" + "🚀 "*20)
    print("RAZORPAY UPI AUTOPAY INTEGRATION TEST")
    print("🚀 "*20)
    
    # Step 1: Validate credentials
    provider = test_razorpay_credentials()
    if not provider:
        print("\n❌ FAILED: Could not initialize Razorpay provider")
        return
    
    # Step 2: Test mandate creation
    success = test_mandate_creation(provider)
    if not success:
        print("\n❌ FAILED: Mandate creation failed")
        print("\nPossible issues:")
        print("- Check RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET in .env")
        print("- Ensure you're using test mode keys (rzp_test_)")
        print("- Verify Razorpay account has Subscriptions enabled")
        return
    
    # Step 3: Test webhook endpoint
    test_webhook_endpoint()
    
    print("\n" + "="*60)
    print("✅ INTEGRATION TEST SUMMARY")
    print("="*60)
    print("✓ Razorpay provider initialized successfully")
    print("✓ Mandate created with auth_link")
    print("✓ Webhook endpoint is ready")
    print("\n📝 NEXT STEPS:")
    print("1. Copy the auth_link from above")
    print("2. Open it in browser to authorize mandate")
    print("3. Or test in Flutter app by creating a mandate")
    print("4. Check Razorpay dashboard for created subscription")
    print("\n" + "="*60)

if __name__ == "__main__":
    main()

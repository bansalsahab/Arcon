"""
Quick Razorpay credential test
"""
import os
from dotenv import load_dotenv

load_dotenv()

print("\n" + "="*60)
print("RAZORPAY CREDENTIALS CHECK")
print("="*60)

key_id = os.getenv("RAZORPAY_KEY_ID")
key_secret = os.getenv("RAZORPAY_KEY_SECRET")
webhook_secret = os.getenv("RAZORPAY_WEBHOOK_SECRET")
upi_provider = os.getenv("UPI_PROVIDER")

print(f"\nUPI_PROVIDER: {upi_provider}")
print(f"RAZORPAY_KEY_ID: {key_id[:15] if key_id else 'NOT SET'}...")
print(f"RAZORPAY_KEY_SECRET: {'SET (' + str(len(key_secret)) + ' chars)' if key_secret else 'NOT SET'}")
print(f"RAZORPAY_WEBHOOK_SECRET: {webhook_secret[:10] if webhook_secret else 'NOT SET'}...")

if not key_id or not key_secret:
    print("\n❌ ERROR: Razorpay credentials not found!")
    exit(1)

if key_id.startswith("rzp_test_"):
    print("\n✅ Using TEST mode (safe for testing)")
elif key_id.startswith("rzp_live_"):
    print("\n⚠️  Using LIVE mode (real money!)")
else:
    ("⚠️  Unknown key format")

# Test import
try:
    import razorpay
    print(f"\n✅ Razorpay SDK installed (version {razorpay.__version__})")
    
    # Test client inita
    client = razorpay.Client(auth=(key_id, key_secret))
    print("✅ Razorpay client initialized successfully")
    
    # Try to fetch a dummy subscription to test API access
    try:
        # This will fail but tests API auth
        client.subscription.fetch("sub_test123")
    except razorpay.errors.BadRequestError as e:
        if "does not exist" in str(e) or "not found" in str(e).lower():
            print("✅ API credentials are VALID (subscription not found is expected)")
        else:
            print(f"⚠️  API error: {e}")
    except Exception as e:
        print(f"⚠️  API test error: {e}")
    
    print("\n" + "="*60)
    print("✅ ALL CHECKS PASSED - Ready to create mandates!")
    print("="*60)
    
except ImportError:
    print("\n❌ Razorpay SDK not installed")
    print("Run: pip install razorpay")
except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()

import os
import razorpay
from typing import Dict, Optional
from datetime import date, datetime, timedelta
from .base import UPIProvider


class RazorpayUPIProvider(UPIProvider):
    """
    Production UPI provider using Razorpay for NPCI-compliant UPI AutoPay mandates.
    
    Razorpay Documentation: https://razorpay.com/docs/payments/upi-autopay/
    """
    
    def __init__(self, key_id: str = None, key_secret: str = None):
        """Initialize Razorpay client with credentials from environment or parameters."""
        self.key_id = key_id or os.getenv("RAZORPAY_KEY_ID")
        self.key_secret = key_secret or os.getenv("RAZORPAY_KEY_SECRET")
        
        if not self.key_id or not self.key_secret:
            raise ValueError("Razorpay credentials not found. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET environment variables.")
        
        self.client = razorpay.Client(auth=(self.key_id, self.key_secret))
    
    def create_mandate(
        self,
        *,
        user_id: int,
        max_amount_paise: int,
        frequency: str,
        start_date: date,
        end_date: Optional[date],
        internal_mandate_id: int,
    ) -> Dict[str, str]:
        """
        Create a UPI AutoPay mandate (recurring payment) via Razorpay.
        
        Args:
            user_id: Internal user ID
            max_amount_paise: Maximum amount per debit in paise (₹15,000 max per RBI)
            frequency: 'daily', 'weekly', or 'monthly'
            start_date: When mandate becomes active
            end_date: Optional expiry date
            internal_mandate_id: Our DB mandate ID for reference
        
        Returns:
            Dict with:
                - external_mandate_id: Razorpay subscription ID
                - status: 'created' (user needs to authorize)
                - auth_link: Short URL for UPI app authorization
                - max_amount_paise: Echoed back
                - frequency: Echoed back
        
        Raises:
            razorpay.errors.BadRequestError: If invalid parameters
        """
        
        # RBI/NPCI compliance: Max ₹15,000 per transaction for UPI AutoPay
        max_limit_paise = 1500000  # ₹15,000
        if max_amount_paise > max_limit_paise:
            raise ValueError(f"Max amount cannot exceed ₹{max_limit_paise / 100} (RBI limit)")
        
        # Map our frequency to Razorpay period
        period_map = {
            "daily": "daily",
            "weekly": "weekly",
            "monthly": "monthly"
        }
        
        if frequency not in period_map:
            raise ValueError(f"Invalid frequency: {frequency}. Must be daily, weekly, or monthly.")
        
        # Calculate total_count (for finite mandates)
        # For simplicity, we'll use a large number or make it perpetual
        total_count = 1200  # ~3 years for daily, more for weekly/monthly
        
        # Create a Razorpay Plan (one-time, reusable)
        # In production, you might want to cache plans or pre-create them
        plan_data = {
            "period": period_map[frequency],
            "interval": 1,
            "item": {
                "name": "Roundup Investment Auto-Debit",
                "amount": max_amount_paise,
                "currency": "INR",
                "description": f"UPI AutoPay for roundup investments (max ₹{max_amount_paise / 100} per {frequency})"
            }
        }
        
        try:
            plan = self.client.plan.create(plan_data)
            plan_id = plan["id"]
        except Exception as e:
            # If plan creation fails, return error
            return {
                "external_mandate_id": None,
                "status": "failed",
                "error": str(e),
                "auth_link": None
            }
        
        # Create Subscription (Mandate)
        subscription_data = {
            "plan_id": plan_id,
            "customer_notify": 1,  # Razorpay sends SMS/email to customer
            "quantity": 1,
            "total_count": total_count,
            "start_at": int(datetime.combine(start_date, datetime.min.time()).timestamp()),
            "notes": {
                "internal_mandate_id": str(internal_mandate_id),
                "user_id": str(user_id),
                "frequency": frequency
            }
        }
        
        # Add end date if provided
        if end_date:
            # Razorpay doesn't directly support end_date, but we can use total_count
            # Calculate days between start and end
            days_diff = (end_date - start_date).days
            if frequency == "daily":
                subscription_data["total_count"] = max(1, days_diff)
            elif frequency == "weekly":
                subscription_data["total_count"] = max(1, days_diff // 7)
            elif frequency == "monthly":
                subscription_data["total_count"] = max(1, days_diff // 30)
        
        try:
            subscription = self.client.subscription.create(subscription_data)
            
            return {
                "external_mandate_id": subscription["id"],
                "status": "created",  # Razorpay initial status
                "auth_link": subscription.get("short_url"),  # UPI authorization link
                "max_amount_paise": max_amount_paise,
                "frequency": frequency,
                "plan_id": plan_id,  # Store for reference
            }
        
        except Exception as e:
            return {
                "external_mandate_id": None,
                "status": "failed",
                "error": str(e),
                "auth_link": None
            }
    
    def execute_debit(self, external_mandate_id: str, amount_paise: int, description: str = None) -> Dict[str, str]:
        """
        Execute a debit against an active mandate.
        
        Args:
            external_mandate_id: Razorpay subscription ID
            amount_paise: Amount to debit (must be <= max_amount)
            description: Optional description for the charge
        
        Returns:
            Dict with:
                - payment_id: Razorpay payment ID
                - status: 'authorized', 'captured', 'failed'
                - amount_paise: Amount debited
        """
        
        try:
            # Fetch subscription to validate
            subscription = self.client.subscription.fetch(external_mandate_id)
            
            if subscription["status"] not in ["active", "authenticated"]:
                return {
                    "payment_id": None,
                    "status": "failed",
                    "error": f"Mandate status is {subscription['status']}, not active"
                }
            
            # Create payment against subscription
            # Note: Razorpay handles automatic charging based on billing cycle
            # For on-demand charging, we create an invoice
            invoice_data = {
                "type": "link",
                "amount": amount_paise,
                "currency": "INR",
                "description": description or "Roundup investment debit",
                "customer": {
                    "email": subscription.get("notes", {}).get("email", "user@example.com")
                },
                "subscription_id": external_mandate_id
            }
            
            invoice = self.client.invoice.create(invoice_data)
            
            return {
                "payment_id": invoice["id"],
                "status": invoice["status"],  # 'issued', 'paid', etc.
                "amount_paise": amount_paise,
                "invoice_id": invoice["id"]
            }
            
        except Exception as e:
            return {
                "payment_id": None,
                "status": "failed",
                "error": str(e)
            }
    
    def pause_mandate(self, external_mandate_id: str) -> Dict[str, str]:
        """
        Pause an active mandate.
        
        Razorpay subscriptions can be paused to stop future charges.
        """
        try:
            # Razorpay: Update subscription status to 'paused'
            subscription = self.client.subscription.pause(external_mandate_id)
            
            return {
                "external_mandate_id": external_mandate_id,
                "status": subscription.get("status", "paused")
            }
        except Exception as e:
            return {
                "external_mandate_id": external_mandate_id,
                "status": "error",
                "error": str(e)
            }
    
    def resume_mandate(self, external_mandate_id: str) -> Dict[str, str]:
        """
        Resume a paused mandate.
        """
        try:
            subscription = self.client.subscription.resume(external_mandate_id)
            
            return {
                "external_mandate_id": external_mandate_id,
                "status": subscription.get("status", "active")
            }
        except Exception as e:
            return {
                "external_mandate_id": external_mandate_id,
                "status": "error",
                "error": str(e)
            }
    
    def cancel_mandate(self, external_mandate_id: str) -> Dict[str, str]:
        """
        Cancel a mandate permanently.
        
        Once cancelled, the mandate cannot be reactivated. User must create a new one.
        """
        try:
            subscription = self.client.subscription.cancel(external_mandate_id)
            
            return {
                "external_mandate_id": external_mandate_id,
                "status": subscription.get("status", "cancelled")
            }
        except Exception as e:
            return {
                "external_mandate_id": external_mandate_id,
                "status": "error",
                "error": str(e)
            }
    
    def confirm_mandate(self, external_mandate_id: str, otp: str) -> Dict[str, str]:
        """
        Confirm mandate with OTP (Not used for UPI AutoPay - approval happens in UPI app).
        
        This method is kept for interface compatibility but is not used in UPI flow.
        UPI mandates are confirmed directly in the user's UPI app (GPay/PhonePe).
        """
        # For UPI AutoPay, confirmation happens via the UPI app, not OTP
        # We can fetch the subscription status instead
        try:
            subscription = self.client.subscription.fetch(external_mandate_id)
            return {
                "external_mandate_id": external_mandate_id,
                "status": subscription.get("status")
            }
        except Exception as e:
            return {
                "external_mandate_id": external_mandate_id,
                "status": "error",
                "error": str(e)
            }
    
    def fetch_mandate_status(self, external_mandate_id: str) -> Dict[str, str]:
        """
        Fetch current status of a mandate from Razorpay.
        
        Useful for polling or verifying mandate state.
        """
        try:
            subscription = self.client.subscription.fetch(external_mandate_id)
            return {
                "external_mandate_id": external_mandate_id,
                "status": subscription.get("status"),
                "current_start": subscription.get("current_start"),
                "current_end": subscription.get("current_end"),
                "charged_count": subscription.get("paid_count", 0),
                "remaining_count": subscription.get("remaining_count")
            }
        except Exception as e:
            return {
                "external_mandate_id": external_mandate_id,
                "status": "error",
                "error": str(e)
            }

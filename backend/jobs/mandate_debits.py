"""
Scheduled job to process UPI AutoPay mandate debits.

This job:
1. Finds mandates due for debit (next_debit_at <= now, status=active)
2. Checks if 24h pre-notification was sent (RBI compliance)
3. If not sent: sends notification and reschedules for 24h later
4. If sent: executes debit via payment provider
5. Handles failures with retry logic
6. Updates next_debit_at based on frequency

Schedule: Run every 6 hours via cron or task scheduler
Cron: 0 */6 * * * cd /path/to/Arcon && python -m backend.jobs.mandate_debits

For production: Use Celery, APScheduler, or cloud scheduler (AWS EventBridge, GCP Cloud Scheduler)
"""

import sys
import os
from datetime import datetime, timedelta

# Add parent directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from backend.extensions import db
from backend.models.mandate import Mandate
from backend.models.event import EventLog
from backend.models.roundup import Roundup
from backend.providers import get_upi_provider
from backend.app import create_app


def send_pre_debit_notification(mandate: Mandate, amount_paise: int):
    """
    Send 24-hour advance notice for mandate debit (RBI compliance).
    
    Args:
        mandate: Mandate object
        amount_paise: Amount to be debited
    
    Returns:
        bool: True if notification sent successfully
    """
    from backend.models.user import User
    
    user = User.query.get(mandate.user_id)
    if not user:
        return False
    
    # In production: Send actual SMS/email/push notification
    # For now: Log the event
    message = f"Auto-debit scheduled: ₹{amount_paise / 100:.2f} will be debited in 24 hours for your roundup investment"
    
    event = EventLog(
        user_id=mandate.user_id,
        event_type="pre_debit_sent",
        message=message,
        amount_paise=amount_paise
    )
    
    db.session.add(event)
    
    # Mark notification as sent
    mandate.pre_debit_notification_sent_at = datetime.utcnow()
    
    db.session.commit()
    
    print(f"[PRE-DEBIT] Notification sent to user {user.id}: {message}")
    
    # TODO: Integrate with SMS provider (Twilio, MSG91, etc.)
    # TODO: Send email via SendGrid/AWS SES
    # TODO: Send push notification via Firebase
    
    return True


def execute_mandate_debit(mandate: Mandate, amount_paise: int):
    """
    Execute debit against active mandate via payment provider.
    
    Args:
        mandate: Mandate object
        amount_paise: Amount to debit
    
    Returns:
        dict: Provider response with payment_id and status
    """
    provider = get_upi_provider()
    
    try:
        result = provider.execute_debit(
            external_mandate_id=mandate.external_mandate_id,
            amount_paise=amount_paise,
            description=f"Roundup investment auto-debit for mandate {mandate.id}"
        )
        
        if result.get("status") in ["authorized", "captured", "paid", "issued"]:
            # Success
            print(f"[DEBIT] Successfully debited ₹{amount_paise / 100:.2f} for mandate {mandate.id}")
            
            mandate.last_debit_at = datetime.utcnow()
            mandate.failure_count = 0  # Reset on success
            mandate.pre_debit_notification_sent_at = None  # Reset for next cycle
            
            # Update next debit based on frequency
            if mandate.frequency == "daily":
                mandate.next_debit_at = datetime.utcnow() + timedelta(days=1)
            elif mandate.frequency == "weekly":
                mandate.next_debit_at = datetime.utcnow() + timedelta(weeks=1)
            elif mandate.frequency == "monthly":
                mandate.next_debit_at = datetime.utcnow() + timedelta(days=30)
            
            db.session.commit()
            
            return result
        else:
            # Failed
            raise Exception(f"Debit failed: {result.get('error', 'Unknown error')}")
    
    except Exception as e:
        print(f"[DEBIT ERROR] Mandate {mandate.id}: {str(e)}")
        
        # Track failure
        mandate.failure_count = (mandate.failure_count or 0) + 1
        mandate.last_failure_reason = str(e)
        
        # Auto-pause after 3 failures
        if mandate.failure_count >= 3:
            mandate.status = "paused"
            print(f"[AUTO-PAUSE] Mandate {mandate.id} paused after 3 consecutive failures")
            
            event = EventLog(
                user_id=mandate.user_id,
                event_type="mandate_auto_paused",
                message=f"Mandate {mandate.id} auto-paused due to repeated failures: {mandate.last_failure_reason}"
            )
            db.session.add(event)
        
        # For insufficient balance: retry in 24h
        if "insufficient" in str(e).lower() or "balance" in str(e).lower():
            mandate.next_debit_at = datetime.utcnow() + timedelta(hours=24)
            mandate.pre_debit_notification_sent_at = None  # Resend notification
            print(f"[RETRY] Will retry mandate {mandate.id} in 24 hours")
        
        db.session.commit()
        
        return {"status": "failed", "error": str(e)}


def calculate_debit_amount(mandate: Mandate) -> int:
    """
    Calculate amount to debit for this mandate.
    
    For roundup app: Sum of pending roundups for this user.
    
    Args:
        mandate: Mandate object
    
    Returns:
        int: Amount in paise
    """
    # Get sum of pending roundups for this user
    pending_sum = db.session.query(db.func.coalesce(db.func.sum(Roundup.amount_paise), 0)).filter(
        Roundup.user_id == mandate.user_id,
        Roundup.status == "pending"
    ).scalar()
    
    # Cap at mandate max_amount
    amount = min(int(pending_sum), mandate.max_amount_paise)
    
    return amount


def process_due_debits():
    """
    Main job function: Process all mandates due for debit.
    """
    app = create_app()
    
    with app.app_context():
        now = datetime.utcnow()
        
        # Find active mandates due for debit
        due_mandates = Mandate.query.filter(
            Mandate.status == "active",
            Mandate.next_debit_at <= now
        ).all()
        
        print(f"\n[JOB START] Processing {len(due_mandates)} due mandates at {now}")
        
        for mandate in due_mandates:
            print(f"\n--- Processing Mandate {mandate.id} ---")
            
            # Calculate debit amount
            amount_paise = calculate_debit_amount(mandate)
            
            if amount_paise <= 0:
                print(f"[SKIP] Mandate {mandate.id}: No pending roundups, skipping debit")
                # Update next debit to tomorrow
                if mandate.frequency == "daily":
                    mandate.next_debit_at = datetime.utcnow() + timedelta(days=1)
                elif mandate.frequency == "weekly":
                    mandate.next_debit_at = datetime.utcnow() + timedelta(weeks=1)
                elif mandate.frequency == "monthly":
                    mandate.next_debit_at = datetime.utcnow() + timedelta(days=30)
                
                mandate.pre_debit_notification_sent_at = None
                db.session.commit()
                continue
            
            # Check if 24h pre-notification was sent
            notification_sent = mandate.pre_debit_notification_sent_at is not None
            
            if notification_sent:
                # Check if 24 hours have passed
                time_since_notification = now - mandate.pre_debit_notification_sent_at
                
                if time_since_notification < timedelta(hours=24):
                    print(f"[WAIT] Mandate {mandate.id}: Notification sent {time_since_notification.total_seconds() / 3600:.1f}h ago, waiting for 24h")
                    continue
                
                # Execute debit
                print(f"[EXECUTE] Mandate {mandate.id}: Debiting ₹{amount_paise / 100:.2f}")
                execute_mandate_debit(mandate, amount_paise)
            
            else:
                # Send pre-debit notification
                print(f"[NOTIFY] Mandate {mandate.id}: Sending 24h pre-debit notice for ₹{amount_paise / 100:.2f}")
                send_pre_debit_notification(mandate, amount_paise)
        
        print(f"\n[JOB END] Processed {len(due_mandates)} mandates")


if __name__ == "__main__":
    print("=" * 60)
    print("UPI AutoPay Mandate Debit Processing Job")
    print("=" * 60)
    
    try:
        process_due_debits()
    except Exception as e:
        print(f"\n[CRITICAL ERROR] Job failed: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

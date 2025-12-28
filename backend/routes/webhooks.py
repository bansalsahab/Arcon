"""
Razorpay webhook handler for UPI AutoPay mandate events.

Handles:
- subscription.authenticated: Mandate approved by user in UPI app
- subscription.charged: Successful debit
- payment.failed: Debit failed (insufficient balance, etc.)
- subscription.cancelled: User cancelled mandate from bank app
- subscription.paused: Mandate paused

Reference: https://razorpay.com/docs/webhooks/
"""

import os
import hmac
import hashlib
from flask import Blueprint, request, jsonify, current_app
from ..extensions import db
from ..models.mandate import Mandate
from ..models.event import EventLog
from ..models.ledger import LedgerEntry

webhooks_bp = Blueprint("webhooks", __name__, url_prefix="/api/webhooks")


def verify_razorpay_signature(payload: bytes, signature: str, secret: str) -> bool:
    """
    Verify Razorpay webhook signature for security.
    
    Args:
        payload: Raw request body (bytes)
        signature: X-Razorpay-Signature header
        secret: Webhook secret from Razorpay dashboard
    
    Returns:
        True if signature is valid, False otherwise
    """
    expected_signature = hmac.new(
        secret.encode("utf-8"),
        payload,
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(expected_signature, signature)


@webhooks_bp.post("/razorpay")
def razorpay_webhook():
    """
    Handle Razorpay webhook events for UPI AutoPay mandates.
    
    Security: Verifies webhook signature before processing.
    """
    
    # Get webhook secret from environment
    webhook_secret = os.getenv("RAZORPAY_WEBHOOK_SECRET")
    if not webhook_secret:
        current_app.logger.error("RAZORPAY_WEBHOOK_SECRET not configured")
        return jsonify({"error": "Webhook secret not configured"}), 500
    
    # Verify signature
    signature = request.headers.get("X-Razorpay-Signature")
    if not signature:
        current_app.logger.warning("Missing Razorpay signature")
        return jsonify({"error": "Missing signature"}), 400
    
    payload = request.get_data()
    
    if not verify_razorpay_signature(payload, signature, webhook_secret):
        current_app.logger.warning("Invalid Razorpay signature")
        return jsonify({"error": "Invalid signature"}), 401
    
    # Parse event
    event_data = request.get_json()
    event_type = event_data.get("event")
    payload_data = event_data.get("payload", {})
    
    # Extract subscription and payment entities
    subscription_entity = payload_data.get("subscription", {}).get("entity", {})
    payment_entity = payload_data.get("payment", {}).get("entity", {})
    
    external_mandate_id = subscription_entity.get("id")
    
    if not external_mandate_id:
        current_app.logger.warning(f"No subscription ID in webhook: {event_type}")
        return jsonify({"status": "ignored", "reason": "No subscription ID"}), 200
    
    # Find our mandate
    mandate = Mandate.query.filter_by(external_mandate_id=external_mandate_id).first()
    
    if not mandate:
        current_app.logger.warning(f"Mandate not found for subscription {external_mandate_id}")
        return jsonify({"status": "ignored", "reason": "Mandate not found"}), 200
    
    # Handle different event types
    if event_type == "subscription.authenticated":
        # User approved mandate in UPI app
        handle_mandate_authenticated(mandate, subscription_entity)
    
    elif event_type == "subscription.charged":
        # Successful debit
        handle_subscription_charged(mandate, subscription_entity, payment_entity)
    
    elif event_type == "payment.failed":
        # Debit failed
        handle_payment_failed(mandate, payment_entity)
    
    elif event_type == "subscription.cancelled":
        # User cancelled from bank app or mandate expired
        handle_mandate_cancelled(mandate, subscription_entity)
    
    elif event_type == "subscription.paused":
        # Mandate paused
        handle_mandate_paused(mandate, subscription_entity)
    
    elif event_type == "subscription.resumed":
        # Mandate resumed
        handle_mandate_resumed(mandate, subscription_entity)
    
    else:
        current_app.logger.info(f"Unhandled event type: {event_type}")
    
    return jsonify({"status": "success"}), 200


def handle_mandate_authenticated(mandate: Mandate, subscription_data: dict):
    """Handle subscription.authenticated event - user approved in UPI app."""
    mandate.status = "active"
    mandate.meta_json = {**(mandate.meta_json or {}), "authenticated_at": subscription_data.get("authenticated_at")}
    
    # Log event
    event = EventLog(
        user_id=mandate.user_id,
        event_type="mandate_authenticated",
        message=f"Mandate {mandate.id} authenticated via UPI app",
        amount_paise=mandate.max_amount_paise
    )
    
    db.session.add(event)
    db.session.commit()
    
    current_app.logger.info(f"Mandate {mandate.id} authenticated")


def handle_subscription_charged(mandate: Mandate, subscription_data: dict, payment_data: dict):
    """Handle subscription.charged event - successful debit."""
    from datetime import datetime, timedelta
    
    amount_paise = payment_data.get("amount", 0)
    payment_id = payment_data.get("id")
    
    # Update mandate
    mandate.last_debit_at = datetime.utcnow()
    
    # Calculate next debit based on frequency
    if mandate.frequency == "daily":
        mandate.next_debit_at = datetime.utcnow() + timedelta(days=1)
    elif mandate.frequency == "weekly":
        mandate.next_debit_at = datetime.utcnow() + timedelta(weeks=1)
    elif mandate.frequency == "monthly":
        mandate.next_debit_at = datetime.utcnow() + timedelta(days=30)
    
    # Reset failure count on success
    if hasattr(mandate, 'failure_count'):
        mandate.failure_count = 0
    
    # Create ledger entry (debit from user's virtual wallet)
    ledger_entry = LedgerEntry(
        user_id=mandate.user_id,
        type="debit",
        category="mandate_debit",
        amount_paise=amount_paise,
        reference_type="Mandate",
        reference_id=mandate.id,
        meta_json={"payment_id": payment_id, "razorpay_subscription_id": mandate.external_mandate_id}
    )
    
    # Log event
    event = EventLog(
        user_id=mandate.user_id,
        event_type="mandate_charged",
        message=f"Mandate {mandate.id} charged ₹{amount_paise / 100:.2f}",
        amount_paise=amount_paise
    )
    
    db.session.add(ledger_entry)
    db.session.add(event)
    db.session.commit()
    
    # TODO: Trigger investment execution with the debited amount
    # from ..services.investment_service import execute_roundup_investment
    # execute_roundup_investment(mandate.user_id, amount_paise)
    
    current_app.logger.info(f"Mandate {mandate.id} charged ₹{amount_paise / 100:.2f}")


def handle_payment_failed(mandate: Mandate, payment_data: dict):
    """Handle payment.failed event - debit failed."""
    failure_reason = payment_data.get("error_description", "Unknown error")
    
    # Increment failure count
    if not hasattr(mandate, 'failure_count') or mandate.failure_count is None:
        mandate.failure_count = 0
    
    mandate.failure_count = (mandate.failure_count or 0) + 1
    
    if hasattr(mandate, 'last_failure_reason'):
        mandate.last_failure_reason = failure_reason
    
    # Auto-pause after 3 consecutive failures
    if mandate.failure_count >= 3:
        mandate.status = "paused"
        current_app.logger.warning(f"Mandate {mandate.id} auto-paused after 3 failures")
    
    # Log event
    event = EventLog(
        user_id=mandate.user_id,
        event_type="mandate_debit_failed",
        message=f"Mandate {mandate.id} debit failed: {failure_reason}",
        amount_paise=payment_data.get("amount", 0)
    )
    
    db.session.add(event)
    db.session.commit()
    
    # TODO: Send notification to user about failed debit
    current_app.logger.warning(f"Mandate {mandate.id} debit failed: {failure_reason}")


def handle_mandate_cancelled(mandate: Mandate, subscription_data: dict):
    """Handle subscription.cancelled event - user cancelled mandate."""
    mandate.status = "cancelled"
    mandate.meta_json = {**(mandate.meta_json or {}), "cancelled_at": subscription_data.get("cancelled_at")}
    
    # Log event
    event = EventLog(
        user_id=mandate.user_id,
        event_type="mandate_cancelled",
        message=f"Mandate {mandate.id} cancelled",
    )
    
    db.session.add(event)
    db.session.commit()
    
    current_app.logger.info(f"Mandate {mandate.id} cancelled")


def handle_mandate_paused(mandate: Mandate, subscription_data: dict):
    """Handle subscription.paused event."""
    mandate.status = "paused"
    
    event = EventLog(
        user_id=mandate.user_id,
        event_type="mandate_paused",
        message=f"Mandate {mandate.id} paused",
    )
    
    db.session.add(event)
    db.session.commit()
    
    current_app.logger.info(f"Mandate {mandate.id} paused")


def handle_mandate_resumed(mandate: Mandate, subscription_data: dict):
    """Handle subscription.resumed event."""
    mandate.status = "active"
    
    # Reset failure count on manual resume
    if hasattr(mandate, 'failure_count'):
        mandate.failure_count = 0
    
    event = EventLog(
        user_id=mandate.user_id,
        event_type="mandate_resumed",
        message=f"Mandate {mandate.id} resumed",
    )
    
    db.session.add(event)
    db.session.commit()
    
    current_app.logger.info(f"Mandate {mandate.id} resumed")

from datetime import datetime, timedelta
from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..extensions import db
from ..models.roundup import Roundup
from ..models.event import EventLog

notifications_bp = Blueprint("notifications", __name__, url_prefix="/api/notifications")


@notifications_bp.get("")
@jwt_required()
def list_notifications():
    """
    ---
    tags: [Notifications]
    summary: List pre-debit notifications (scheduled/sent)
    security:
      - BearerAuth: []
    responses:
      200:
        description: Recent pre-debit notifications
    """
    user_id = int(get_jwt_identity())
    items = (
        EventLog.query
        .filter(EventLog.user_id == user_id, EventLog.event_type.in_(["pre_debit_scheduled", "pre_debit_sent"]))
        .order_by(EventLog.created_at.desc())
        .limit(100)
        .all()
    )
    return jsonify([e.to_dict() for e in items])


@notifications_bp.post("/pre-debit/schedule")
@jwt_required()
def schedule_pre_debit_notice():
    """
    ---
    tags: [Notifications]
    summary: Schedule a 24h pre-debit notification (stub)
    description: Creates an event log stating a pre-debit notice is scheduled for 24 hours later with the current pending roundup total.
    security:
      - BearerAuth: []
    responses:
      200:
        description: Scheduled notice
    """
    user_id = int(get_jwt_identity())
    total = sum(r.amount_paise for r in Roundup.query.filter_by(user_id=user_id, status="pending").all())
    scheduled_for = (datetime.utcnow() + timedelta(hours=24)).isoformat()
    msg = f"Pre-debit notice scheduled for {scheduled_for} (amount_paise={total})"
    evt = EventLog(user_id=user_id, event_type="pre_debit_scheduled", message=msg, amount_paise=total)
    db.session.add(evt)
    db.session.commit()
    return jsonify(evt.to_dict())


@notifications_bp.post("/pre-debit/send")
@jwt_required()
def send_pre_debit_notice():
    """
    ---
    tags: [Notifications]
    summary: Send the 24h pre-debit notification (stub)
    description: Logs a 'pre_debit_sent' event. In production this would dispatch email/push.
    security:
      - BearerAuth: []
    responses:
      200:
        description: Sent notice event
    """
    user_id = int(get_jwt_identity())
    total = sum(r.amount_paise for r in Roundup.query.filter_by(user_id=user_id, status="pending").all())
    msg = f"Pre-debit notice sent (amount_paise={total})"
    evt = EventLog(user_id=user_id, event_type="pre_debit_sent", message=msg, amount_paise=total)
    db.session.add(evt)
    db.session.commit()
    return jsonify(evt.to_dict())

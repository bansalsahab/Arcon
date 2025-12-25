from flask import Blueprint, jsonify
from datetime import datetime, timedelta
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..services.investment_service import execute_pending_roundups
from ..extensions import db
from ..models.event import EventLog
from ..models.user import User

scheduler_bp = Blueprint("scheduler", __name__, url_prefix="/api/scheduler")


@scheduler_bp.post("/daily-sweep")
@jwt_required()
def daily_sweep():
    """
    ---
    tags: [Scheduler]
    summary: Trigger daily sweep to execute pending roundups (per-user stub)
    description: Aggregates pending roundups into an executed investment order and logs an event.
    security:
      - BearerAuth: []
    responses:
      200:
        description: Executed or no-pending status
    """
    user_id = int(get_jwt_identity())
    # Respect user's sweep_frequency (daily/weekly) based on last sweep_executed event
    user = User.query.get(user_id)
    freq = (user.sweep_frequency or "daily").lower()
    min_delta = timedelta(days=1) if freq == "daily" else timedelta(days=7)
    last_sweep = (
        EventLog.query
        .filter_by(user_id=user_id, event_type="sweep_executed")
        .order_by(EventLog.created_at.desc())
        .first()
    )
    if last_sweep and (datetime.utcnow() - last_sweep.created_at) < min_delta:
        return jsonify({"status": "skipped_frequency", "next_allowed_after": (last_sweep.created_at + min_delta).isoformat()}), 200

    order = execute_pending_roundups(user_id)
    if not order:
        return jsonify({"status": "no_pending"}), 200
    evt = EventLog(user_id=user_id, event_type="sweep_executed", message=f"Executed sweep order {order.id}", amount_paise=order.amount_paise)
    db.session.add(evt)
    db.session.commit()
    return jsonify({"status": "executed", "order": order.to_dict()})

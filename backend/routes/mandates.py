import time
from datetime import date, datetime
from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..extensions import db
from ..models.mandate import Mandate
from ..models.event import EventLog
from ..providers import get_upi_provider

mandates_bp = Blueprint("mandates", __name__, url_prefix="/api/mandates")


@mandates_bp.post("")
@jwt_required()
def create_mandate():
    """
    ---
    tags: [Mandates]
    summary: Initiate a UPI AutoPay mandate
    security:
      - BearerAuth: []
    consumes:
      - application/json
    parameters:
      - in: body
        name: body
        required: false
        schema:
          type: object
          properties:
            max_amount_paise:
              type: integer
            frequency:
              type: string
              enum: [daily, weekly, monthly]
            start_date:
              type: string
              format: date
            end_date:
              type: string
              format: date
    responses:
      200:
        description: Created mandate + provider auth link (if any)
    """
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}

    # Max per-debit amount in paise (default ₹5000 to match UI)
    try:
        max_amount_paise = int(data.get("max_amount_paise") or 500000)
        if max_amount_paise <= 0:
            return jsonify({"error": "max_amount_paise must be > 0"}), 400
    except (TypeError, ValueError):
        return jsonify({"error": "max_amount_paise must be integer"}), 400

    # Default to weekly because Razorpay daily mandates require min 7 day interval
    frequency = (data.get("frequency") or "weekly").lower()
    if frequency not in {"daily", "weekly", "monthly"}:
        return jsonify({"error": "frequency must be one of daily, weekly, monthly"}), 400

    # Dates
    start_str = data.get("start_date")
    if start_str:
        try:
            start_date = date.fromisoformat(start_str)
        except ValueError:
            return jsonify({"error": "start_date must be ISO date (YYYY-MM-DD)"}), 400
    else:
        start_date = date.today()

    end_str = data.get("end_date")
    end_date = None
    if end_str:
        try:
            end_date = date.fromisoformat(end_str)
        except ValueError:
            return jsonify({"error": "end_date must be ISO date (YYYY-MM-DD)"}), 400

    m = Mandate(
        user_id=user_id,
        provider="UPI",
        status="pending",
        max_amount_paise=max_amount_paise,
        frequency=frequency,
        start_date=start_date,
        end_date=end_date,
    )
    db.session.add(m)
    db.session.flush()

    provider = get_upi_provider()
    resp = provider.create_mandate(
        user_id=user_id,
        max_amount_paise=max_amount_paise,
        frequency=frequency,
        start_date=start_date,
        end_date=end_date,
        internal_mandate_id=m.id,
    )

    m.external_mandate_id = resp.get("external_mandate_id")
    if resp.get("status"):
        m.status = str(resp["status"]).lower()
    
    # Check if creation failed
    if m.status == "failed" or resp.get("error"):
        db.session.commit() # Save the failed mandate record for debugging
        return jsonify({
            "error": "Mandate creation failed", 
            "details": resp.get("error", "Unknown provider error")
        }), 400

    # Store auth_link for frontend to redirect to UPI app
    m.auth_link = resp.get("auth_link")
    
    # Store full provider response as metadata
    m.meta_json = resp

    # Default next_debit_at to start date midnight
    if start_date and not m.next_debit_at:
        m.next_debit_at = datetime.combine(start_date, datetime.min.time())

    evt = EventLog(
        user_id=user_id,
        event_type="mandate_created",
        message=f"Mandate {m.id} created",
        amount_paise=max_amount_paise,
    )
    db.session.add(evt)
    db.session.commit()

    return jsonify({
        "mandate": m.to_dict(),
        "auth_link": m.auth_link,  # Frontend uses this to redirect to UPI app
    })


@mandates_bp.get("")
@jwt_required()
def list_mandates():
    """
    ---
    tags: [Mandates]
    summary: List mandates for current user
    security:
      - BearerAuth: []
    responses:
      200:
        description: List of mandates
    """
    user_id = int(get_jwt_identity())
    items = Mandate.query.filter_by(user_id=user_id).order_by(Mandate.created_at.desc()).all()
    return jsonify([m.to_dict() for m in items])


@mandates_bp.post("/<int:mandate_id>/pause")
@jwt_required()
def pause_mandate(mandate_id: int):
    """
    ---
    tags: [Mandates]
    summary: Pause an active mandate (stub)
    security:
      - BearerAuth: []
    responses:
      200:
        description: Mandate paused
      404:
        description: Not found
    """
    user_id = int(get_jwt_identity())
    m = Mandate.query.filter_by(id=mandate_id, user_id=user_id).first()
    if not m:
        return jsonify({"error": "not found"}), 404
    provider = get_upi_provider()
    if m.external_mandate_id:
        resp = provider.pause_mandate(m.external_mandate_id)
        if resp.get("status"):
            m.status = str(resp["status"]).lower()
        m.meta_json = {**(m.meta_json or {}), "last_pause": resp}
    else:
        m.status = "paused"
    db.session.add(EventLog(user_id=user_id, event_type="mandate_paused", message=f"Mandate {m.id} paused"))
    db.session.commit()
    return jsonify(m.to_dict())


@mandates_bp.post("/<int:mandate_id>/resume")
@jwt_required()
def resume_mandate(mandate_id: int):
    """
    ---
    tags: [Mandates]
    summary: Resume a paused mandate (stub)
    security:
      - BearerAuth: []
    responses:
      200:
        description: Mandate resumed
      404:
        description: Not found
    """
    user_id = int(get_jwt_identity())
    m = Mandate.query.filter_by(id=mandate_id, user_id=user_id).first()
    if not m:
        return jsonify({"error": "not found"}), 404
    provider = get_upi_provider()
    if m.external_mandate_id:
        resp = provider.resume_mandate(m.external_mandate_id)
        if resp.get("status"):
            m.status = str(resp["status"]).lower()
        m.meta_json = {**(m.meta_json or {}), "last_resume": resp}
    else:
        m.status = "active"
    db.session.add(EventLog(user_id=user_id, event_type="mandate_resumed", message=f"Mandate {m.id} resumed"))
    db.session.commit()
    return jsonify(m.to_dict())


@mandates_bp.post("/<int:mandate_id>/cancel")
@jwt_required()
def cancel_mandate(mandate_id: int):
    """
    ---
    tags: [Mandates]
    summary: Cancel a mandate (stub)
    security:
      - BearerAuth: []
    responses:
      200:
        description: Mandate cancelled
      404:
        description: Not found
    """
    user_id = int(get_jwt_identity())
    m = Mandate.query.filter_by(id=mandate_id, user_id=user_id).first()
    if not m:
        return jsonify({"error": "not found"}), 404
    provider = get_upi_provider()
    if m.external_mandate_id:
        resp = provider.cancel_mandate(m.external_mandate_id)
        if resp.get("status"):
            m.status = str(resp["status"]).lower()
        m.meta_json = {**(m.meta_json or {}), "last_cancel": resp}
    else:
        m.status = "cancelled"
    db.session.add(EventLog(user_id=user_id, event_type="mandate_cancelled", message=f"Mandate {m.id} cancelled"))
    db.session.commit()
    return jsonify(m.to_dict())

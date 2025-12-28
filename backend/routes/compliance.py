from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..extensions import db
from ..models.event import EventLog

compliance_bp = Blueprint("compliance", __name__, url_prefix="/api/compliance")


_VALID_TYPES = {"terms", "privacy", "sebi", "gold_risk"}


@compliance_bp.post("/accept")
@jwt_required()
def accept():
    """
    ---
    tags: [Compliance]
    summary: Accept a compliance item (terms/privacy/sebi/gold_risk)
    security:
      - BearerAuth: []
    consumes:
      - application/json
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            type:
              type: string
              enum: [terms, privacy, sebi, gold_risk]
    responses:
      200:
        description: Acceptance recorded
    """
    uid = int(get_jwt_identity())
    data = request.get_json() or {}
    t = (data.get("type") or "").strip().lower()
    if t not in _VALID_TYPES:
        return jsonify({"error": "type must be one of terms, privacy, sebi, gold_risk"}), 400
    msg = f"Accepted {t}"
    evt = EventLog(user_id=uid, event_type="compliance_accept", message=msg)
    db.session.add(evt)
    db.session.commit()
    return jsonify(evt.to_dict())


@compliance_bp.get("/history")
@jwt_required()
def history():
    """
    ---
    tags: [Compliance]
    summary: List compliance acceptance history
    security:
      - BearerAuth: []
    responses:
      200:
        description: Events related to compliance acceptance
    """
    uid = int(get_jwt_identity())
    items = (
        EventLog.query
        .filter_by(user_id=uid, event_type="compliance_accept")
        .order_by(EventLog.created_at.desc())
        .all()
    )
    return jsonify([e.to_dict() for e in items])

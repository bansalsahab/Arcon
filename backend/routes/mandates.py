import time
from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..extensions import db
from ..models.mandate import Mandate
from ..models.event import EventLog

mandates_bp = Blueprint("mandates", __name__, url_prefix="/api/mandates")


@mandates_bp.post("")
@jwt_required()
def create_mandate():
    """
    ---
    tags: [Mandates]
    summary: Create an active UPI mandate (stub)
    security:
      - BearerAuth: []
    responses:
      200:
        description: Created mandate (stub)
    """
    user_id = int(get_jwt_identity())
    m = Mandate(user_id=user_id, provider="UPI", external_mandate_id=f"UPI-{int(time.time())}", status="active")
    db.session.add(m)
    db.session.commit()
    return jsonify(m.to_dict())


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
    m.status = "cancelled"
    db.session.add(EventLog(user_id=user_id, event_type="mandate_cancelled", message=f"Mandate {m.id} cancelled"))
    db.session.commit()
    return jsonify(m.to_dict())

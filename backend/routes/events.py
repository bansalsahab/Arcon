from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..extensions import db
from ..models.event import EventLog

events_bp = Blueprint("events", __name__, url_prefix="/api/events")


@events_bp.get("")
@jwt_required()
def list_events():
    """
    ---
    tags: [Events]
    summary: List recent events
    security:
      - BearerAuth: []
    responses:
      200:
        description: Recent event logs for the user
    """
    user_id = int(get_jwt_identity())
    items = EventLog.query.filter_by(user_id=user_id).order_by(EventLog.created_at.desc()).limit(100).all()
    return jsonify([e.to_dict() for e in items])


@events_bp.post("")
@jwt_required()
def create_event():
    """
    ---
    tags: [Events]
    summary: Create an event log entry
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
            event_type:
              type: string
            message:
              type: string
            amount_paise:
              type: integer
    responses:
      200:
        description: Created event
    """
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    evt = EventLog(
        user_id=user_id,
        event_type=data.get("event_type", "notice"),
        message=data.get("message"),
        amount_paise=data.get("amount_paise"),
    )
    db.session.add(evt)
    db.session.commit()
    return jsonify(evt.to_dict())

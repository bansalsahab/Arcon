from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..extensions import db
from ..models.user import User
from ..models.event import EventLog

users_bp = Blueprint("users", __name__, url_prefix="/api/user")


@users_bp.get("/settings")
@jwt_required()
def get_settings():
    """
    ---
    tags: [User]
    summary: Get user settings
    security:
      - BearerAuth: []
    responses:
      200:
        description: Current user settings
    """
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    return jsonify({
        "rounding_base": user.rounding_base,
        "risk_tier": user.risk_tier,
        "sweep_frequency": user.sweep_frequency,
    })


@users_bp.patch("/settings")
@jwt_required()
def update_settings():
    """
    ---
    tags: [User]
    summary: Update user settings
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
            rounding_base:
              type: integer
              description: Rounding base in rupees (1-1000)
            risk_tier:
              type: string
              enum: [low, medium, high]
            sweep_frequency:
              type: string
              enum: [daily, weekly]
    responses:
      200:
        description: Updated settings
    """
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    data = request.get_json() or {}
    if "rounding_base" in data:
        try:
            rb = int(data["rounding_base"])
            if rb < 1 or rb > 1000:
                return jsonify({"error": "rounding_base must be between 1 and 1000 rupees"}), 400
            user.rounding_base = rb
        except (ValueError, TypeError):
            return jsonify({"error": "rounding_base must be integer"}), 400
    if "risk_tier" in data:
        if data["risk_tier"] not in {"low", "medium", "high"}:
            return jsonify({"error": "risk_tier must be one of low, medium, high"}), 400
        if user.risk_tier != data["risk_tier"]:
            user.risk_tier = data["risk_tier"]
            db.session.add(EventLog(user_id=user_id, event_type="risk_tier_changed", message=f"Risk tier changed to {user.risk_tier}"))
    if "sweep_frequency" in data:
        if data["sweep_frequency"] not in {"daily", "weekly"}:
            return jsonify({"error": "sweep_frequency must be one of daily, weekly"}), 400
        user.sweep_frequency = data["sweep_frequency"]
    db.session.commit()
    return jsonify({
        "rounding_base": user.rounding_base,
        "risk_tier": user.risk_tier,
        "sweep_frequency": user.sweep_frequency,
    })


@users_bp.get("/profile")
@jwt_required()
def get_profile():
    """
    ---
    tags: [User]
    summary: Get user profile
    security:
      - BearerAuth: []
    responses:
      200:
        description: Basic profile
    """
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    return jsonify({
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "created_at": user.created_at.isoformat(),
    })


@users_bp.patch("/profile")
@jwt_required()
def update_profile():
    """
    ---
    tags: [User]
    summary: Update user profile
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
            full_name:
              type: string
    responses:
      200:
        description: Updated profile
    """
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    data = request.get_json() or {}
    if "full_name" in data:
        user.full_name = str(data["full_name"])[:255]
    db.session.commit()
    return jsonify({
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "created_at": user.created_at.isoformat(),
    })

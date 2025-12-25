from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..models.roundup import Roundup

roundups_bp = Blueprint("roundups", __name__, url_prefix="/api/roundups")


@roundups_bp.get("")
@jwt_required()
def list_roundups():
    """
    ---
    tags: [Roundups]
    summary: List roundups with optional status filter
    security:
      - BearerAuth: []
    parameters:
      - in: query
        name: status
        type: string
        enum: [pending, invested]
        required: false
      - in: query
        name: limit
        type: integer
        required: false
        default: 100
    responses:
      200:
        description: List of roundups
    """
    user_id = int(get_jwt_identity())
    status = request.args.get("status")
    try:
        limit = int(request.args.get("limit", 100))
    except ValueError:
        limit = 100
    try:
        offset = int(request.args.get("offset", 0))
    except ValueError:
        offset = 0
    q = Roundup.query.filter_by(user_id=user_id)
    if status in {"pending", "invested"}:
        q = q.filter_by(status=status)
    items = q.order_by(Roundup.created_at.desc()).offset(offset).limit(limit).all()
    return jsonify([r.to_dict() for r in items])


@roundups_bp.get("/pending")
@jwt_required()
def pending_roundups():
    """
    ---
    tags: [Roundups]
    summary: Get pending roundups and total
    security:
      - BearerAuth: []
    responses:
      200:
        description: Total pending roundups in paise and list of items
    """
    user_id = int(get_jwt_identity())
    items = Roundup.query.filter_by(user_id=user_id, status="pending").all()
    total = sum(r.amount_paise for r in items)
    return jsonify({"total_paise": total, "items": [r.to_dict() for r in items]})

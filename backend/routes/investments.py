from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..extensions import db
from ..models.mandate import Mandate
from ..models.investment import InvestmentOrder
from ..models.user import User
from ..services.investment_service import execute_pending_roundups, execute_pending_roundups_allocated
from ..services.allocations_service import get_allocation_for_tier

investments_bp = Blueprint("investments", __name__, url_prefix="/api/investments")


@investments_bp.post("/execute")
@jwt_required()
def execute_investment():
    """
    ---
    tags: [Investments]
    summary: Execute investment by sweeping pending roundups
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
            product_type:
              type: string
              default: mf
    responses:
      200:
        description: Executed investment order
      400:
        description: No active mandate or no pending roundups
    """
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    product_type = data.get("product_type", "mf")
    mandate = Mandate.query.filter_by(user_id=user_id, status="active").first()
    if not mandate:
        return jsonify({"error": "no active mandate"}), 400
    order = execute_pending_roundups(user_id, product_type)
    if not order:
        return jsonify({"error": "no pending roundups"}), 400
    return jsonify(order.to_dict())


@investments_bp.get("")
@jwt_required()
def list_investments():
    """
    ---
    tags: [Investments]
    summary: List investment orders
    security:
      - BearerAuth: []
    responses:
      200:
        description: List of investment orders
    """
    user_id = int(get_jwt_identity())
    try:
        limit = int(request.args.get("limit", 100))
    except ValueError:
        limit = 100
    try:
        offset = int(request.args.get("offset", 0))
    except ValueError:
        offset = 0
    items = (
        InvestmentOrder.query
        .filter_by(user_id=user_id)
        .order_by(InvestmentOrder.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return jsonify([o.to_dict() for o in items])


@investments_bp.post("/execute/allocated")
@jwt_required()
def execute_investment_allocated():
    """
    ---
    tags: [Investments]
    summary: Execute investment by sweeping pending roundups allocated by user's risk tier
    security:
      - BearerAuth: []
    responses:
      200:
        description: Executed one or more investment orders based on allocation
      400:
        description: No active mandate or no pending roundups
    """
    user_id = int(get_jwt_identity())
    mandate = Mandate.query.filter_by(user_id=user_id, status="active").first()
    if not mandate:
        return jsonify({"error": "no active mandate"}), 400
    user = User.query.get(user_id)
    allocation = get_allocation_for_tier(user.risk_tier)
    orders = execute_pending_roundups_allocated(user_id, allocation)
    if not orders:
        return jsonify({"error": "no pending roundups"}), 400
    return jsonify({"orders": [o.to_dict() for o in orders], "allocation_percent": allocation})

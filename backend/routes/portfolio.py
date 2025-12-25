from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..models.roundup import Roundup
from ..models.investment import InvestmentOrder
from ..services.valuation_service import compute_positions_value

portfolio_bp = Blueprint("portfolio", __name__, url_prefix="/api/portfolio")


@portfolio_bp.get("")
@jwt_required()
def get_portfolio():
    """
    ---
    tags: [Portfolio]
    summary: Get portfolio summary (pending and invested totals)
    security:
      - BearerAuth: []
    responses:
      200:
        description: Portfolio totals and position sums (paise)
    """
    user_id = int(get_jwt_identity())
    pending_total = sum(r.amount_paise for r in Roundup.query.filter_by(user_id=user_id, status="pending").all())
    orders = InvestmentOrder.query.filter_by(user_id=user_id, status="executed").all()
    invested_total = sum(o.amount_paise for o in orders)
    positions = {}
    for o in orders:
        positions[o.product_type] = positions.get(o.product_type, 0) + o.amount_paise
    return jsonify({
        "pending_roundups_paise": pending_total,
        "invested_total_paise": invested_total,
        "positions_paise": positions,
    })


@portfolio_bp.get("/value")
@jwt_required()
def get_portfolio_value():
    """
    ---
    tags: [Portfolio]
    summary: Get current portfolio valuation (stub)
    security:
      - BearerAuth: []
    responses:
      200:
        description: Current value and PnL (paise)
    """
    user_id = int(get_jwt_identity())
    data = compute_positions_value(user_id)
    return jsonify(data)

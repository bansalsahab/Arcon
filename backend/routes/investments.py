from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..extensions import db
from ..models.mandate import Mandate
from ..models.investment import InvestmentOrder
from ..models.user import User
from ..services.investment_service import execute_pending_roundups, execute_pending_roundups_allocated
from ..services.allocations_service import get_allocation_for_tier
from ..models.cap_setting import CapSetting
from ..models.redemption import Redemption
from ..models.ledger import LedgerEntry

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
    # Check if investing is paused
    cap = CapSetting.query.filter_by(user_id=user_id).first()
    if cap and cap.investing_paused:
        return jsonify({"error": "investing_paused"}), 400
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
    # Check if investing is paused
    cap = CapSetting.query.filter_by(user_id=user_id).first()
    if cap and cap.investing_paused:
        return jsonify({"error": "investing_paused"}), 400
    mandate = Mandate.query.filter_by(user_id=user_id, status="active").first()
    if not mandate:
        return jsonify({"error": "no active mandate"}), 400
    user = User.query.get(user_id)
    allocation = get_allocation_for_tier(user.risk_tier)
    orders = execute_pending_roundups_allocated(user_id, allocation)
    if not orders:
        return jsonify({"error": "no pending roundups"}), 400
    return jsonify({"orders": [o.to_dict() for o in orders], "allocation_percent": allocation})


@investments_bp.post("/redeem")
@jwt_required()
def redeem():
    """
    ---
    tags: [Investments]
    summary: Redeem (withdraw) invested amount (stub)
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
          required: [amount_paise, product_type]
          properties:
            amount_paise:
              type: integer
            product_type:
              type: string
              default: mf
    responses:
      200:
        description: Redemption executed
    """
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    try:
        amount = int(data.get("amount_paise"))
    except (TypeError, ValueError):
        return jsonify({"error": "amount_paise must be integer"}), 400
    if amount <= 0:
        return jsonify({"error": "amount_paise must be > 0"}), 400
    product_type = (data.get("product_type") or "mf").strip()

    invested = db.session.query(db.func.coalesce(db.func.sum(InvestmentOrder.amount_paise), 0)).filter_by(user_id=user_id, status="executed", product_type=product_type).scalar()
    redeemed = db.session.query(db.func.coalesce(db.func.sum(Redemption.amount_paise), 0)).filter_by(user_id=user_id, status="executed", product_type=product_type).scalar()
    available = int(invested) - int(redeemed)
    if amount > available:
        return jsonify({"error": "insufficient_invested_balance", "available_paise": available}), 400

    r = Redemption(user_id=user_id, product_type=product_type, amount_paise=amount, status="executed")
    db.session.add(r)
    db.session.flush()
    entry = LedgerEntry(user_id=user_id, type="credit", category="redemption", amount_paise=amount, reference_type="Redemption", reference_id=r.id)
    db.session.add(entry)
    db.session.commit()
    return jsonify(r.to_dict())


@investments_bp.get("/redemptions")
@jwt_required()
def list_redemptions():
    """
    ---
    tags: [Investments]
    summary: List redemptions
    security:
      - BearerAuth: []
    responses:
      200:
        description: List of redemptions
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
        Redemption.query
        .filter_by(user_id=user_id)
        .order_by(Redemption.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return jsonify([e.to_dict() for e in items])

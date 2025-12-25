from decimal import Decimal, ROUND_HALF_UP
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..extensions import db
from ..models.user import User
from ..models.transaction import Transaction
from ..services.roundup_service import create_roundup_for_transaction

transactions_bp = Blueprint("transactions", __name__, url_prefix="/api/transactions")


def to_paise(value):
    d = Decimal(str(value)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    return int(d * 100)


@transactions_bp.post("")
@jwt_required()
def create_transaction():
    """
    ---
    tags: [Transactions]
    summary: Create a transaction and auto-generate a roundup
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
          required: [amount]
          properties:
            amount:
              type: number
              format: float
            merchant:
              type: string
    responses:
      200:
        description: Created transaction and optional roundup
    """
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    data = request.get_json() or {}
    amount = data.get("amount")
    if amount is None:
        return jsonify({"error": "amount required"}), 400
    merchant = data.get("merchant")
    amount_paise = to_paise(amount)
    tx = Transaction(user_id=user.id, amount_paise=amount_paise, merchant=merchant)
    db.session.add(tx)
    db.session.commit()
    r = create_roundup_for_transaction(user, tx)
    return jsonify({"transaction": tx.to_dict(), "roundup": r.to_dict() if r else None})


@transactions_bp.get("")
@jwt_required()
def list_transactions():
    """
    ---
    tags: [Transactions]
    summary: List recent transactions
    security:
      - BearerAuth: []
    parameters:
      - in: query
        name: limit
        type: integer
        required: false
        default: 100
      - in: query
        name: offset
        type: integer
        required: false
        default: 0
    responses:
      200:
        description: List of transactions (latest 100)
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
        Transaction.query
        .filter_by(user_id=user_id)
        .order_by(Transaction.timestamp.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return jsonify([t.to_dict() for t in items])

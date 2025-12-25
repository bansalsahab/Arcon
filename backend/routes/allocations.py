from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..models.user import User

allocations_bp = Blueprint("allocations", __name__, url_prefix="/api/allocations")

# Percentages add to 100
RISK_ALLOCATIONS = {
    "low": {
        "mf_debt": 70,
        "mf_equity": 20,
        "gold": 10,
    },
    "medium": {
        "mf_debt": 40,
        "mf_equity": 50,
        "gold": 10,
    },
    "high": {
        "mf_debt": 20,
        "mf_equity": 70,
        "gold": 10,
    },
}


@allocations_bp.get("")
@jwt_required()
def get_allocations():
    """
    ---
    tags: [Allocations]
    summary: Get allocation percentages for user's risk tier
    security:
      - BearerAuth: []
    responses:
      200:
        description: Risk tier and allocation percentages
    """
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    tier = user.risk_tier or "medium"
    return jsonify({
        "risk_tier": tier,
        "allocation_percent": RISK_ALLOCATIONS.get(tier, RISK_ALLOCATIONS["medium"]),
    })

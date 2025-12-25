from collections import defaultdict
from ..models.investment import InvestmentOrder


def compute_positions_value(user_id: int):
    orders = InvestmentOrder.query.filter_by(user_id=user_id, status="executed").all()
    invested_paise_by_product = defaultdict(int)
    for o in orders:
        invested_paise_by_product[o.product_type] += o.amount_paise
    # Stub: current value equals invested amount (PnL = 0)
    current_value_paise_by_product = dict(invested_paise_by_product)
    total_invested = sum(invested_paise_by_product.values())
    total_value = sum(current_value_paise_by_product.values())
    return {
        "invested_paise_by_product": dict(invested_paise_by_product),
        "current_value_paise_by_product": current_value_paise_by_product,
        "total_invested_paise": total_invested,
        "total_value_paise": total_value,
        "pnl_paise": total_value - total_invested,
    }

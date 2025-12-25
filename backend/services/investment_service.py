from ..extensions import db
from ..models.roundup import Roundup
from ..models.investment import InvestmentOrder
from ..models.ledger import LedgerEntry
from typing import Dict, List


def execute_pending_roundups(user_id: int, product_type: str = "mf"):
    pending = Roundup.query.filter_by(user_id=user_id, status="pending").all()
    amount = sum(r.amount_paise for r in pending)
    if amount <= 0:
        return None
    order = InvestmentOrder(user_id=user_id, product_type=product_type, amount_paise=amount, status="executed")
    db.session.add(order)
    db.session.flush()
    for r in pending:
        r.status = "invested"
        r.investment_id = order.id
    entry = LedgerEntry(user_id=user_id, type="debit", category="investment", amount_paise=amount, reference_type="InvestmentOrder", reference_id=order.id)
    db.session.add(entry)
    db.session.commit()
    return order


def execute_pending_roundups_allocated(user_id: int, allocation_percent: Dict[str, int]) -> List[InvestmentOrder]:
    pending = Roundup.query.filter_by(user_id=user_id, status="pending").all()
    total_amount = sum(r.amount_paise for r in pending)
    if total_amount <= 0:
        return []

    # Compute allocations with integer paise rounding, assign remainder to the first key
    keys = [k for k, p in allocation_percent.items() if p > 0]
    if not keys:
        return []
    allocated = {}
    allocated_sum = 0
    for k in keys:
        amt = (total_amount * allocation_percent[k]) // 100
        allocated[k] = amt
        allocated_sum += amt
    remainder = total_amount - allocated_sum
    if remainder:
        first_key = keys[0]
        allocated[first_key] += remainder

    orders: List[InvestmentOrder] = []
    first_order_id = None
    for product_type, amt in allocated.items():
        if amt <= 0:
            continue
        o = InvestmentOrder(user_id=user_id, product_type=product_type, amount_paise=amt, status="executed")
        db.session.add(o)
        db.session.flush()
        if first_order_id is None:
            first_order_id = o.id
        orders.append(o)

    if first_order_id is not None:
        for r in pending:
            r.status = "invested"
            r.investment_id = first_order_id
        entry = LedgerEntry(user_id=user_id, type="debit", category="investment", amount_paise=total_amount, reference_type="InvestmentOrder", reference_id=first_order_id)
        db.session.add(entry)
    db.session.commit()

    return orders

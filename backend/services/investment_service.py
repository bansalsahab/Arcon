from ..extensions import db
from ..models.roundup import Roundup
from ..models.investment import InvestmentOrder
from ..models.ledger import LedgerEntry
from ..providers import get_mf_provider, get_gold_provider
from typing import Dict, List
import logging

def _get_provider(product_type: str):
    if product_type == "mf":
        return get_mf_provider()
    elif product_type == "gold":
        return get_gold_provider()
    return None

def execute_pending_roundups(user_id: int, product_type: str = "mf"):
    pending = Roundup.query.filter_by(user_id=user_id, status="pending").all()
    amount = sum(r.amount_paise for r in pending)
    if amount <= 0:
        return None
    
    # Create order as pending initially
    order = InvestmentOrder(user_id=user_id, product_type=product_type, amount_paise=amount, status="pending")
    db.session.add(order)
    db.session.flush()

    # Call provider
    provider = _get_provider(product_type)
    print(f"DEBUG: execute_pending_roundups pt={product_type} provider={provider}")
    if provider:
        try:
            resp = provider.place_order(user_id, amount, product_type)
            print(f"DEBUG: provider response {resp}")
            order.external_order_id = resp.get("external_order_id")
            if resp.get("status"):
                order.status = str(resp.get("status")).lower()
        except Exception as e:
            order.status = "failed"
            logging.error(f"Investment failed for user {user_id}: {e}")
    else:
        # If no provider (development fallback), mark executed
        order.status = "executed"

    # Only update roundups/ledger if executed or pending (provider dependent)
    # For now, if status is executed, we consider it done.
    if order.status == "executed":
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
    
    # Process each allocation
    for product_type, amt in allocated.items():
        if amt <= 0:
            continue
            
        o = InvestmentOrder(user_id=user_id, product_type=product_type, amount_paise=amt, status="pending")
        db.session.add(o)
        db.session.flush()

        provider = _get_provider(product_type)
        if provider:
            try:
                resp = provider.place_order(user_id, amt, product_type)
                o.external_order_id = resp.get("external_order_id")
                if resp.get("status"):
                    o.status = str(resp.get("status")).lower()
            except Exception as e:
                o.status = "failed"
                logging.error(f"Investment failed for user {user_id}: {e}")
        else:
             o.status = "executed"

        if first_order_id is None and o.status == "executed":
            first_order_id = o.id
        orders.append(o)

    # Update roundups if at least one order succeeded - simplified logic
    # Ideally detailed mapping but for now we link to the first successful one
    if first_order_id is not None:
        for r in pending:
            r.status = "invested"
            r.investment_id = first_order_id
        entry = LedgerEntry(user_id=user_id, type="debit", category="investment", amount_paise=total_amount, reference_type="InvestmentOrder", reference_id=first_order_id)
        db.session.add(entry)
    
    db.session.commit()

    return orders

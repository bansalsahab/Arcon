from ..extensions import db
from ..models.roundup import Roundup


def calculate_roundup_paise(amount_paise: int, base_rupees: int) -> int:
    base_paise = base_rupees * 100
    target = ((amount_paise + base_paise - 1) // base_paise) * base_paise
    return max(0, target - amount_paise)


def create_roundup_for_transaction(user, transaction):
    amount = calculate_roundup_paise(transaction.amount_paise, user.rounding_base)
    if amount <= 0:
        return None
    r = Roundup(user_id=user.id, transaction_id=transaction.id, amount_paise=amount, status="pending")
    db.session.add(r)
    db.session.commit()
    return r

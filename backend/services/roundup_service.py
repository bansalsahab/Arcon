from datetime import datetime, timedelta
from ..extensions import db
from ..models.roundup import Roundup
from ..models.cap_setting import CapSetting


def calculate_roundup_paise(amount_paise: int, base_rupees: int) -> int:
    base_paise = base_rupees * 100
    target = ((amount_paise + base_paise - 1) // base_paise) * base_paise
    return max(0, target - amount_paise)


def create_roundup_for_transaction(user, transaction):
    amount = calculate_roundup_paise(transaction.amount_paise, user.rounding_base)
    if amount <= 0:
        return None

    # Apply caps and pause if configured
    cap = CapSetting.query.filter_by(user_id=user.id).first()
    if cap and cap.investing_paused:
        return None

    # Compute remaining caps for today and this month
    allowed = amount
    now = datetime.utcnow()
    if cap and (cap.daily_cap_paise or cap.monthly_cap_paise):
        # Start of today (UTC)
        day_start = datetime(now.year, now.month, now.day)
        # Start of month (UTC)
        month_start = datetime(now.year, now.month, 1)
        # Sum existing roundups created today/this month
        today_sum = (
            db.session.query(db.func.coalesce(db.func.sum(Roundup.amount_paise), 0))
            .filter(Roundup.user_id == user.id, Roundup.created_at >= day_start)
            .scalar()
        )
        month_sum = (
            db.session.query(db.func.coalesce(db.func.sum(Roundup.amount_paise), 0))
            .filter(Roundup.user_id == user.id, Roundup.created_at >= month_start)
            .scalar()
        )
        if cap.daily_cap_paise is not None:
            remaining_day = max(0, cap.daily_cap_paise - int(today_sum))
            allowed = min(allowed, remaining_day)
        if cap.monthly_cap_paise is not None:
            remaining_month = max(0, cap.monthly_cap_paise - int(month_sum))
            allowed = min(allowed, remaining_month)

    if allowed <= 0:
        return None

    r = Roundup(user_id=user.id, transaction_id=transaction.id, amount_paise=allowed, status="pending")
    db.session.add(r)
    db.session.commit()
    return r

from datetime import datetime
from ..extensions import db


class Mandate(db.Model):
    __tablename__ = "mandates"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    provider = db.Column(db.String(50), default="UPI")
    external_mandate_id = db.Column(db.String(255), index=True)
    status = db.Column(db.String(20), default="pending")  # pending, active, paused, cancelled, failed

    # NPCI / AutoPay parameters
    max_amount_paise = db.Column(db.Integer)
    frequency = db.Column(db.String(20), default="daily")  # daily/weekly/monthly
    start_date = db.Column(db.Date)
    end_date = db.Column(db.Date)

    # Scheduling and provider metadata
    last_debit_at = db.Column(db.DateTime)
    next_debit_at = db.Column(db.DateTime)
    meta_json = db.Column(db.JSON)
    
    # Failure tracking and compliance
    failure_count = db.Column(db.Integer, default=0)
    last_failure_reason = db.Column(db.Text)
    pre_debit_notification_sent_at = db.Column(db.DateTime)
    auth_link = db.Column(db.Text)  # UPI authorization link from payment aggregator

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "provider": self.provider,
            "external_mandate_id": self.external_mandate_id,
            "status": self.status,
            "max_amount_paise": self.max_amount_paise,
            "frequency": self.frequency,
            "start_date": self.start_date.isoformat() if self.start_date else None,
            "end_date": self.end_date.isoformat() if self.end_date else None,
            "last_debit_at": self.last_debit_at.isoformat() if self.last_debit_at else None,
            "next_debit_at": self.next_debit_at.isoformat() if self.next_debit_at else None,
            "created_at": self.created_at.isoformat(),
            "meta": self.meta_json,
        }

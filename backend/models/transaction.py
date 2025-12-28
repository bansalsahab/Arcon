from datetime import datetime
from ..extensions import db


class Transaction(db.Model):
    __tablename__ = "transactions"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    amount_paise = db.Column(db.Integer, nullable=False)
    currency = db.Column(db.String(3), default="INR")
    merchant = db.Column(db.String(255))
    description = db.Column(db.String(255))
    external_transaction_id = db.Column(db.String(255), unique=True, index=True)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    roundups = db.relationship("Roundup", backref="transaction", lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "amount_paise": self.amount_paise,
            "currency": self.currency,
            "merchant": self.merchant,
            "description": self.description,
            "external_transaction_id": self.external_transaction_id,
            "timestamp": self.timestamp.isoformat(),
        }

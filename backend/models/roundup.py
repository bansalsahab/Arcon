from datetime import datetime
from ..extensions import db


class Roundup(db.Model):
    __tablename__ = "roundups"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    transaction_id = db.Column(db.Integer, db.ForeignKey("transactions.id"), nullable=False)
    amount_paise = db.Column(db.Integer, nullable=False)
    status = db.Column(db.String(20), default="pending")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    investment_id = db.Column(db.Integer, db.ForeignKey("investment_orders.id"))

    user = db.relationship("User", backref=db.backref("roundups", lazy=True))

    def to_dict(self):
        return {
            "id": self.id,
            "transaction_id": self.transaction_id,
            "amount_paise": self.amount_paise,
            "status": self.status,
            "created_at": self.created_at.isoformat(),
            "investment_id": self.investment_id,
        }

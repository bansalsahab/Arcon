from datetime import datetime
from ..extensions import db


class InvestmentOrder(db.Model):
    __tablename__ = "investment_orders"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    product_type = db.Column(db.String(20), nullable=False)
    amount_paise = db.Column(db.Integer, nullable=False)
    status = db.Column(db.String(20), default="pending")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    external_order_id = db.Column(db.String(255))

    user = db.relationship("User", backref=db.backref("investment_orders", lazy=True))
    roundups = db.relationship("Roundup", backref="investment_order", lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "product_type": self.product_type,
            "amount_paise": self.amount_paise,
            "status": self.status,
            "created_at": self.created_at.isoformat(),
            "external_order_id": self.external_order_id,
        }

from datetime import datetime
from ..extensions import db


class Redemption(db.Model):
    __tablename__ = "redemptions"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    product_type = db.Column(db.String(20), nullable=False)
    amount_paise = db.Column(db.Integer, nullable=False)
    status = db.Column(db.String(20), default="executed")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    external_order_id = db.Column(db.String(255))

    user = db.relationship("User", backref=db.backref("redemptions", lazy=True))

    def to_dict(self):
        return {
            "id": self.id,
            "product_type": self.product_type,
            "amount_paise": self.amount_paise,
            "status": self.status,
            "created_at": self.created_at.isoformat(),
            "external_order_id": self.external_order_id,
        }

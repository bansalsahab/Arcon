from datetime import datetime
from ..extensions import db


class LedgerEntry(db.Model):
    __tablename__ = "ledger_entries"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    type = db.Column(db.String(10), nullable=False)
    category = db.Column(db.String(50))
    amount_paise = db.Column(db.Integer, nullable=False)
    reference_type = db.Column(db.String(50))
    reference_id = db.Column(db.Integer)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    user = db.relationship("User", backref=db.backref("ledger_entries", lazy=True))

    def to_dict(self):
        return {
            "id": self.id,
            "type": self.type,
            "category": self.category,
            "amount_paise": self.amount_paise,
            "reference_type": self.reference_type,
            "reference_id": self.reference_id,
            "timestamp": self.timestamp.isoformat(),
        }

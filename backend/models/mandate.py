from datetime import datetime
from ..extensions import db


class Mandate(db.Model):
    __tablename__ = "mandates"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    provider = db.Column(db.String(50), default="UPI")
    external_mandate_id = db.Column(db.String(255))
    status = db.Column(db.String(20), default="active")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "provider": self.provider,
            "external_mandate_id": self.external_mandate_id,
            "status": self.status,
            "created_at": self.created_at.isoformat(),
        }

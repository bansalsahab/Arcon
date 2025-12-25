from datetime import datetime
from ..extensions import db


class KYCRecord(db.Model):
    __tablename__ = "kyc_records"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, unique=True)
    pan = db.Column(db.String(10), nullable=True)
    aadhaar_last4 = db.Column(db.String(4), nullable=True)
    status = db.Column(db.String(20), default="not_started")  # not_started|submitted|verified|rejected
    rejection_reason = db.Column(db.String(255))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = db.relationship("User", backref=db.backref("kyc_record", uselist=False))

    def to_dict(self):
        return {
            "user_id": self.user_id,
            "pan": self.pan,
            "aadhaar_last4": self.aadhaar_last4,
            "status": self.status,
            "rejection_reason": self.rejection_reason,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

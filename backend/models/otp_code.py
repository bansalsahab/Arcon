from datetime import datetime, timedelta
from ..extensions import db


class OTPCode(db.Model):
    __tablename__ = "otp_codes"

    id = db.Column(db.Integer, primary_key=True)
    phone = db.Column(db.String(32), index=True, nullable=False)
    code = db.Column(db.String(6), nullable=False)
    expires_at = db.Column(db.DateTime, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    @staticmethod
    def create(phone: str, code: str, ttl_seconds: int = 300):
        rec = OTPCode(phone=phone, code=code, expires_at=datetime.utcnow() + timedelta(seconds=ttl_seconds))
        db.session.add(rec)
        db.session.commit()
        return rec

from datetime import datetime
from ..extensions import db


class CapSetting(db.Model):
    __tablename__ = "cap_settings"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), unique=True, nullable=False)
    investing_paused = db.Column(db.Boolean, default=False)
    daily_cap_paise = db.Column(db.Integer)
    monthly_cap_paise = db.Column(db.Integer)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = db.relationship("User", backref=db.backref("cap_setting", uselist=False))

    def to_dict(self):
        return {
            "investing_paused": self.investing_paused,
            "daily_cap_paise": self.daily_cap_paise,
            "monthly_cap_paise": self.monthly_cap_paise,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

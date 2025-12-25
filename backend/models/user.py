from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from ..extensions import db


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    full_name = db.Column(db.String(255))
    risk_tier = db.Column(db.String(20), default="medium")
    rounding_base = db.Column(db.Integer, default=10)
    sweep_frequency = db.Column(db.String(20), default="daily")  # daily|weekly
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    transactions = db.relationship("Transaction", backref="user", lazy=True)
    mandates = db.relationship("Mandate", backref="user", lazy=True)

    def set_password(self, password: str):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password: str) -> bool:
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            "id": self.id,
            "email": self.email,
            "full_name": self.full_name,
            "risk_tier": self.risk_tier,
            "rounding_base": self.rounding_base,
            "sweep_frequency": self.sweep_frequency,
            "created_at": self.created_at.isoformat(),
        }

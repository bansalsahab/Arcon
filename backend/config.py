import os
from datetime import timedelta

class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret")
    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY", "dev-jwt-secret")
    SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE_URL", "sqlite:///roundup.db")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=int(os.environ.get("JWT_ACCESS_MINUTES", "15")))
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=int(os.environ.get("JWT_REFRESH_DAYS", "30")))
    UPI_PROVIDER = os.environ.get("UPI_PROVIDER", "mock")
    MF_PROVIDER = os.environ.get("MF_PROVIDER", "mock")
    GOLD_PROVIDER = os.environ.get("GOLD_PROVIDER", "mock")
    PROVIDER_USE_ORDERS = os.environ.get("PROVIDER_USE_ORDERS", "false").lower() == "true"
    PAY_KEY_ID = os.environ.get("PAY_KEY_ID")
    PAY_KEY_SECRET = os.environ.get("PAY_KEY_SECRET")
    CASHFREE_CLIENT_ID = os.environ.get("CASHFREE_CLIENT_ID")
    CASHFREE_CLIENT_SECRET = os.environ.get("CASHFREE_CLIENT_SECRET")
    MFU_CLIENT_ID = os.environ.get("MFU_CLIENT_ID")
    MFU_CLIENT_SECRET = os.environ.get("MFU_CLIENT_SECRET")
    BSESTAR_MF_MEMBER_ID = os.environ.get("BSESTAR_MF_MEMBER_ID")
    BSESTAR_MF_PASSWORD = os.environ.get("BSESTAR_MF_PASSWORD")
    SAFEGOLD_API_TOKEN = os.environ.get("SAFEGOLD_API_TOKEN")
    PAY_WEBHOOK_SECRET = os.environ.get("PAY_WEBHOOK_SECRET")

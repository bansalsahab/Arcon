from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity, get_jwt
from ..extensions import db
from ..models.user import User
from ..models.otp_code import OTPCode
from ..models.phone_account import PhoneAccount
from ..models.token_blocklist import TokenBlocklist
from datetime import datetime
import secrets

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")


@auth_bp.post("/register")
def register():
    """
    ---
    tags: [Auth]
    summary: Register a new user
    consumes:
      - application/json
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [email, password]
          properties:
            email:
              type: string
            password:
              type: string
            full_name:
              type: string
    responses:
      200:
        description: Successful registration returns JWT token and user
    """
    data = request.get_json() or {}
    email = data.get("email")
    password = data.get("password")
    full_name = data.get("full_name")
    if not email or not password:
        return jsonify({"error": "email and password required"}), 400
    if User.query.filter_by(email=email).first():
        return jsonify({"error": "email already exists"}), 400
    user = User(email=email, full_name=full_name)
    user.set_password(password)
    db.session.add(user)
    db.session.commit()
    token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))
    return jsonify({"access_token": token, "refresh_token": refresh_token, "user": user.to_dict()})


@auth_bp.post("/logout/access")
@jwt_required()
def logout_access():
    """
    ---
    tags: [Auth]
    summary: Revoke current access token (logout)
    security:
      - BearerAuth: []
    responses:
      200:
        description: Revoked
    """
    jti = get_jwt().get("jti")
    if jti:
        if not TokenBlocklist.query.filter_by(jti=jti).first():
            db.session.add(TokenBlocklist(jti=jti))
            db.session.commit()
    return jsonify({"revoked": True})


@auth_bp.post("/logout/refresh")
@jwt_required(refresh=True)
def logout_refresh():
    """
    ---
    tags: [Auth]
    summary: Revoke current refresh token (logout all sessions if used)
    security:
      - BearerAuth: []
    responses:
      200:
        description: Revoked
    """
    jti = get_jwt().get("jti")
    if jti:
        if not TokenBlocklist.query.filter_by(jti=jti).first():
            db.session.add(TokenBlocklist(jti=jti))
            db.session.commit()
    return jsonify({"revoked": True})


@auth_bp.post("/login")
def login():
    """
    ---
    tags: [Auth]
    summary: Login with email and password
    consumes:
      - application/json
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [email, password]
          properties:
            email:
              type: string
            password:
              type: string
    responses:
      200:
        description: Successful login returns JWT token and user
    """
    data = request.get_json() or {}
    email = data.get("email")
    password = data.get("password")
    if not email or not password:
        return jsonify({"error": "email and password required"}), 400
    user = User.query.filter_by(email=email).first()
    if not user or not user.check_password(password):
        return jsonify({"error": "invalid credentials"}), 401
    token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))
    return jsonify({"access_token": token, "refresh_token": refresh_token, "user": user.to_dict()})


@auth_bp.get("/me")
@jwt_required()
def me():
    """
    ---
    tags: [Auth]
    summary: Get current logged-in user
    security:
      - BearerAuth: []
    responses:
      200:
        description: Current user details
      401:
        description: Unauthorized
    """
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "not found"}), 404
    return jsonify(user.to_dict())


@auth_bp.post("/refresh")
@jwt_required(refresh=True)
def refresh():
    user_id = int(get_jwt_identity())
    new_access = create_access_token(identity=str(user_id))
    return jsonify({"access_token": new_access})


@auth_bp.post("/request-otp")
def request_otp():
    """
    ---
    tags: [Auth]
    summary: Request OTP for phone login (stub)
    consumes:
      - application/json
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [phone]
          properties:
            phone:
              type: string
    responses:
      200:
        description: OTP sent (stub). dev_code contains the OTP in development.
    """
    data = request.get_json() or {}
    phone = (data.get("phone") or "").strip()
    if not phone:
        return jsonify({"error": "phone required"}), 400
    code = f"{secrets.randbelow(10000):04d}"
    OTPCode.create(phone, code, ttl_seconds=300)
    # In production we would send SMS here.
    return jsonify({"sent": True, "dev_code": code})


@auth_bp.post("/verify-otp")
def verify_otp():
    """
    ---
    tags: [Auth]
    summary: Verify OTP and login/create account (stub)
    consumes:
      - application/json
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [phone, code]
          properties:
            phone:
              type: string
            code:
              type: string
    responses:
      200:
        description: JWT tokens and user
    """
    data = request.get_json() or {}
    phone = (data.get("phone") or "").strip()
    code = (data.get("code") or "").strip()
    if not phone or not code:
        return jsonify({"error": "phone and code required"}), 400
    rec = OTPCode.query.filter_by(phone=phone, code=code).order_by(OTPCode.created_at.desc()).first()
    if not rec or rec.expires_at < datetime.utcnow():
        return jsonify({"error": "invalid_or_expired_code"}), 400

    # Find or create user linked to this phone
    pa = PhoneAccount.query.filter_by(phone=phone).first()
    if pa:
        user = User.query.get(pa.user_id)
    else:
        # Create minimal user with synthetic email
        local_email = f"user_{phone.replace('+','').replace(' ', '')}@local"
        if User.query.filter_by(email=local_email).first():
            local_email = f"user_{secrets.token_hex(4)}_{phone}@local"
        user = User(email=local_email)
        user.set_password(secrets.token_urlsafe(12))
        db.session.add(user)
        db.session.flush()
        pa = PhoneAccount(user_id=user.id, phone=phone)
        db.session.add(pa)
        db.session.commit()

    token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))
    return jsonify({"access_token": token, "refresh_token": refresh_token, "user": user.to_dict()})

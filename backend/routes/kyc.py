from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..extensions import db
from ..models.kyc import KYCRecord

kyc_bp = Blueprint("kyc", __name__, url_prefix="/api/kyc")


def _get_or_create_record(user_id: int) -> KYCRecord:
    rec = KYCRecord.query.filter_by(user_id=user_id).first()
    if not rec:
        rec = KYCRecord(user_id=user_id, status="not_started")
        db.session.add(rec)
        db.session.commit()
    return rec


@kyc_bp.get("")
@jwt_required()
def get_kyc():
    """
    ---
    tags: [KYC]
    summary: Get KYC record for current user
    security:
      - BearerAuth: []
    responses:
      200:
        description: KYC record
    """
    user_id = int(get_jwt_identity())
    rec = _get_or_create_record(user_id)
    return jsonify(rec.to_dict())


@kyc_bp.post("/start")
@jwt_required()
def start_kyc():
    """
    ---
    tags: [KYC]
    summary: Start KYC by submitting PAN and Aadhaar last4
    security:
      - BearerAuth: []
    consumes:
      - application/json
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [pan, aadhaar_last4]
          properties:
            pan:
              type: string
            aadhaar_last4:
              type: string
    responses:
      200:
        description: KYC submitted
    """
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    pan = (data.get("pan") or "").upper().strip()
    aadhaar_last4 = (data.get("aadhaar_last4") or "").strip()
    if not pan or not aadhaar_last4:
        return jsonify({"error": "pan and aadhaar_last4 required"}), 400
    rec = _get_or_create_record(user_id)
    rec.pan = pan
    rec.aadhaar_last4 = aadhaar_last4[-4:]
    rec.status = "submitted"
    db.session.commit()
    return jsonify(rec.to_dict())


@kyc_bp.post("/verify")
@jwt_required()
def verify_kyc():
    """
    ---
    tags: [KYC]
    summary: Verify KYC (stub)
    description: Stub verification checks PAN length=10 and Aadhaar last4 length=4
    security:
      - BearerAuth: []
    responses:
      200:
        description: KYC verified or rejected with reason
    """
    user_id = int(get_jwt_identity())
    rec = _get_or_create_record(user_id)
    if rec.status not in {"submitted", "rejected"}:
        # idempotent verify for verified users
        if rec.status == "verified":
            return jsonify(rec.to_dict())
    # Stub verification rules
    if rec.pan and len(rec.pan) == 10 and rec.aadhaar_last4 and len(rec.aadhaar_last4) == 4:
        rec.status = "verified"
        rec.rejection_reason = None
    else:
        rec.status = "rejected"
        rec.rejection_reason = "Invalid PAN or Aadhaar last4"
    db.session.commit()
    return jsonify(rec.to_dict())

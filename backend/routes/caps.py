from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..extensions import db
from ..models.cap_setting import CapSetting

caps_bp = Blueprint("caps", __name__, url_prefix="/api/user/caps")


@caps_bp.get("")
@jwt_required()
def get_caps():
    """
    ---
    tags: [User]
    summary: Get investing pause/daily/monthly caps
    security:
      - BearerAuth: []
    responses:
      200:
        description: Current caps
    """
    uid = int(get_jwt_identity())
    cap = CapSetting.query.filter_by(user_id=uid).first()
    if not cap:
        return jsonify({"investing_paused": False, "daily_cap_paise": None, "monthly_cap_paise": None})
    return jsonify(cap.to_dict())


@caps_bp.patch("")
@jwt_required()
def update_caps():
    """
    ---
    tags: [User]
    summary: Update investing pause/daily/monthly caps
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
          properties:
            investing_paused:
              type: boolean
            daily_cap_paise:
              type: integer
            monthly_cap_paise:
              type: integer
    responses:
      200:
        description: Updated caps
    """
    uid = int(get_jwt_identity())
    data = request.get_json() or {}
    cap = CapSetting.query.filter_by(user_id=uid).first()
    if not cap:
        cap = CapSetting(user_id=uid)
        db.session.add(cap)

    if "investing_paused" in data:
        cap.investing_paused = bool(data["investing_paused"])
    if "daily_cap_paise" in data:
        v = data["daily_cap_paise"]
        if v is not None:
            try:
                v = int(v)
                if v < 0:
                    return jsonify({"error": "daily_cap_paise must be >= 0"}), 400
            except (TypeError, ValueError):
                return jsonify({"error": "daily_cap_paise must be integer or null"}), 400
        cap.daily_cap_paise = v
    if "monthly_cap_paise" in data:
        v = data["monthly_cap_paise"]
        if v is not None:
            try:
                v = int(v)
                if v < 0:
                    return jsonify({"error": "monthly_cap_paise must be >= 0"}), 400
            except (TypeError, ValueError):
                return jsonify({"error": "monthly_cap_paise must be integer or null"}), 400
        cap.monthly_cap_paise = v

    db.session.commit()
    return jsonify(cap.to_dict())

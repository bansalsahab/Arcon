import os
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from openai import OpenAI

ai_bp = Blueprint("ai", __name__, url_prefix="/api/ai")


def _get_openai_client():
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        return None, "Missing OPENAI_API_KEY environment variable"
    try:
        client = OpenAI(api_key=api_key)
        return client, None
    except Exception as e:
        return None, str(e)


@ai_bp.post("/advice")
@jwt_required()
def advice():
    """
    ---
    tags: [AI]
    summary: Get AI advice via OpenAI
    security:
      - BearerAuth: []
    consumes:
      - application/json
    parameters:
      - in: body
        name: body
        schema:
          type: object
          properties:
            topic:
              type: string
              default: portfolio
            messages:
              type: array
              items:
                type: object
                properties:
                  role:
                    type: string
                  content:
                    type: string
    responses:
      200:
        description: AI advice response
      400:
        description: Missing API key or invalid input
    """
    user_id = get_jwt_identity()
    payload = request.get_json() or {}
    topic = payload.get("topic", "portfolio")

    model = os.environ.get("OPENAI_MODEL", "gpt-4o-mini")
    client, err = _get_openai_client()
    if err:
        return jsonify({"error": err}), 400

    # Allow custom messages or build a simple default prompt
    messages = payload.get("messages")
    if not messages:
        messages = [
            {
                "role": "user",
                "content": f"Provide concise, non-advisory educational guidance about '{topic}' for a novice Indian retail investor."
            }
        ]

    try:
        resp = client.chat.completions.create(
            model=model,
            messages=messages,
        )
        msg = resp.choices[0].message
        out = {
            "topic": topic,
            "model": model,
            "message": {"role": getattr(msg, "role", "assistant"), "content": getattr(msg, "content", "")},
        }
        # Some models may return reasoning details attached to the message
        reasoning_details = getattr(msg, "reasoning_details", None)
        if reasoning_details is not None:
            out["reasoning_details"] = reasoning_details
        return jsonify(out)
    except Exception as e:
        return jsonify({"error": str(e)}), 400

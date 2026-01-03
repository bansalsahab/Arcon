import os
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from openai import OpenAI
from ..models.user import User
from ..models.ledger import LedgerEntry
from ..models.roundup import Roundup
from ..models.mandate import Mandate
from sqlalchemy import func

ai_bp = Blueprint("ai", __name__, url_prefix="/api/ai")

# Finance-focused AI system prompt
FINANCE_ASSISTANT_SYSTEM_PROMPT = """You are a finance-only AI assistant embedded inside an Indian micro-investing app that helps users invest spare change via UPI AutoPay. Your role is strictly limited to providing educational, explanatory, and portfolio-related assistance.

**What you CAN do:**
- Answer questions about the user's own portfolio, round-up investing, mutual funds, digital gold, and asset allocation
- Explain how the app works and its features
- Discuss basic financial concepts in simple, non-technical language
- Explain investment progress and roundup mechanics
- Clarify SEBI/RBI regulations related to the app

**What you CANNOT do:**
- Provide personalized financial advice, stock tips, market predictions, or tax advice
- Recommend specific securities to buy or sell
- Execute any actions in the app (only explain how users can do it)
- Answer questions unrelated to finance, investments, portfolio tracking, or app features
- Hallucinate data - only use portfolio data explicitly provided in the context

**Guidelines:**
- Always prioritize safety, clarity, and compliance with Indian regulations (SEBI/RBI)
- Use simple, non-technical language suitable for first-time investors
- Include gentle disclaimers when needed (e.g., "Past performance doesn't guarantee future results")
- Avoid jargon; explain terms when necessary
- If asked something outside your scope, politely refuse and redirect to supported topics

**Response format:**
Keep responses concise (2-3 paragraphs max), helpful, and educational. Always end with "Is there anything else about your portfolio or the app I can help explain?"
"""


def _get_openai_client():
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        return None, "Missing OPENAI_API_KEY environment variable"
    try:
        client = OpenAI(api_key=api_key)
        return client, None
    except Exception as e:
        return None, str(e)


def _get_user_portfolio_context(user_id: int) -> str:
    """Get user's portfolio data to inject as context for AI."""
    try:
        user = User.query.get(user_id)
        if not user:
            return "Portfolio data unavailable."
        
        # Get portfolio summary
        invested = LedgerEntry.query.filter_by(user_id=user_id).with_entities(
            func.sum(LedgerEntry.amount_paise)
        ).scalar() or 0
        
        # Pending roundups
        pending = Roundup.query.filter_by(user_id=user_id, swept=False).with_entities(
            func.sum(Roundup.roundup_paise)
        ).scalar() or 0
        
        # Mandate status
        mandate = Mandate.query.filter_by(user_id=user_id, status='active').first()
        autopay_status = "Active" if mandate else "Not set up"
        
        # Build context
        context = f"""**User Portfolio Data (for reference only):**
- Total Invested: ₹{invested / 100:.2f}
- Pending Roundups: ₹{pending / 100:.2f}
- UPI AutoPay Status: {autopay_status}
- Risk Tier: {user.risk_tier or 'Not set'}
- Rounding Base: ₹{user.rounding_base or 10}

Use this data ONLY when the user asks about their portfolio. Do not volunteer this information unless relevant to their question."""
        
        return context
        
    except Exception as e:
        current_app.logger.error(f"Error fetching portfolio context: {e}")
        return "Portfolio data temporarily unavailable."


@ai_bp.post("/advice")
@jwt_required()
def advice():
    """
    ---
    tags: [AI]
    summary: Get finance-focused AI advice (portfolio education only)
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
              description: User's question about portfolio/app
              example: "How does round-up investing work?"
            messages:
              type: array
              description: Custom conversation history (optional)
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
    topic = payload.get("topic", "portfolio help")

    model = os.environ.get("OPENAI_MODEL", "gpt-4o-mini")
    client, err = _get_openai_client()
    if err:
        return jsonify({"error": err}), 400

    # Get user's portfolio context
    portfolio_context = _get_user_portfolio_context(user_id)
    
    # Build messages with system prompt + portfolio context
    messages = payload.get("messages")
    if not messages:
        messages = [
            {
                "role": "system",
                "content": FINANCE_ASSISTANT_SYSTEM_PROMPT
            },
            {
                "role": "system", 
                "content": portfolio_context
            },
            {
                "role": "user",
                "content": topic
            }
        ]
    else:
        # If custom messages provided, prepend system prompts
        messages = [
            {"role": "system", "content": FINANCE_ASSISTANT_SYSTEM_PROMPT},
            {"role": "system", "content": portfolio_context}
        ] + messages

    try:
        resp = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=0.7,  # Balanced creativity
            max_tokens=500,  # Keep responses concise
        )
        msg = resp.choices[0].message
        out = {
            "topic": topic,
            "model": model,
            "message": {"role": getattr(msg, "role", "assistant"), "content": getattr(msg, "content", "")},
        }
        
        return jsonify(out)
    except Exception as e:
        current_app.logger.error(f"OpenAI API error: {e}")
        return jsonify({"error": str(e)}), 400

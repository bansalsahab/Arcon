from flask import Flask, jsonify
from flask_cors import CORS
from flasgger import Swagger
from .config import Config
from .extensions import db, jwt
from dotenv import load_dotenv


def create_app():
    app = Flask(__name__)
    load_dotenv()
    app.config.from_object(Config)
    CORS(app, supports_credentials=True)
    app.config["SWAGGER"] = {
        "title": "Roundup Investing API",
        "uiversion": 3,
    }

    db.init_app(app)
    jwt.init_app(app)

    # JWT blocklist (revocation) callback
    from .models.token_blocklist import TokenBlocklist  # noqa: E402

    @jwt.token_in_blocklist_loader
    def check_if_token_revoked(jwt_header, jwt_payload):
        jti = jwt_payload.get("jti")
        if not jti:
            return False
        return TokenBlocklist.query.filter_by(jti=jti).first() is not None

    with app.app_context():
        from .models import user, transaction, roundup, ledger, mandate, investment, kyc, event, otp_code, phone_account, cap_setting, token_blocklist, user_profile, redemption
        db.create_all()

    swagger_template = {
        "swagger": "2.0",
        "info": {
            "title": "Roundup Investing API",
            "version": "v1",
            "description": "APIs for UPI roundup investing flows. Use Authorize to set 'Bearer <JWT>'.",
        },
        "basePath": "/",
        "securityDefinitions": {
            "BearerAuth": {
                "type": "apiKey",
                "name": "Authorization",
                "in": "header",
                "description": "JWT Authorization header using the Bearer scheme. Example: 'Bearer eyJ0eXAiOiJKV1Qi...'",
            }
        },
        "security": [{"BearerAuth": []}],
        "tags": [
            {"name": "Auth"},
            {"name": "User"},
            {"name": "Transactions"},
            {"name": "Roundups"},
            {"name": "Investments"},
            {"name": "Mandates"},
            {"name": "Portfolio"},
            {"name": "Ledger"},
            {"name": "KYC"},
            {"name": "Allocations"},
            {"name": "Events"},
            {"name": "Scheduler"},
            {"name": "AI"},
            {"name": "Notifications"},
            {"name": "Compliance"},
        ],
    }

    swagger_config = {
        "headers": [],
        "specs": [
            {
                "endpoint": "apispec_1",
                "route": "/api/docs.json",
                "rule_filter": lambda rule: True,
                "model_filter": lambda tag: True,
            }
        ],
        "static_url_path": "/flasgger_static",
        "swagger_ui": True,
        "specs_route": "/api/docs/",
    }

    Swagger(app, template=swagger_template, config=swagger_config)

    from .routes.auth import auth_bp
    from .routes.transactions import transactions_bp
    from .routes.roundups import roundups_bp
    from .routes.portfolio import portfolio_bp
    from .routes.mandates import mandates_bp
    from .routes.investments import investments_bp
    from .routes.users import users_bp
    from .routes.ai import ai_bp
    from .routes.ledger import ledger_bp
    from .routes.kyc import kyc_bp
    from .routes.allocations import allocations_bp
    from .routes.events import events_bp
    from .routes.notifications import notifications_bp
    from .routes.compliance import compliance_bp
    from .routes.caps import caps_bp
    from .routes.scheduler import scheduler_bp
    from .routes.webhooks import webhooks_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(transactions_bp)
    app.register_blueprint(roundups_bp)
    app.register_blueprint(portfolio_bp)
    app.register_blueprint(mandates_bp)
    app.register_blueprint(investments_bp)
    app.register_blueprint(users_bp)
    app.register_blueprint(ai_bp)
    app.register_blueprint(ledger_bp)
    app.register_blueprint(kyc_bp)
    app.register_blueprint(allocations_bp)
    app.register_blueprint(events_bp)
    app.register_blueprint(scheduler_bp)
    app.register_blueprint(notifications_bp)
    app.register_blueprint(compliance_bp)
    app.register_blueprint(caps_bp)
    app.register_blueprint(webhooks_bp)

    @app.get("/api/health")
    def health():
        return jsonify({"status": "ok"})

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

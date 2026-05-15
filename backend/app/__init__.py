from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv

def create_app():
    load_dotenv()

    app = Flask(__name__)

    allowed_origins = [
        "http://localhost:*",
        "http://127.0.0.1:3000",
        "http://localhost:5000",
        "http://127.0.0.1:5000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "https://what-makes-me-itch.vercel.app",
    ]

    CORS(
        app,
        resources={r"/*": {"origins": allowed_origins}},
        supports_credentials=True,
    )

    # Register blueprints
    from .routes.auth import auth_bp
    from .routes.chat import chat_bp
    from .routes.users import users_bp
    from .routes.analytics import analytics_bp
    from .routes.allergy_entries import allergy_entries_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(chat_bp)
    app.register_blueprint(users_bp)
    app.register_blueprint(analytics_bp)
    app.register_blueprint(allergy_entries_bp)

    # simple health check
    @app.route("/", methods=["GET"])
    def index():
        return "Hello, this endpoint is working!"

    return app
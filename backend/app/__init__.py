from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv

def create_app():
    load_dotenv()

    app = Flask(__name__)
    CORS(app)

    # Register blueprints
    from .routes.auth import auth_bp
    from .routes.chat import chat_bp
    from .routes.users import users_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(chat_bp)
    app.register_blueprint(users_bp)

    # simple health check
    @app.route("/", methods=["GET"])
    def index():
        return "Hello, this endpoint is working!"

    return app
import os
from flask import Flask
from flask_cors import CORS


def create_app():
    app = Flask(__name__)
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    app.config["MAX_CONTENT_LENGTH"] = int(os.getenv("MAX_IMAGE_SIZE_MB", 10)) * 1024 * 1024
    app.config["BLUR_THRESHOLD"] = int(os.getenv("BLUR_THRESHOLD", 100))
    app.config["BRIGHTNESS_THRESHOLD"] = int(os.getenv("BRIGHTNESS_THRESHOLD", 50))

    from .routes.analyze import analyze_bp
    from .routes.meals import meals_bp
    from .routes.food import food_bp
    from .routes.profile import profile_bp

    app.register_blueprint(analyze_bp, url_prefix="/api")
    app.register_blueprint(meals_bp, url_prefix="/api")
    app.register_blueprint(food_bp, url_prefix="/api")
    app.register_blueprint(profile_bp, url_prefix="/api")

    @app.route("/health")
    def health():
        return {"status": "ok"}, 200

    return app

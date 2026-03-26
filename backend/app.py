from flask import Flask
from flask_cors import CORS
from .config import Config
from .models.db import db
from .routes.analyze_route import analyze_bp
from .routes.history_route import history_bp
import os

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    
    # Setup CORS for Flutter web / mobile testing
    CORS(app)
    
    # Initialize SQLAlchemy
    db.init_app(app)
    
    with app.app_context():
        # Create tables if they don't exist
        db.create_all()
        
    # Register blueprints
    app.register_blueprint(analyze_bp)
    app.register_blueprint(history_bp)
    
    # Ensure upload folder exists
    os.makedirs(Config.UPLOAD_FOLDER, exist_ok=True)
    
    @app.route('/', methods=['GET'])
    def index():
        return {"message": "Nutrition Analyzer AI Backend is running."}

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5000)

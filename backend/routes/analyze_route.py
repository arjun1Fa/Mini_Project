import os
from flask import Blueprint, request, jsonify
from werkzeug.utils import secure_filename
from ..utils.auth import token_required
from ..services.ai_service import process_image
from ..services.nutrition_service import calculate_nutrition
from ..models.db_models import FoodLog
from ..models.db import db
from ..config import Config

analyze_bp = Blueprint('analyze', __name__)

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in {'png', 'jpg', 'jpeg'}

@analyze_bp.route('/analyze', methods=['POST'])
@token_required
def analyze_food(current_user_id):
    if 'image' not in request.files:
        return jsonify({"error": "No image part in the request"}), 400
        
    file = request.files['image']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
        
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        # Ensure upload dir exists
        os.makedirs(Config.UPLOAD_FOLDER, exist_ok=True)
        
        filepath = os.path.join(Config.UPLOAD_FOLDER, filename)
        file.save(filepath)
        
        try:
            # 1. AI Processing
            ai_result = process_image(filepath)
            food_name = ai_result['food_name']
            area_cm2 = ai_result['area_cm2']
            
            # 2. Nutrition Calculation
            nutrition_data = calculate_nutrition(food_name, area_cm2)
            
            # 3. Save to Database
            new_log = FoodLog(
                user_id=current_user_id,
                food_name=nutrition_data['food'],
                weight_g=nutrition_data['weight_g'],
                calories=nutrition_data['calories'],
                protein=nutrition_data['protein'],
                carbs=nutrition_data['carbs'],
                fat=nutrition_data['fat'],
                image_path=filepath
            )
            
            db.session.add(new_log)
            db.session.commit()
            
            return jsonify({
                "message": "Analysis complete",
                "food": nutrition_data['food'],
                "weight": nutrition_data['weight'],
                "calories": nutrition_data['calories'],
                "protein": nutrition_data['protein'],
                "carbs": nutrition_data['carbs'],
                "fat": nutrition_data['fat']
            }), 200
            
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500
            
    return jsonify({"error": "Allowed image types are png, jpg, jpeg"}), 400

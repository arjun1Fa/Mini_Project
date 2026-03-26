from flask import Blueprint, jsonify
from ..utils.auth import token_required
from ..models.db_models import FoodLog

history_bp = Blueprint('history', __name__)

@history_bp.route('/history', methods=['GET'])
@token_required
def get_user_history(current_user_id):
    try:
        logs = FoodLog.query.filter_by(user_id=current_user_id).order_by(FoodLog.created_at.desc()).all()
        return jsonify([log.to_dict() for log in logs]), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

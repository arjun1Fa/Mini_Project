"""
GET /api/food/search?q=<query>
Used by the manual food name correction modal in the app.
"""
from flask import Blueprint, request, jsonify
from ..utils.auth import require_auth
from ..db.supabase_client import search_food
from ..utils.nutrition_calculator import FALLBACK_NUTRITION

food_bp = Blueprint("food", __name__)


@food_bp.route("/food/search", methods=["GET"])
@require_auth
def food_search():
    query = request.args.get("q", "").strip()
    if not query:
        return jsonify({"results": []}), 200

    # Try Supabase first
    results = search_food(query, limit=20)

    if not results:
        # Fallback: search the local FALLBACK_NUTRITION dict
        q_lower = query.lower()
        results = [
            {
                "food_name": k,
                "calories_per_100g": v["calories_per_100g"],
                "protein_per_100g": v["protein_per_100g"],
                "carbs_per_100g": v["carbs_per_100g"],
                "fat_per_100g": v["fat_per_100g"],
            }
            for k, v in FALLBACK_NUTRITION.items()
            if q_lower in k.replace("_", " ")
        ][:20]

    return jsonify({"results": results}), 200

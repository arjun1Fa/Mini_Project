"""
PUT /api/profile  — update user settings
GET /api/profile  — fetch user settings
"""
from flask import Blueprint, request, jsonify, g
from ..utils.auth import require_auth
from ..db.supabase_client import get_profile, upsert_profile

profile_bp = Blueprint("profile", __name__)

ALLOWED_FIELDS = {"full_name", "daily_goal_kcal", "plate_type", "units"}


@profile_bp.route("/profile", methods=["GET"])
@require_auth
def get_user_profile():
    profile = get_profile(g.user_id)
    if profile is None:
        return jsonify({"error": "not_found", "message": "Profile not found"}), 404
    return jsonify(profile), 200


@profile_bp.route("/profile", methods=["PUT"])
@require_auth
def update_profile():
    body = request.get_json(silent=True) or {}

    # Filter only permitted fields
    updates = {k: v for k, v in body.items() if k in ALLOWED_FIELDS}
    if not updates:
        return jsonify({"error": "no_valid_fields", "message": "No valid fields to update"}), 400

    # Validate plate_type
    if "plate_type" in updates and updates["plate_type"] not in {"standard", "thali", "katori", "side"}:
        return jsonify({"error": "invalid_plate_type"}), 400

    # Validate units
    if "units" in updates and updates["units"] not in {"grams", "oz"}:
        return jsonify({"error": "invalid_units"}), 400

    saved = upsert_profile(g.user_id, updates)
    if saved is None:
        return jsonify({"success": True, "offline": True}), 200

    return jsonify({"success": True, "profile": saved}), 200

"""
Meal log endpoints:
  POST /api/meals/save
  GET  /api/meals/history
  GET  /api/meals/<meal_id>
"""
from flask import Blueprint, request, jsonify, g
from ..utils.auth import require_auth
from ..utils.notifications import maybe_send_nutrition_alerts
from ..db.supabase_client import (
    save_meal_log, get_meal_history, get_meal_by_id,
    get_profile,
)

meals_bp = Blueprint("meals", __name__)


# ── Save a meal ───────────────────────────────────────────────────────────────

@meals_bp.route("/meals/save", methods=["POST"])
@require_auth
def save_meal():
    body = request.get_json(silent=True) or {}

    items = body.get("items", [])
    total = body.get("total", {})
    image_url = body.get("image_url", "")
    logged_at = body.get("logged_at")

    if not items:
        return jsonify({"error": "empty_items", "message": "No food items provided"}), 400

    payload = {
        "user_id": g.user_id,
        "logged_at": logged_at,
        "image_url": image_url,
        "items": items,
        "total_calories": total.get("calories", 0),
        "total_protein_g": total.get("protein_g", 0),
        "total_carbs_g": total.get("carbs_g", 0),
        "total_fat_g": total.get("fat_g", 0),
        "total_fiber_g": total.get("fiber_g", 0),
    }

    saved = save_meal_log(payload)

    # Post-save: aggregate today's nutrition and maybe fire FCM
    _trigger_notification_check(g.user_id, total)

    if saved is None:
        return jsonify({"success": True, "meal_id": None, "offline": True}), 200

    return jsonify({"success": True, "meal_id": saved.get("id")}), 201


def _trigger_notification_check(user_id: str, latest_total: dict):
    """Aggregate today's nutrition and maybe fire a push notification."""
    try:
        from datetime import date
        today = str(date.today())
        history = get_meal_history(user_id, today, today, page=1, page_size=100)
        all_meals = history.get("data", [])
        today_cals    = sum(m.get("total_calories",  0) for m in all_meals)
        today_protein = sum(m.get("total_protein_g", 0) for m in all_meals)
        profile  = get_profile(user_id) or {}
        goal     = float(profile.get("daily_goal_kcal", 2000))
        fcm_tok  = profile.get("fcm_token")
        notif_on = profile.get("notifications_enabled", True)
        today_totals = {"calories": today_cals, "protein_g": today_protein}
        maybe_send_nutrition_alerts(user_id, goal, today_totals, fcm_tok, notif_on)
    except Exception:
        pass  # Never surface notification errors to the client


# ── History ───────────────────────────────────────────────────────────────────

@meals_bp.route("/meals/history", methods=["GET"])
@require_auth
def meal_history():
    start_date = request.args.get("start_date", "2000-01-01")
    end_date = request.args.get("end_date", "2099-12-31")
    
    # Supabase date comparisons on timestamps are exact.
    # An end_date of "YYYY-MM-DD" acts as "YYYY-MM-DD 00:00:00",
    # which cuts off all meals logged that day after midnight.
    if len(end_date) == 10:
        end_date += "T23:59:59.999Z"
        
    page = int(request.args.get("page", 1))
    page_size = min(int(request.args.get("page_size", 20)), 100)

    result = get_meal_history(g.user_id, start_date, end_date, page, page_size)
    return jsonify(result), 200


# ── Single meal detail ────────────────────────────────────────────────────────

@meals_bp.route("/meals/<meal_id>", methods=["GET"])
@require_auth
def meal_detail(meal_id: str):
    meal = get_meal_by_id(meal_id)
    if meal is None:
        return jsonify({"error": "not_found", "message": "Meal not found"}), 404

    # Enforce row-level ownership check at API layer too
    if meal.get("user_id") != g.user_id:
        return jsonify({"error": "forbidden", "message": "Access denied"}), 403

    return jsonify(meal), 200

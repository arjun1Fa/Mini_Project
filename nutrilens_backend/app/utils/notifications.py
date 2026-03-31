"""
Firebase Cloud Messaging helper.
Sends nutritional gap notifications after meal saves.
Runs as a background thread so the API response is not blocked.
"""
import os
import json
import logging
import threading

logger = logging.getLogger(__name__)

_fcm_app = None


def _init_fcm():
    global _fcm_app
    if _fcm_app is not None:
        return _fcm_app
    creds_path = os.getenv("FIREBASE_CREDENTIALS_JSON")
    if not creds_path or not os.path.exists(creds_path):
        logger.warning("Firebase credentials not found — push notifications disabled.")
        return None
    try:
        import firebase_admin
        from firebase_admin import credentials
        cred = credentials.Certificate(creds_path)
        _fcm_app = firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK initialised.")
    except Exception as exc:
        logger.error("Firebase init error: %s", exc)
        _fcm_app = None
    return _fcm_app


def _send_fcm(token: str, title: str, body: str):
    app = _init_fcm()
    if app is None:
        return
    try:
        from firebase_admin import messaging
        msg = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            token=token,
        )
        resp = messaging.send(msg)
        logger.info("FCM sent: %s", resp)
    except Exception as exc:
        logger.error("FCM send error: %s", exc)


def maybe_send_nutrition_alerts(
    user_id: str,
    daily_goal_kcal: float,
    today_totals: dict,
    fcm_token: str | None,
    notifications_enabled: bool,
):
    """
    Check daily nutrition totals against goals and fire FCM if thresholds are met.
    Runs in a daemon thread so it never blocks the API response.
    """
    if not notifications_enabled or not fcm_token:
        return

    def _check():
        from datetime import datetime

        hour = datetime.now().hour
        total_cals = today_totals.get("calories", 0)
        total_protein = today_totals.get("protein_g", 0)
        protein_goal = daily_goal_kcal * 0.30 / 4  # 30% of kcal goal ÷ 4 kcal/g

        # Calorie over-goal: any time of day
        if total_cals > daily_goal_kcal * 1.20:
            _send_fcm(
                fcm_token,
                "🎯 Calorie Goal Reached",
                f"You've hit {int(total_cals)} kcal today — your daily goal is {int(daily_goal_kcal)} kcal.",
            )
            return  # Don't stack notifications

        # Low protein alert: only after 8 PM
        if hour >= 20 and total_protein < protein_goal * 0.70:
            gap = int(protein_goal - total_protein)
            _send_fcm(
                fcm_token,
                "💪 Boost Your Protein",
                f"You're {gap}g short of your protein goal today. "
                "Try dal, paneer, or eggs for dinner.",
            )

    t = threading.Thread(target=_check, daemon=True)
    t.start()

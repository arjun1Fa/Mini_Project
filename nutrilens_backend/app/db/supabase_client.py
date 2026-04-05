"""
Supabase client singleton with error-safe wrappers.
"""
import os
import logging

logger = logging.getLogger(__name__)

_client = None


def get_client():
    global _client
    if _client is not None:
        return _client
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_SERVICE_KEY")
    if not url or not key:
        logger.warning("Supabase env vars not set — DB operations will be skipped.")
        return None
    try:
        from supabase import create_client, Client
        _client = create_client(url, key)
        logger.info("Supabase client initialised.")
    except Exception as exc:
        logger.error("Supabase init error: %s", exc)
        _client = None
    return _client


# ── Nutrition lookup ──────────────────────────────────────────────────────────

def get_nutrition(food_name: str) -> dict | None:
    """Fetch nutrition row for a food class name."""
    client = get_client()
    if client is None:
        return None
    try:
        result = (
            client.table("food_nutrition")
            .select("*")
            .eq("food_name", food_name)
            .limit(1)
            .execute()
        )
        if result.data:
            return result.data[0]
    except Exception as exc:
        logger.error("get_nutrition error: %s", exc)
    return None


def search_food(query: str, limit: int = 20) -> list[dict]:
    """Full-text search across food_name and aliases."""
    client = get_client()
    if client is None:
        return []
    try:
        result = (
            client.table("food_nutrition")
            .select("food_name, aliases, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g")
            .ilike("food_name", f"%{query}%")
            .limit(limit)
            .execute()
        )
        return result.data or []
    except Exception as exc:
        logger.error("search_food error: %s", exc)
        return []


# ── Meal logs ─────────────────────────────────────────────────────────────────

def save_meal_log(payload: dict) -> dict | None:
    client = get_client()
    if client is None:
        return None
    try:
        result = client.table("meal_logs").insert(payload).execute()
        return result.data[0] if result.data else None
    except Exception as exc:
        logger.error("save_meal_log error: %s", exc)
        return None


def get_meal_history(user_id: str, start_date: str, end_date: str, page: int = 1, page_size: int = 20) -> dict:
    client = get_client()
    if client is None:
        return {"data": [], "count": 0}
    try:
        offset = (page - 1) * page_size
        result = (
            client.table("meal_logs")
            .select("id, logged_at, image_url, total_calories, total_protein_g, total_carbs_g, total_fat_g, total_fiber_g, items", count="exact")
            .eq("user_id", user_id)
            .gte("logged_at", start_date)
            .lte("logged_at", end_date)
            .order("logged_at", desc=True)
            .range(offset, offset + page_size - 1)
            .execute()
        )
        return {"data": result.data or [], "count": result.count or 0}
    except Exception as exc:
        logger.error("get_meal_history error: %s", exc)
        return {"data": [], "count": 0}


def get_meal_by_id(meal_id: str) -> dict | None:
    client = get_client()
    if client is None:
        return None
    try:
        result = (
            client.table("meal_logs")
            .select("*")
            .eq("id", meal_id)
            .limit(1)
            .execute()
        )
        return result.data[0] if result.data else None
    except Exception as exc:
        logger.error("get_meal_by_id error: %s", exc)
        return None


# ── User profile ──────────────────────────────────────────────────────────────

AUTH_META_FIELDS = {"age", "gender", "height_cm", "weight_kg", "activity_level", "goal"}

def get_profile(user_id: str) -> dict | None:
    client = get_client()
    if client is None:
        return None
    try:
        result = (
            client.table("users")
            .select("*")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        profile_data = result.data[0] if result.data else {}

        # Merge in the metadata fields from auth API
        try:
            user_auth = client.auth.admin.get_user_by_id(user_id)
            meta = getattr(user_auth.user, "user_metadata", {}) or {}
            for k in AUTH_META_FIELDS:
                if k in meta:
                    profile_data[k] = meta[k]
        except Exception as e:
            logger.error("get_profile auth admin error: %s", e)

        return profile_data if profile_data else None
    except Exception as exc:
        logger.error("get_profile error: %s", exc)
        return None


def upsert_profile(user_id: str, fields: dict) -> dict | None:
    client = get_client()
    if client is None:
        return None
    try:
        db_fields = {k: v for k, v in fields.items() if k not in AUTH_META_FIELDS}
        meta_fields = {k: v for k, v in fields.items() if k in AUTH_META_FIELDS}

        # DB updates
        db_fields["id"] = user_id
        result = client.table("users").upsert(db_fields).execute()
        saved_data = result.data[0] if result.data else db_fields.copy()

        # Auth metadata updates
        if meta_fields:
            try:
                user_auth = client.auth.admin.get_user_by_id(user_id)
                current_meta = getattr(user_auth.user, "user_metadata", {}) or {}
                current_meta.update(meta_fields)
                client.auth.admin.update_user_by_id(user_id, {"user_metadata": current_meta})
                
                # Merge into the result dict so client sees the saved fields
                for k, v in meta_fields.items():
                    saved_data[k] = v
            except Exception as e:
                logger.error("upsert_profile auth admin error: %s", e)

        return saved_data
    except Exception as exc:
        logger.error("upsert_profile error: %s", exc)
        return None

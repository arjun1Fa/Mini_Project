"""
Groq Vision API handler for NutriVision.
Uses Llama 4 Scout (vision-capable) via Groq's free API.
Replaces the YOLO + Depth pipeline when USE_YOLO=False.
"""
import os
import base64
import json
import logging
import re
import io

from PIL import Image

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """You are a professional nutritionist and Indian food expert with 20 years of experience.
Analyze the food image and identify every distinct food item visible on the plate or in the bowl.

For each food item:
1. Identify the exact food name (use common Indian food names).
2. Estimate the weight in grams based on the portion size you can see.

Rules:
- Use snake_case for food names (e.g., rice_cooked, sambar, chapathi, aviyal, kadala_curry, dal).
- Be specific: don't say "curry" — say "chicken_curry" or "vegetable_curry".
- Estimate weights realistically: a standard serving of rice is 150-200g, a bowl of dal is 100-150g.
- Include ALL visible food items, even small sides like papad or pickle.
- Return ONLY a valid JSON array. No explanation, no markdown, no code block — just raw JSON.

Example output:
[{"food_name": "rice_cooked", "weight_g": 180, "confidence": 0.95}, {"food_name": "sambar", "weight_g": 120, "confidence": 0.90}]"""


def analyze_with_gemini(image_rgb) -> list[dict]:
    """
    Send image to Llama 4 Scout via Groq API for food identification.
    Function kept named 'analyze_with_gemini' to avoid changing analyze.py imports.
    """
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key:
        logger.error("GROQ_API_KEY is not set in .env")
        return _fallback_response()

    try:
        from openai import OpenAI

        # Compress to handle any base64 limits
        pil_image = Image.fromarray(image_rgb)
        pil_image.thumbnail((1024, 1024))
        
        img_byte_arr = io.BytesIO()
        pil_image.save(img_byte_arr, format='JPEG', quality=85)
        base64_image = base64.b64encode(img_byte_arr.getvalue()).decode('utf-8')

        # Groq uses OpenAI-compatible API
        client = OpenAI(
            base_url="https://api.groq.com/openai/v1",
            api_key=api_key
        )

        response = client.chat.completions.create(
            model="meta-llama/llama-4-scout-17b-16e-instruct",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": SYSTEM_PROMPT},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}",
                            },
                        },
                    ],
                }
            ],
            temperature=0.1,
            max_tokens=1024,
        )

        raw_text = response.choices[0].message.content.strip()
        logger.info("Groq Vision raw response: %s", raw_text)
        return _parse_response(raw_text)

    except Exception as exc:
        logger.error("Groq Vision API call failed: %s", exc, exc_info=True)
        return _fallback_response()


def _parse_response(raw_text: str) -> list[dict]:
    """Robustly parse the JSON response."""
    cleaned = re.sub(r"```[A-Za-z_-]*", "", raw_text).strip().rstrip("`").strip()

    try:
        data = json.loads(cleaned)
        if not isinstance(data, list):
            raise ValueError("Expected a JSON array")

        result = []
        for item in data:
            food_name = str(item.get("food_name", "unknown")).lower().replace(" ", "_")
            weight_g = float(item.get("weight_g", 100.0))
            confidence = float(item.get("confidence", 0.85))

            weight_g = max(10.0, min(weight_g, 1000.0))
            confidence = max(0.0, min(confidence, 1.0))

            result.append({
                "food_name": food_name,
                "weight_g": weight_g,
                "confidence": confidence,
            })

        return result if result else _fallback_response()

    except (json.JSONDecodeError, ValueError) as exc:
        logger.error("Failed to parse Groq response: %s | Raw: %s", exc, raw_text)
        return _fallback_response()


def _fallback_response() -> list[dict]:
    logger.warning("Using fallback food response — Vision API call failed.")
    return [{"food_name": "rice_cooked", "weight_g": 150.0, "confidence": 0.50}]

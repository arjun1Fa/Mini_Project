# NutriLens — Indian Food Nutrition Analyzer

AI-powered meal analysis app for Indian cuisine.  
Photograph a meal → instant per-item nutritional breakdown.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Quick Start (Local)](#quick-start-local)
3. [Environment Variables](#environment-variables)
4. [Supabase Setup](#supabase-setup)
5. [API Reference](#api-reference)
6. [ML Models](#ml-models)
7. [Cloud Run Deployment](#cloud-run-deployment)
8. [Flutter Integration Notes](#flutter-integration-notes)

---

## Architecture Overview

```
Flutter App
  ├── On-device: EfficientNetB0 (TFLite) — food class prediction
  └── Backend call: POST /api/analyze
        │
        ▼
Flask Backend (Cloud Run)
  ├── Image quality gate (OpenCV Laplacian)
  ├── YOLOv8-seg → segmentation masks + plate detection
  ├── Depth Anything V2 Small → relative height estimation
  ├── Geometric volume calculator → weight_g per item
  └── Supabase food_nutrition → scaled macro/micro values
        │
        ▼
Supabase (PostgreSQL)
  ├── food_nutrition  — 60 Indian food classes, IFCT 2017 values
  ├── meal_logs       — per-user meal history with full JSON
  └── users           — profile, goals, FCM token
```

---

## Quick Start (Local)

```bash
# 1. Clone and enter backend directory
cd nutrilens_backend

# 2. Create virtual environment
python3.11 -m venv .venv
source .venv/bin/activate

# 3. Install CPU-only PyTorch (faster install for dev)
pip install torch==2.3.0+cpu torchvision==0.18.0+cpu \
    --index-url https://download.pytorch.org/whl/cpu

# 4. Install remaining dependencies
pip install -r requirements.txt

# 5. Copy and fill environment variables
cp .env.example .env
# Edit .env with your Supabase URL, service key, and JWT secret

# 6. Run the dev server
python wsgi.py
# → http://localhost:8080
```

The backend starts fully without model files.  
If `yolov8_indian_food_seg.pt` or `depth_anything_v2_small.pth` are absent,
mock detections and heuristic depth are used automatically.

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `SUPABASE_URL` | Yes | e.g. `https://xxxx.supabase.co` |
| `SUPABASE_SERVICE_KEY` | Yes | `service_role` key from Dashboard → Settings → API |
| `SUPABASE_JWT_SECRET` | Yes | From Dashboard → Settings → API → JWT Secret |
| `FIREBASE_CREDENTIALS_JSON` | No | Path to Firebase service account JSON for FCM |
| `MODEL_DIR` | No | Directory containing `.pt` / `.pth` model files (default `./models`) |
| `BLUR_THRESHOLD` | No | Laplacian variance below which image is rejected (default `100`) |
| `BRIGHTNESS_THRESHOLD` | No | Mean V-channel brightness below which image is rejected (default `50`) |
| `MAX_IMAGE_SIZE_MB` | No | Upload limit in MB (default `10`) |

---

## Supabase Setup

1. Create a new Supabase project at https://supabase.com
2. Go to **SQL Editor** and run the entire contents of `supabase_schema.sql`  
   This creates all tables, RLS policies, triggers, indexes, and seeds 60 food rows.
3. Go to **Storage** → **New Bucket**  
   Name: `meal-images`, Public: **off**
4. Set Storage RLS so authenticated users can read/write only their own folder:
   ```sql
   -- In SQL Editor:
   create policy "meal_images_own_folder" on storage.objects
     for all using (
       bucket_id = 'meal-images'
       and auth.uid()::text = (storage.foldername(name))[1]
     );
   ```

---

## API Reference

All endpoints except `/health` require:  
`Authorization: Bearer <supabase_jwt>`

### POST `/api/analyze`

Analyse a meal photo. Full ML pipeline.

**Request:** `multipart/form-data`

| Field | Type | Required | Description |
|---|---|---|---|
| `image` | file | Yes | JPEG or PNG, max 10 MB |
| `plate_type` | string | No | `standard` / `thali` / `katori` / `side` (default `standard`) |
| `food_predictions` | JSON string | No | `[{"class_name":"rice_cooked","confidence":0.92}]` from on-device TFLite |

**Response 200:**
```json
{
  "items": [
    {
      "food_name": "Rice Cooked",
      "food_key": "rice_cooked",
      "confidence": 0.921,
      "weight_g": 185.3,
      "bounding_box": { "x": 120, "y": 90, "w": 210, "h": 195 },
      "segmentation_mask_b64": "<base64 PNG>",
      "nutrition": {
        "calories": 240.9,
        "protein_g": 5.0,
        "carbs_g": 52.2,
        "fat_g": 0.6,
        "fiber_g": 0.7,
        "sodium_mg": 1.9,
        "calcium_mg": 5.6,
        "iron_mg": 0.4
      }
    }
  ],
  "total": {
    "calories": 620.4,
    "protein_g": 22.1,
    "carbs_g": 88.3,
    "fat_g": 14.2,
    "fiber_g": 8.5,
    "sodium_mg": 42.0,
    "calcium_mg": 195.0,
    "iron_mg": 5.2
  },
  "plate_pixel_per_cm": 18.432,
  "processing_time_ms": 1240
}
```

**Error responses:**

| Code | `error` field | Meaning |
|---|---|---|
| 400 | `missing_image` | No image in request |
| 422 | `image_too_blurry` | Laplacian variance < threshold |
| 422 | `image_too_dark` | Mean brightness < threshold |

---

### POST `/api/meals/save`

Save a meal log entry.

**Request body (JSON):**
```json
{
  "items": [ ... ],
  "total": { "calories": 620, "protein_g": 22, "carbs_g": 88, "fat_g": 14, "fiber_g": 8 },
  "image_url": "meal-images/user-id/2024-01-15T14:30:00Z.jpg",
  "logged_at": "2024-01-15T14:30:00Z"
}
```

**Response 201:** `{ "success": true, "meal_id": "uuid" }`

---

### GET `/api/meals/history`

Paginated meal history.

**Query params:** `start_date`, `end_date` (ISO date, e.g. `2024-01-01`), `page`, `page_size`

**Response 200:** `{ "data": [...], "count": 42 }`

---

### GET `/api/meals/<meal_id>`

Full detail for a single meal.

---

### PUT `/api/profile`

Update user settings.

**Request body (JSON):** Any subset of:
```json
{
  "full_name": "Priya Sharma",
  "daily_goal_kcal": 1800,
  "plate_type": "thali",
  "units": "grams"
}
```

---

### GET `/api/food/search?q=<query>`

Search food database. Used by the correction modal.

**Response 200:** `{ "results": [{ "food_name": "...", "calories_per_100g": 130, ... }] }`

---

## ML Models

### YOLOv8-seg (server-side)

- **Base:** `yolov8n-seg.pt` (nano, 3.4M params)
- **Classes:** 60 Indian food classes + 4 plate/bowl classes (64 total)
- **Training dataset:** IndianFoodNet + custom thali images
- **Input size:** 640 × 640
- **Training config:**
  ```yaml
  epochs: 100
  batch: 16
  optimizer: AdamW
  lr0: 0.001
  augment: true   # mosaic, flips, HSV shifts, scale jitter
  ```
- **Export for deployment:**
  ```python
  from ultralytics import YOLO
  model = YOLO("yolov8n-seg.pt")
  # Fine-tune on your dataset, then:
  model.save("models/yolov8_indian_food_seg.pt")
  ```
- **Place at:** `models/yolov8_indian_food_seg.pt`

### EfficientNetB0 (on-device Flutter)

- **Base:** `efficientnet_b0` pretrained on ImageNet
- **Training:**
  ```python
  import torch
  import torchvision.models as models

  model = models.efficientnet_b0(weights="IMAGENET1K_V1")
  # Unfreeze last 3 blocks
  for param in list(model.parameters())[:-30]:
      param.requires_grad = False
  # Replace classifier head
  model.classifier[1] = torch.nn.Linear(1280, 60)
  # Train: 50 epochs, Adam lr=0.001, cosine decay, label_smoothing=0.1
  ```
- **Export to TFLite:**
  ```python
  import tensorflow as tf
  # Convert via ONNX → TF → TFLite (float16 quantized)
  # Or use ai_edge_torch if using PyTorch directly
  converter = tf.lite.TFLiteConverter.from_saved_model("saved_model")
  converter.optimizations = [tf.lite.Optimize.DEFAULT]
  converter.target_spec.supported_types = [tf.float16]
  tflite_model = converter.convert()
  with open("assets/models/efficientnet_b0_indian_food.tflite", "wb") as f:
      f.write(tflite_model)
  ```
- **Labels file:** `assets/models/labels.txt` — one class name per line, matching training order

### Depth Anything V2 Small (server-side)

- **Weights:** Download from https://huggingface.co/depth-anything/Depth-Anything-V2-Small
  ```bash
  wget https://huggingface.co/depth-anything/Depth-Anything-V2-Small/resolve/main/depth_anything_v2_vits.pth \
    -O models/depth_anything_v2_small.pth
  ```
- **Install:**
  ```bash
  git clone https://github.com/DepthAnything/Depth-Anything-V2
  pip install -e Depth-Anything-V2
  ```
- **No fine-tuning required.** Used pretrained as-is.

---

## Cloud Run Deployment

### Prerequisites

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud services enable run.googleapis.com cloudbuild.googleapis.com
```

### Store secrets in Secret Manager

```bash
echo -n "https://xxxx.supabase.co" | \
  gcloud secrets create nutrilens-supabase-url --data-file=-

echo -n "eyJhbGci..." | \
  gcloud secrets create nutrilens-supabase-key --data-file=-

echo -n "your-jwt-secret" | \
  gcloud secrets create nutrilens-jwt-secret --data-file=-
```

### Trigger a deployment

```bash
gcloud builds submit --config cloudbuild.yaml .
```

The service will be available at:  
`https://nutrilens-backend-<hash>-as.a.run.app`

### Add model files (two options)

**Option A — Bake into image (simple, larger image):**  
Place `.pt` and `.pth` files in `models/` before running `gcloud builds submit`.

**Option B — Cloud Storage mount (recommended for large files):**
```bash
gsutil cp models/*.pt gs://YOUR_BUCKET/nutrilens-models/
gsutil cp models/*.pth gs://YOUR_BUCKET/nutrilens-models/
```
Then add a Cloud Run volume mount in `cloudbuild.yaml` or via the Console under  
**Edit & Deploy New Revision → Volumes**.

---

## Flutter Integration Notes

### API service setup (Dio)

```dart
// lib/services/api_service.dart
class ApiService {
  static const _base = 'https://YOUR_CLOUD_RUN_URL';

  final _dio = Dio(BaseOptions(baseUrl: _base))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final jwt = await SharedPreferences.getInstance()
            .then((p) => p.getString('jwt'));
        if (jwt != null) {
          options.headers['Authorization'] = 'Bearer $jwt';
        }
        handler.next(options);
      },
    ));

  Future<Map<String, dynamic>> analyze({
    required File imageFile,
    required String plateType,
    List<Map<String, dynamic>> foodPredictions = const [],
  }) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
      'plate_type': plateType,
      'food_predictions': jsonEncode(foodPredictions),
    });
    final resp = await _dio.post('/api/analyze', data: form);
    return resp.data as Map<String, dynamic>;
  }
}
```

### Portion adjuster scaling

The backend returns absolute `weight_g` values.  
Apply the multiplier client-side:

```dart
const multipliers = {
  'Small': 0.75, 'Medium': 1.0, 'Large': 1.25, 'XL': 1.5
};

double scaledCalories(FoodItem item, String portion) =>
    item.nutrition.calories * multipliers[portion]!;
```

### Offline fallback portion weights

```dart
const standardPortionGrams = {
  'rice_cooked':  150.0,
  'roti_chapati':  40.0,
  'dal_tadka':    100.0,
  'sabzi':         80.0,
  'idli':         100.0,  // 2 pieces
  'dosa':          90.0,
  'sambar':        80.0,
  'paneer':        60.0,
};
```

---

## Project Structure

```
nutrilens_backend/
├── wsgi.py                        # Gunicorn entry point
├── Dockerfile
├── cloudbuild.yaml
├── requirements.txt
├── .env.example
├── supabase_schema.sql            # Full schema + seed data
├── models/                        # Drop model files here
│   ├── yolov8_indian_food_seg.pt
│   └── depth_anything_v2_small.pth
└── app/
    ├── __init__.py                # Flask app factory
    ├── routes/
    │   ├── analyze.py             # POST /api/analyze
    │   ├── meals.py               # Meal log CRUD
    │   ├── food.py                # Food search
    │   └── profile.py             # User profile
    ├── ml/
    │   ├── yolo_handler.py        # YOLOv8-seg inference
    │   ├── depth_handler.py       # Depth Anything V2
    │   ├── volume_calculator.py   # Geometric shape formulas
    │   └── shape_density_table.py # 60-class lookup table
    ├── db/
    │   └── supabase_client.py     # All DB operations
    └── utils/
        ├── image_quality.py       # Blur + brightness checks
        ├── nutrition_calculator.py # Scaling + IFCT fallback
        ├── auth.py                # JWT Bearer middleware
        └── notifications.py       # FCM push notifications
```

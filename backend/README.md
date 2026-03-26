# NutriVision AI Backend

This is the Python Flask REST API backend for the **NutriVision** Indian Food Nutrition Analyzer app. It integrates YOLOv8 and PyTorch CNN implementations alongside Supabase authentication and PostgreSQL.

## 📁 Architecture
- `app.py`: Flask Entry point and configuration.
- `config.py`: Essential environment variable connections.
- `models/`: Contains the SQLAlchemy DB layer connecting to Supabase Postgres.
- `routes/`: Blueprint API controllers (Analysis & User History).
- `services/`: The core AI Vision Logic (`ai_service.py`) and standard Nutrition calculations (`nutrition_service.py`).
- `utils/`: Includes the securely parsed PyJWT Auth token middleware (`auth.py`).

## ⚙️ Setup Instructions

### 1. Install Dependencies
Make sure you have Python 3.9+ installed.
```bash
cd backend
python -m venv venv
# Windows:
env\Scripts\activate
# MacOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
```

### 2. Configure Environment Variables
Create a `.env` file in the `backend/` directory holding your Supabase setup:
```env
# Find this in Supabase Project Settings -> Database -> Connection String (URI)
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# Find this in Supabase Project Settings -> API -> JWT Secret
SUPABASE_JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long
```

### 3. Run the Server
Ensure you're inside the virtual environment:
```bash
python app.py
```
The server will boot up and host the endpoints at `http://127.0.0.1:5000`.

---

## 🔗 Endpoint Integration with Flutter (Dart)

### The API Connection Context
To communicate properly, the frontend must assemble the image via the `http.MultipartRequest` format while passing the valid JWT Authorization.

Below is exactly how you can implement this in your `lib/screens/add_food_screen.dart` (or `image_preview_screen.dart`) API layer:

```dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> analyzeFoodImage(String imagePath, String supabaseJwtToken) async {
  final url = Uri.parse('http://10.0.2.2:5000/analyze'); // Use 10.0.2.2 for Android Emulator, or your local machine IP for iOS/Real devices

  try {
    var request = http.MultipartRequest('POST', url);
    
    // Add Authorization Headers
    request.headers['Authorization'] = 'Bearer $supabaseJwtToken';
    
    // Attach the Image File
    var file = await http.MultipartFile.fromPath('image', imagePath);
    request.files.add(file);
    
    // Dispatch
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      // Nutrition JSON is structured as per backend spec
      return json.decode(responseData);
    } else {
      print('Failed Analysis: \${response.statusCode} | \$responseData');
      return null;
    }
  } catch (e) {
    print('Network Exception: \$e');
    return null;
  }
}
```

### Validating with cURL
You can also validate the endpoint instantly from the terminal assuming you possess an image inside `backend/uploads/`:
```bash
curl -X POST http://127.0.0.1:5000/analyze \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_HERE" \
  -F "image=@uploads/test_meal.jpg"
```

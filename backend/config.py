import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Supabase PostgreSQL connection string
    # e.g. postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'postgresql://postgres:password@localhost/nutrivision')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Supabase JWT Secret for Decoding the user tokens from Flutter
    SUPABASE_JWT_SECRET = os.getenv('SUPABASE_JWT_SECRET', 'your-super-secret-jwt-token-with-at-least-32-characters-long')
    
    # Upload folder for temporary image saving
    UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'uploads')
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16 MB limit

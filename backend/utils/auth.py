from functools import wraps
from flask import request, jsonify
import jwt
from ..config import Config

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        if 'Authorization' in request.headers:
            parts = request.headers['Authorization'].split()
            if len(parts) == 2 and parts[0].lower() == 'bearer':
                token = parts[1]
                
        if not token:
            return jsonify({'message': 'Token is missing or invalid format!'}), 401
            
        try:
            # Supabase signs JWTs with the HS256 algorithm and the project JWT secret
            data = jwt.decode(
                token, 
                Config.SUPABASE_JWT_SECRET, 
                algorithms=["HS256"], 
                options={"verify_aud": False}
            )
            current_user_id = data.get('sub') # Subject usually contains the user UUID
            if not current_user_id:
                raise Exception("Token missing 'sub' claim")
        except jwt.ExpiredSignatureError:
            return jsonify({'message': 'Token has expired!'}), 401
        except Exception as e:
            return jsonify({'message': f'Token is invalid! {str(e)}'}), 401
            
        return f(current_user_id, *args, **kwargs)
        
    return decorated

from datetime import datetime
import json
from .db import db

class FoodLog(db.Model):
    __tablename__ = 'food_logs'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.String(255), nullable=False, index=True)
    food_name = db.Column(db.String(255), nullable=False)
    weight_g = db.Column(db.Float, nullable=False)
    calories = db.Column(db.Float, nullable=False)
    protein = db.Column(db.Float, nullable=False)
    carbs = db.Column(db.Float, nullable=False)
    fat = db.Column(db.Float, nullable=False)
    image_path = db.Column(db.String(512), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'food_name': self.food_name,
            'weight_g': round(self.weight_g, 2),
            'calories': round(self.calories, 2),
            'protein': round(self.protein, 2),
            'carbs': round(self.carbs, 2),
            'fat': round(self.fat, 2),
            'image_path': self.image_path,
            'created_at': self.created_at.isoformat()
        }

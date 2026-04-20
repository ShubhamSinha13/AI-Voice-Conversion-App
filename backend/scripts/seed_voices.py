#!/usr/bin/env python3
"""
Seed predefined voices into database
"""
import asyncio
from app.database import SessionLocal
from app.models import Voice

PREDEFINED_VOICES = [
    # Female Voices
    {"name": "Female Voice 1", "type": "predefined", "category": "female", "accuracy_percentage": 99, "sample_count": 4, "is_predefined": True},
    {"name": "Female Voice 2", "type": "predefined", "category": "female", "accuracy_percentage": 99, "sample_count": 4, "is_predefined": True},
    {"name": "Female Voice 3", "type": "predefined", "category": "female", "accuracy_percentage": 99, "sample_count": 4, "is_predefined": True},
    {"name": "Female Voice 4", "type": "predefined", "category": "female", "accuracy_percentage": 99, "sample_count": 4, "is_predefined": True},
    
    # Male Voices
    {"name": "Men Voice 1", "type": "predefined", "category": "men", "accuracy_percentage": 99, "sample_count": 4, "is_predefined": True},
    {"name": "Men Voice 2", "type": "predefined", "category": "men", "accuracy_percentage": 99, "sample_count": 4, "is_predefined": True},
    {"name": "Men Voice 3", "type": "predefined", "category": "men", "accuracy_percentage": 99, "sample_count": 4, "is_predefined": True},
    {"name": "Men Voice 4", "type": "predefined", "category": "men", "accuracy_percentage": 99, "sample_count": 4, "is_predefined": True},
    
    # Special Voices
    {"name": "Robotic Voice", "type": "predefined", "category": "special", "accuracy_percentage": 99, "sample_count": 4, "is_predefined": True},
    {"name": "Whisper Voice", "type": "predefined", "category": "special", "accuracy_percentage": 99, "sample_count": 4, "is_predefined": True},
    {"name": "Cartoon Voice", "type": "predefined", "category": "special", "accuracy_percentage": 99, "sample_count": 4, "is_predefined": True},
    {"name": "Elder Voice", "type": "predefined", "category": "special", "accuracy_percentage": 99, "sample_count": 4, "is_predefined": True},
]

def seed_voices():
    """Seed predefined voices into database"""
    db = SessionLocal()
    
    try:
        # Check if voices already exist
        existing_count = db.query(Voice).filter(Voice.is_predefined == True).count()
        
        if existing_count == 0:
            print("🌱 Seeding predefined voices...")
            
            for voice_data in PREDEFINED_VOICES:
                voice = Voice(**voice_data)
                db.add(voice)
                print(f"  ✅ Added: {voice_data['name']}")
            
            db.commit()
            print(f"\n✅ Successfully seeded {len(PREDEFINED_VOICES)} predefined voices!")
        else:
            print(f"ℹ️  Predefined voices already exist ({existing_count} found)")
    
    except Exception as e:
        db.rollback()
        print(f"❌ Error seeding voices: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_voices()

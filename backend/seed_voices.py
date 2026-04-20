"""
Seed script to populate predefined voices in the database.
This creates 12 diverse predefined voices for demo purposes.
"""

from app.database import SessionLocal, engine
from app.models import Base, Voice, User
from sqlalchemy.orm import Session
from datetime import datetime

# Create tables if they don't exist
Base.metadata.create_all(bind=engine)

def seed_predefined_voices():
    """Seed the database with 12 predefined voices."""
    db = SessionLocal()
    
    try:
        # Check if we already have predefined voices
        existing = db.query(Voice).filter(Voice.is_predefined == True).count()
        if existing > 0:
            print(f"✓ Database already has {existing} predefined voices. Skipping seed.")
            return
        
        # Create or get system user for predefined voices
        system_user = db.query(User).filter(User.email == "system@voiceconverter.com").first()
        if not system_user:
            system_user = User(
                email="system@voiceconverter.com",
                password_hash="SYSTEM",  # Dummy hash
                username="system_voice_provider"
            )
            db.add(system_user)
            db.commit()
            print("✓ Created system user for predefined voices")
        
        # Define 12 predefined voices
        predefined_voices = [
            {
                "name": "Alex - Professional Male",
                "type": "male",
                "category": "professional",
                "accuracy_percentage": 95.5,
                "sample_count": 500,
            },
            {
                "name": "Emma - Friendly Female",
                "type": "female",
                "category": "friendly",
                "accuracy_percentage": 94.2,
                "sample_count": 450,
            },
            {
                "name": "James - Deep Male",
                "type": "male",
                "category": "deep",
                "accuracy_percentage": 93.8,
                "sample_count": 480,
            },
            {
                "name": "Sophia - Soft Female",
                "type": "female",
                "category": "soft",
                "accuracy_percentage": 96.1,
                "sample_count": 520,
            },
            {
                "name": "Marco - Italian Accent Male",
                "type": "male",
                "category": "accented",
                "accuracy_percentage": 92.3,
                "sample_count": 400,
            },
            {
                "name": "Claire - French Accent Female",
                "type": "female",
                "category": "accented",
                "accuracy_percentage": 91.7,
                "sample_count": 380,
            },
            {
                "name": "Raj - Indian Accent Male",
                "type": "male",
                "category": "accented",
                "accuracy_percentage": 90.5,
                "sample_count": 350,
            },
            {
                "name": "Yuki - Japanese Accent Female",
                "type": "female",
                "category": "accented",
                "accuracy_percentage": 89.9,
                "sample_count": 340,
            },
            {
                "name": "Liam - Irish Male",
                "type": "male",
                "category": "regional",
                "accuracy_percentage": 93.4,
                "sample_count": 420,
            },
            {
                "name": "Ava - American Female",
                "type": "female",
                "category": "regional",
                "accuracy_percentage": 95.8,
                "sample_count": 510,
            },
            {
                "name": "Miguel - Spanish Male",
                "type": "male",
                "category": "regional",
                "accuracy_percentage": 92.1,
                "sample_count": 390,
            },
            {
                "name": "Luna - Child Voice Female",
                "type": "female",
                "category": "special",
                "accuracy_percentage": 88.6,
                "sample_count": 300,
            },
        ]
        
        # Insert voices
        for voice_data in predefined_voices:
            voice = Voice(
                user_id=system_user.id,
                name=voice_data["name"],
                type=voice_data["type"],
                category=voice_data["category"],
                speaker_embedding=None,  # Will be computed during voice conversion
                accuracy_percentage=voice_data["accuracy_percentage"],
                sample_count=voice_data["sample_count"],
                is_predefined=True,
            )
            db.add(voice)
        
        db.commit()
        print(f"✓ Successfully seeded {len(predefined_voices)} predefined voices!")
        print("\nVoices created:")
        for voice_data in predefined_voices:
            print(f"  • {voice_data['name']} ({voice_data['category']})")
        
    except Exception as e:
        db.rollback()
        print(f"✗ Error seeding voices: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    seed_predefined_voices()

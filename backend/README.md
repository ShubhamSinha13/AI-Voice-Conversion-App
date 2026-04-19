# Backend Setup Instructions

## Prerequisites
- Python 3.10+
- PostgreSQL 12+
- pip or conda

## Installation

### 1. Create Virtual Environment
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Configure Environment Variables
```bash
cp .env.example .env
# Edit .env with your database credentials and settings
```

### 4. Set up PostgreSQL Database
```sql
CREATE DATABASE voice_converter_db;
```

### 5. Run Database Migrations
```bash
# Alembic will be added for migrations
# For now, tables are created automatically by SQLAlchemy
python
>>> from app.database import engine, Base
>>> from app.models import User, Voice, CallSession
>>> Base.metadata.create_all(bind=engine)
```

### 6. Start the Server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Server will be available at `http://localhost:8000`
API docs available at `http://localhost:8000/docs`

## API Endpoints

### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login and get token

### Voices
- `GET /api/voices/predefined` - Get predefined voices
- `GET /api/voices/my-voices` - Get user's custom voices
- `POST /api/voices/create` - Create new custom voice
- `POST /api/voices/{voice_id}/add-sample` - Add sample to voice
- `GET /api/voices/{voice_id}` - Get voice details
- `DELETE /api/voices/{voice_id}` - Delete voice

## Database Schema

### Users Table
- id (Primary Key)
- email (Unique)
- password_hash
- username (Unique)
- created_at, updated_at

### Voices Table
- id (Primary Key)
- user_id (Foreign Key)
- name, type, category
- speaker_embedding
- model_path
- sample_count, accuracy_percentage
- is_predefined, created_at

### Call Sessions Table
- id (Primary Key)
- user_id, voice_id (Foreign Keys)
- call_type, duration
- voice_accuracy, created_at

## ML Models Setup

Required models (to be downloaded):
- RVC (Retrieval-based Voice Conversion)
- HuBERT (for speaker embedding)
- HiFi-GAN (neural vocoder)

Models will be placed in `./ml_models/` directory.

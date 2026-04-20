# PostgreSQL Setup Guide

## Prerequisites
- PostgreSQL 12+ installed
- Python 3.10+ with venv
- FastAPI backend running

## Quick Setup

### 1. Install PostgreSQL

**Windows:**
```powershell
# Download from https://www.postgresql.org/download/windows/
# Or use Chocolatey
choco install postgresql
```

**macOS:**
```bash
brew install postgresql
```

**Linux (Ubuntu):**
```bash
sudo apt-get install postgresql postgresql-contrib
```

### 2. Create Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE voice_converter_db;

# Create user
CREATE USER voice_user WITH PASSWORD 'your_secure_password';

# Grant privileges
ALTER ROLE voice_user SET client_encoding TO 'utf8';
ALTER ROLE voice_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE voice_user SET default_transaction_deferrable TO off;
ALTER ROLE voice_user SET default_transaction_read_only TO off;
ALTER ROLE voice_user SET timezone TO 'UTC';

GRANT ALL PRIVILEGES ON DATABASE voice_converter_db TO voice_user;

# Exit psql
\q
```

### 3. Configure Backend

**Create `.env` file:**
```env
# Database
DATABASE_URL=postgresql://voice_user:your_secure_password@localhost:5432/voice_converter_db

# JWT
SECRET_KEY=your_super_secret_key_change_this_in_production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# ML Models Path
ML_MODELS_PATH=./ml_models

# Audio Processing
SAMPLE_RATE=44100
CHUNK_SIZE=4096
```

### 4. Run Migrations

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

pip install -r requirements.txt

# Run migrations (Alembic)
alembic upgrade head

# Or manually create tables
python -c "from app.models import Base; from app.database import engine; Base.metadata.create_all(engine)"
```

### 5. Seed Predefined Voices

```bash
python scripts/seed_voices.py
```

### 6. Start Backend Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 7. Test Connection

```bash
curl http://localhost:8000/health
```

Expected response:
```json
{"status": "healthy"}
```

---

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Voices Table
```sql
CREATE TABLE voices (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'predefined' or 'custom'
    category VARCHAR(100),
    speaker_embedding BYTEA,
    accuracy_percentage FLOAT DEFAULT 0,
    sample_count INTEGER DEFAULT 0,
    is_predefined BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Call Sessions Table
```sql
CREATE TABLE call_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    voice_id INTEGER REFERENCES voices(id) ON DELETE SET NULL,
    duration INTEGER,
    accuracy FLOAT,
    call_type VARCHAR(50), -- 'video', 'audio', 'presentation'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Troubleshooting

### Connection refused
```bash
# Check PostgreSQL service is running
psql -U postgres -c "SELECT version();"

# On Windows
net start postgresql-x64-15

# On macOS
brew services start postgresql

# On Linux
sudo service postgresql start
```

### Database creation failed
```bash
# Drop and recreate
dropdb voice_converter_db
createdb -U postgres voice_converter_db
```

### Permission denied
```bash
# Reconnect with correct user
psql -U voice_user -d voice_converter_db
```

---

## Testing the API

### 1. Register User
```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpass123",
    "username": "testuser"
  }'
```

### 2. Login
```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpass123"
  }'
```

### 3. Get Predefined Voices
```bash
curl http://localhost:8000/api/voices/predefined
```

### 4. Create Custom Voice
```bash
curl -X POST http://localhost:8000/api/voices/create \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Voice",
    "user_defined_name": "Professional Voice"
  }'
```

---

## Backup & Recovery

### Backup Database
```bash
pg_dump -U voice_user voice_converter_db > backup.sql
```

### Restore Database
```bash
psql -U voice_user voice_converter_db < backup.sql
```

---

## Performance Tips

1. **Create indexes** on frequently queried columns:
```sql
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_voices_user_id ON voices(user_id);
CREATE INDEX idx_call_sessions_user_id ON call_sessions(user_id);
```

2. **Enable connection pooling** - Use PgBouncer:
```bash
brew install pgbouncer
```

3. **Monitor queries** - Enable query logging:
```sql
ALTER SYSTEM SET log_min_duration_statement = 1000;
```

---

## Next Steps

1. Start PostgreSQL service
2. Create database and user
3. Configure `.env` file
4. Run backend server
5. Test API endpoints
6. Proceed to ML model integration

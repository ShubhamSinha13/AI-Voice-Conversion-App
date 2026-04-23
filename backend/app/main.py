"""
Main FastAPI application
"""

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from app.database import engine, Base, get_db
from app.models import User, Voice
from app.schemas import UserCreate, UserLogin, UserResponse, Token
from app.utils.auth import hash_password, verify_password, create_access_token
from app.api.voices import router as voices_router
from app.api.voice_samples import router as voice_samples_router
from app.api.voice_conversion import router as voice_conversion_router
from app.api.voice_preview import router as voice_preview_router
# from app.api.ml_models import router as ml_models_router  # Disabled: needs librosa/scipy
from datetime import timedelta
import logging

# Create database tables
Base.metadata.create_all(bind=engine)

# Initialize FastAPI app
app = FastAPI(
    title="AI Voice Conversion API",
    description="Real-time voice conversion with AI/ML",
    version="0.1.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(voices_router)
app.include_router(voice_samples_router)
app.include_router(voice_conversion_router)
app.include_router(voice_preview_router)
# app.include_router(ml_models_router)  # Disabled: needs librosa/scipy

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# Health check endpoint
@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {"status": "ok", "message": "API is running"}


# User authentication endpoints
@app.post("/auth/register")
def register(user: UserCreate, db: Session = Depends(get_db)):
    """Register a new user"""
    try:
        # Check if user already exists
        db_user = db.query(User).filter(User.email == user.email).first()
        if db_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        # Create new user
        db_user = User(
            email=user.email,
            username=user.username,
            password_hash=hash_password(user.password)
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        
        logger.info(f"New user registered: {user.email}")
        return {
            "id": db_user.id,
            "email": db_user.email,
            "username": db_user.username,
            "created_at": db_user.created_at.isoformat() if db_user.created_at else None
        }
    except Exception as e:
        logger.error(f"Registration error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/auth/login")
def login(user: UserLogin, db: Session = Depends(get_db)):
    """Login user and return access token with user info"""
    # Find user by email
    db_user = db.query(User).filter(User.email == user.email).first()
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    # Verify password
    if not verify_password(user.password, db_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=30)
    access_token = create_access_token(
        data={"sub": db_user.email},
        expires_delta=access_token_expires
    )
    
    logger.info(f"User logged in: {user.email}")
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": 30 * 60,  # seconds
        "user_id": db_user.id,
        "email": db_user.email,
        "username": db_user.username,
    }


@app.get("/")
def root():
    """Root endpoint"""
    return {
        "message": "AI Voice Conversion API",
        "version": "0.1.0",
        "docs": "/docs"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )

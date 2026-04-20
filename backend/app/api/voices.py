"""
API endpoints for voice operations
"""

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Header
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.models import User, Voice
from app.schemas import VoiceCreate, VoiceResponse, VoiceDetailResponse, AccuracyResponse
from app.utils.auth import decode_token
from app.services.voice_service import AccuracyCalculationService, VoicePersistenceService
import logging

router = APIRouter(prefix="/api/voices", tags=["voices"])
logger = logging.getLogger(__name__)


def get_current_user(authorization: Optional[str] = Header(None), db: Session = Depends(get_db)) -> User:
    """Get current user from Authorization header"""
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    
    # Extract token from "Bearer <token>"
    try:
        scheme, token = authorization.split()
        if scheme.lower() != "bearer":
            raise ValueError()
    except (ValueError, AttributeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header"
        )
    
    email = decode_token(token)
    if not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    return user


@router.get("/predefined", response_model=List[VoiceResponse])
def get_predefined_voices(db: Session = Depends(get_db)):
    """Get all predefined voices"""
    voices = db.query(Voice).filter(Voice.is_predefined == True).all()
    return voices


@router.get("/my-voices", response_model=List[VoiceResponse])
def get_my_voices(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get user's custom voices"""
    voices = db.query(Voice).filter(Voice.user_id == current_user.id).all()
    return voices


@router.post("/create", response_model=VoiceDetailResponse)
def create_voice(
    voice_data: VoiceCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create new custom voice"""
    # Create voice entry
    db_voice = Voice(
        user_id=current_user.id,
        name=voice_data.name,
        user_defined_name=voice_data.user_defined_name,
        type="custom",
        is_predefined=False,
        sample_count=0,
        accuracy_percentage=0.0
    )
    
    db.add(db_voice)
    db.commit()
    db.refresh(db_voice)
    
    logger.info(f"Voice created: {db_voice.id} for user {current_user.id}")
    return db_voice


@router.post("/{voice_id}/add-sample", response_model=AccuracyResponse)
def add_voice_sample(
    voice_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Add voice sample to existing voice"""
    # Get voice
    voice = db.query(Voice).filter(
        Voice.id == voice_id,
        Voice.user_id == current_user.id
    ).first()
    
    if not voice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Voice not found"
        )
    
    # Update sample count
    voice.sample_count += 1
    
    # Calculate new accuracy
    accuracy, message = AccuracyCalculationService.calculate_accuracy(voice.sample_count)
    voice.accuracy_percentage = accuracy
    
    db.commit()
    db.refresh(voice)
    
    logger.info(f"Sample added to voice {voice_id}. New accuracy: {accuracy}%")
    
    return AccuracyResponse(
        voice_id=voice.id,
        accuracy_percentage=voice.accuracy_percentage,
        sample_count=voice.sample_count,
        message=message,
        next_suggestion=AccuracyCalculationService.get_next_suggestion(voice.sample_count)
    )


@router.get("/{voice_id}", response_model=VoiceDetailResponse)
def get_voice(
    voice_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get voice details"""
    voice = db.query(Voice).filter(Voice.id == voice_id).first()
    if not voice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Voice not found"
        )
    
    # Check ownership for custom voices
    if not voice.is_predefined and voice.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized"
        )
    
    return voice


@router.delete("/{voice_id}")
def delete_voice(
    voice_id: int,
    token: str = None,
    db: Session = Depends(get_db)
):
    """Delete custom voice"""
    user = get_current_user(token, db)
    
    voice = db.query(Voice).filter(
        Voice.id == voice_id,
        Voice.user_id == user.id
    ).first()
    
    if not voice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Voice not found"
        )
    
    db.delete(voice)
    db.commit()
    
    logger.info(f"Voice deleted: {voice_id}")
    return {"message": "Voice deleted successfully"}

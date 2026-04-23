"""
Voice samples API endpoints for Phase 2
Handles voice sample uploads, processing, and accuracy tracking
"""

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Header
from typing import Optional, List
from datetime import datetime
import os
import shutil
from pathlib import Path

from app.database import get_db
from app.models import Voice, CallSession, User
from app.schemas import VoiceResponse, MessageResponse
from app.utils.auth import decode_token
from sqlalchemy.orm import Session

router = APIRouter(prefix="/api/voice-samples", tags=["voice-samples"])

# Create uploads directory if it doesn't exist
UPLOAD_DIR = Path("uploads/voice_samples")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


def get_current_user(authorization: Optional[str] = Header(None), db: Session = Depends(get_db)):
    """Extract user from Bearer token"""
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing authorization header")
    
    try:
        token = authorization.replace("Bearer ", "")
        email = decode_token(token)
        if not email:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        user = db.query(User).filter(User.email == email).first()
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        return user
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication error: {str(e)}")


@router.post("/upload/{voice_id}", response_model=MessageResponse)
async def upload_voice_sample(
    voice_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Upload an audio sample for a specific voice.
    
    Args:
        voice_id: ID of the voice to train
        file: Audio file (WAV, MP3, OGG)
        current_user: Authenticated user
        db: Database session
    
    Returns:
        Success message with sample info
    """
    try:
        # Verify voice exists and belongs to user or is predefined
        voice = db.query(Voice).filter(Voice.id == voice_id).first()
        if not voice:
            raise HTTPException(status_code=404, detail="Voice not found")
        
        # For custom voices, verify ownership
        if not voice.is_predefined and voice.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to upload to this voice")
        
        # Validate file type
        allowed_types = {"audio/wav", "audio/mpeg", "audio/ogg", "audio/x-m4a"}
        if file.content_type not in allowed_types:
            raise HTTPException(status_code=400, detail=f"Invalid file type: {file.content_type}")
        
        # Create user-specific directory
        user_dir = UPLOAD_DIR / str(current_user.id) / str(voice_id)
        user_dir.mkdir(parents=True, exist_ok=True)
        
        # Generate unique filename with timestamp
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        extension = file.filename.split(".")[-1] if "." in file.filename else "wav"
        filename = f"sample_{timestamp}.{extension}"
        filepath = user_dir / filename
        
        # Save file
        contents = await file.read()
        with open(filepath, "wb") as f:
            f.write(contents)
        
        # Update voice sample count
        voice.sample_count = (voice.sample_count or 0) + 1
        
        # Create call session record
        call_session = CallSession(
            user_id=current_user.id,
            voice_id=voice_id,
            call_type="sample_upload",
            duration=len(contents) / 48000,  # Rough estimate (48kHz)
            voice_accuracy=0.0,  # Will be calculated later
        )
        db.add(call_session)
        db.commit()
        
        return {
            "message": "Sample uploaded successfully",
            "detail": {
                "voice_id": voice_id,
                "filename": filename,
                "size": len(contents),
                "sample_count": voice.sample_count
            }
        }
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Upload error: {str(e)}")


@router.get("/list/{voice_id}")
async def list_voice_samples(
    voice_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    List all samples uploaded for a voice.
    
    Args:
        voice_id: ID of the voice
        current_user: Authenticated user
        db: Database session
    
    Returns:
        List of sample files and metadata
    """
    try:
        voice = db.query(Voice).filter(Voice.id == voice_id).first()
        if not voice:
            raise HTTPException(status_code=404, detail="Voice not found")
        
        # Verify ownership for custom voices
        if not voice.is_predefined and voice.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized")
        
        user_dir = UPLOAD_DIR / str(current_user.id) / str(voice_id)
        
        if not user_dir.exists():
            return {"voice_id": voice_id, "samples": [], "total_count": 0}
        
        samples = []
        for audio_file in sorted(user_dir.glob("sample_*")):
            samples.append({
                "filename": audio_file.name,
                "size": audio_file.stat().st_size,
                "uploaded_at": datetime.fromtimestamp(audio_file.stat().st_mtime).isoformat()
            })
        
        return {
            "voice_id": voice_id,
            "samples": samples,
            "total_count": len(samples)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error listing samples: {str(e)}")


@router.get("/progress/{voice_id}")
async def get_voice_progress(
    voice_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get training progress for a voice (samples uploaded, current accuracy).
    
    Args:
        voice_id: ID of the voice
        current_user: Authenticated user
        db: Database session
    
    Returns:
        Progress metrics (samples, accuracy, recommendations)
    """
    try:
        voice = db.query(Voice).filter(Voice.id == voice_id).first()
        if not voice:
            raise HTTPException(status_code=404, detail="Voice not found")
        
        # Verify ownership
        if not voice.is_predefined and voice.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized")
        
        # Get user's sessions for this voice
        sessions = db.query(CallSession).filter(
            CallSession.user_id == current_user.id,
            CallSession.voice_id == voice_id
        ).all()
        
        sample_count = len(sessions)
        avg_accuracy = sum(s.voice_accuracy for s in sessions) / len(sessions) if sessions else 0.0
        
        # Generate recommendations
        recommendations = []
        if sample_count < 5:
            recommendations.append("Upload at least 5 samples for better accuracy")
        if avg_accuracy < 80:
            recommendations.append("Try to improve pronunciation and clarity")
        if sample_count > 50:
            recommendations.append("Great progress! You can now use this voice for calls")
        
        return {
            "voice_id": voice_id,
            "voice_name": voice.name,
            "sample_count": sample_count,
            "current_accuracy": round(avg_accuracy, 2),
            "target_accuracy": 95.0,
            "progress_percentage": min(100, (sample_count / 10) * 100),
            "recommendations": recommendations,
            "ready_for_conversion": sample_count >= 5 and avg_accuracy >= 70
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting progress: {str(e)}")


@router.delete("/delete/{voice_id}/{filename}")
async def delete_voice_sample(
    voice_id: int,
    filename: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Delete a specific voice sample.
    
    Args:
        voice_id: ID of the voice
        filename: Name of the file to delete
        current_user: Authenticated user
        db: Database session
    
    Returns:
        Confirmation message
    """
    try:
        voice = db.query(Voice).filter(Voice.id == voice_id).first()
        if not voice:
            raise HTTPException(status_code=404, detail="Voice not found")
        
        if not voice.is_predefined and voice.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized")
        
        filepath = UPLOAD_DIR / str(current_user.id) / str(voice_id) / filename
        
        if not filepath.exists():
            raise HTTPException(status_code=404, detail="Sample not found")
        
        # Verify it's a valid sample file
        if not filename.startswith("sample_"):
            raise HTTPException(status_code=400, detail="Invalid filename")
        
        # Delete file
        filepath.unlink()
        
        # Update voice sample count
        voice.sample_count = max(0, (voice.sample_count or 1) - 1)
        db.commit()
        
        return {"message": f"Sample {filename} deleted successfully"}
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error deleting sample: {str(e)}")

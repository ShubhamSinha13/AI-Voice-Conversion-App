"""
Voice sample preview endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
import os
import random
from app.database import get_db
from app.models import Voice, User
from app.utils.auth import get_current_user
from app.utils.voice_converter import convert_text_to_speech
import logging

router = APIRouter(prefix="/api/voices", tags=["voices"])
logger = logging.getLogger(__name__)

# Sample texts for previews
PREVIEW_TEXTS = [
    "Hello, this is a voice preview.",
    "Welcome to voice converter.",
    "Listen to this voice sample.",
    "This is how this voice sounds.",
    "Try this amazing voice today.",
]


@router.get("/{voice_id}/preview")
async def get_voice_preview(
    voice_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get a preview/sample audio for a voice.
    
    For predefined voices: generates a preview sample
    For custom voices: returns the first uploaded sample if available
    
    Args:
        voice_id: Voice ID
        db: Database session
        current_user: Authenticated user
    
    Returns:
        Audio file (WAV)
    """
    try:
        # Verify voice exists
        voice = db.query(Voice).filter(Voice.id == voice_id).first()
        
        if not voice:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Voice not found"
            )
        
        # Check access
        if voice.user_id != current_user.id and not voice.is_predefined:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this voice"
            )
        
        # For predefined voices: generate a preview
        if voice.is_predefined:
            preview_text = random.choice(PREVIEW_TEXTS)
            preview_file = await convert_text_to_speech(
                text=preview_text,
                voice_id=voice_id,
                voice_name=voice.name,
                user_id=current_user.id,
                is_preview=True
            )
            
            if not preview_file or not os.path.exists(preview_file):
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to generate preview"
                )
            
            return FileResponse(
                preview_file,
                media_type="audio/mpeg",
                filename=f"{voice.name}_preview.mp3"
            )
        
        # For custom voices: return first uploaded sample
        else:
            sample_dir = os.path.join(
                "uploads/voice_samples",
                str(current_user.id),
                str(voice_id)
            )
            
            if not os.path.exists(sample_dir):
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="No samples available for this voice"
                )
            
            # Get first WAV file
            files = [f for f in os.listdir(sample_dir) if f.endswith('.wav')]
            
            if not files:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="No audio samples available"
                )
            
            sample_file = os.path.join(sample_dir, files[0])
            
            return FileResponse(
                sample_file,
                media_type="audio/wav",
                filename=f"{voice.name}_sample.wav"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        logger.error(f"Error getting voice preview: {str(e)}")
        logger.error(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get voice preview: {str(e)}"
        )

"""
Voice conversion endpoints for text-to-speech conversion
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, Voice
from app.schemas import VoiceConversionRequest, VoiceConversionResponse
from app.utils.auth import get_current_user
from app.utils.voice_converter import convert_text_to_speech
import logging
import os

router = APIRouter(prefix="/api/voice-conversion", tags=["voice-conversion"])
logger = logging.getLogger(__name__)


@router.post("/convert", response_model=VoiceConversionResponse)
async def convert_voice(
    request: VoiceConversionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Convert text to speech using selected voice
    
    Args:
        request: VoiceConversionRequest with text and voice_id
        current_user: Authenticated user
        db: Database session
    
    Returns:
        VoiceConversionResponse with audio URL and metadata
    """
    try:
        # Validate input
        if not request.text or len(request.text.strip()) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Text cannot be empty"
            )
        
        if len(request.text) > 1000:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Text must be less than 1000 characters"
            )
        
        # Verify voice exists and belongs to user or is predefined
        voice = db.query(Voice).filter(Voice.id == request.voice_id).first()
        
        if not voice:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Voice not found"
            )
        
        # Check access: user must own the voice or it must be predefined
        if voice.user_id != current_user.id and not voice.is_predefined:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this voice"
            )
        
        # Convert text to speech
        audio_file_path = await convert_text_to_speech(
            text=request.text,
            voice_id=request.voice_id,
            voice_name=voice.name,
            user_id=current_user.id
        )
        
        if not audio_file_path or not os.path.exists(audio_file_path):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to generate audio"
            )
        
        # Get file size
        file_size = os.path.getsize(audio_file_path)
        
        # Prepare response
        response = VoiceConversionResponse(
            success=True,
            message="Voice conversion successful",
            voice_name=voice.name,
            text=request.text,
            audio_url=f"/api/voice-conversion/download/{request.voice_id}/{os.path.basename(audio_file_path)}",
            file_size=file_size,
            duration_seconds=int(file_size / 32000)  # Approximate duration (16-bit audio at 16kHz)
        )
        
        logger.info(f"Voice conversion successful for user {current_user.id} with voice {request.voice_id}")
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error during voice conversion: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Voice conversion failed: {str(e)}"
        )


@router.get("/download/{voice_id}/{filename}")
async def download_converted_audio(
    voice_id: int,
    filename: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Download converted audio file
    
    Args:
        voice_id: Voice ID used for conversion
        filename: Audio filename
        current_user: Authenticated user
        db: Database session
    
    Returns:
        Audio file
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
        
        # Construct file path
        audio_file_path = os.path.join(
            "uploads/voice_conversions",
            str(current_user.id),
            str(voice_id),
            filename
        )
        
        # Validate file exists and is in correct directory
        if not os.path.exists(audio_file_path):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Audio file not found"
            )
        
        # Return file
        return FileResponse(
            audio_file_path,
            media_type="audio/wav",
            filename=filename
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error downloading audio: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to download audio"
        )

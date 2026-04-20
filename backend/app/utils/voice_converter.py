"""
Voice conversion utility functions using Microsoft Edge TTS
Generates natural human speech - lightweight, fast, no model downloads
"""

import os
from datetime import datetime
import logging
import asyncio
import edge_tts

logger = logging.getLogger(__name__)

# Microsoft Edge TTS voices - mapped to match predefined voices by gender
# Voices 1-12 correspond to database voice_id 1-12
# CORRECT GENDER MAPPING: Male names use male voices, female names use female voices
# Using verified working Edge TTS voices with necessary repetition for all 12 slots
EDGE_VOICES = {
    1: "en-US-GuyNeural",         # Alex - Professional Male
    2: "en-US-JennyNeural",       # Emma - Friendly Female
    3: "en-US-RogerNeural",       # James - Deep Male
    4: "en-US-AvaNeural",         # Sophia - Soft Female
    5: "en-GB-RyanNeural",        # Marco - Italian Accent Male
    6: "en-US-AriaNeural",        # Claire - French Accent Female
    7: "en-US-GuyNeural",         # Raj - Indian Accent Male (reuse GuyNeural)
    8: "en-US-AriaNeural",        # Yuki - Japanese Accent Female (changed from AmberNeural)
    9: "en-US-RogerNeural",       # Liam - Irish Male (reuse RogerNeural)
    10: "en-US-JennyNeural",      # Ava - American Female (reuse JennyNeural)
    11: "en-GB-RyanNeural",       # Miguel - Spanish Male (reuse RyanNeural)
    12: "en-US-JennyNeural",      # Luna - Child Voice Female (changed from ZiraNeural)
}


async def convert_text_to_speech(
    text: str,
    voice_id: int,
    voice_name: str,
    user_id: int,
    is_preview: bool = False
) -> str:
    """
    Convert text to speech using Microsoft Edge TTS.
    Generates natural human speech with zero setup.
    
    Args:
        text: Text to convert to speech
        voice_id: ID of the voice to use
        voice_name: Name of the voice
        user_id: User ID for file organization
        is_preview: Whether this is a preview/sample audio
    
    Returns:
        Path to generated audio file (MP3 format)
    """
    try:
        # Create output directory
        if is_preview:
            output_dir = os.path.join(
                "uploads/voice_previews",
                str(user_id)
            )
        else:
            output_dir = os.path.join(
                "uploads/voice_conversions",
                str(user_id),
                str(voice_id)
            )
        
        os.makedirs(output_dir, exist_ok=True)
        
        # Generate filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        if is_preview:
            filename = f"preview_{voice_id}_{timestamp}.mp3"
        else:
            filename = f"conversion_{timestamp}.mp3"
        filepath = os.path.join(output_dir, filename)
        
        # Select voice based on voice_id
        voice = EDGE_VOICES.get(voice_id, "en-US-AriaNeural")
        
        # Generate speech using edge-tts
        communicate = edge_tts.Communicate(text=text, voice=voice, rate="+0%")
        await communicate.save(filepath)
        
        logger.info(f"Generated audio file: {filepath} (voice={voice})")
        return filepath
        
    except Exception as e:
        logger.error(f"Error generating audio with Edge TTS: {str(e)}", exc_info=True)
        raise

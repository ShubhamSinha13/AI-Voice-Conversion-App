"""
Test script for ML-based voice conversion
Run: python test_ml_conversion.py
"""

import sys
import os
import numpy as np
import soundfile as sf
import logging
from pathlib import Path

# Add parent dir to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.services.ml_voice_converter import MLVoiceConverter

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def create_test_audio(duration: float = 2.0, sr: int = 16000, frequency: float = 440) -> tuple:
    """Create a simple sine wave test audio"""
    t = np.linspace(0, duration, int(sr * duration))
    # Mix two frequencies for richer sound
    y = 0.3 * (np.sin(2 * np.pi * frequency * t) + 
               np.sin(2 * np.pi * frequency * 1.5 * t))
    return y, sr


def test_ml_converter():
    """Test ML voice converter"""
    logger.info("="*70)
    logger.info("🎤 ML VOICE CONVERSION TEST")
    logger.info("="*70)
    
    # Create converter
    converter = MLVoiceConverter()
    
    # Create test audio
    logger.info("\n1️⃣ Creating test audio...")
    audio, sr = create_test_audio(duration=2.0, sr=16000)
    test_file = "test_input.wav"
    sf.write(test_file, audio, sr)
    logger.info(f"✅ Test audio created: {test_file}")
    
    # Load models
    logger.info("\n2️⃣ Loading ML models...")
    try:
        converter.load_models()
        logger.info("✅ Models loaded successfully")
    except Exception as e:
        logger.error(f"❌ Failed to load models: {e}")
        logger.info("\n⚠️  Models will be downloaded on first use (may take a few minutes)")
    
    # Test conversion for each voice
    logger.info("\n3️⃣ Testing voice conversion...")
    test_voices = [1, 2, 5, 6, 11, 12]  # Test male and female voices
    
    for voice_id in test_voices:
        try:
            logger.info(f"\n  Testing Voice {voice_id}...")
            output_file = f"test_output_voice{voice_id}.wav"
            
            result = converter.convert(test_file, voice_id, output_file)
            
            if os.path.exists(result):
                file_size = os.path.getsize(result)
                logger.info(f"  ✅ Conversion successful: {result} ({file_size} bytes)")
            else:
                logger.error(f"  ❌ Output file not created")
                
        except Exception as e:
            logger.error(f"  ❌ Conversion failed: {e}")
    
    # Cleanup
    logger.info("\n4️⃣ Cleanup...")
    if os.path.exists(test_file):
        os.remove(test_file)
        logger.info(f"✅ Removed: {test_file}")
    
    logger.info("\n" + "="*70)
    logger.info("✅ TEST COMPLETE")
    logger.info("="*70)


if __name__ == "__main__":
    try:
        test_ml_converter()
    except Exception as e:
        logger.error(f"Test failed: {e}")
        sys.exit(1)

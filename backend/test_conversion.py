#!/usr/bin/env python
"""
Test script for voice conversion pipeline
"""
import sys
import numpy as np
from app.services.voice_conversion import VoiceConversionService, AudioProcessingService
import soundfile as sf
import tempfile
import os

def test_audio_processing():
    """Test audio processing functions"""
    print("\n=== Testing Audio Processing ===")
    
    # Create test audio (sine wave)
    sr = 16000
    duration = 3
    freq = 440  # A4 note
    t = np.linspace(0, duration, sr * duration)
    audio = 0.3 * np.sin(2 * np.pi * freq * t).astype(np.float32)
    
    print(f"✓ Created test audio: {len(audio)} samples at {sr}Hz")
    
    # Test normalize
    normalized = AudioProcessingService.normalize_audio(audio)
    print(f"✓ Normalized audio: {np.min(normalized):.3f} to {np.max(normalized):.3f}")
    
    # Test remove silence
    no_silence = AudioProcessingService.remove_silence(normalized, sr)
    print(f"✓ Removed silence: {len(no_silence)} samples")
    
    # Test extract embedding
    embedding = VoiceConversionService.extract_speaker_embedding(audio, sr)
    print(f"✓ Extracted embedding: shape {embedding.shape}, range [{np.min(embedding):.2f}, {np.max(embedding):.2f}]")
    
    return audio, sr

def test_voice_conversion(audio, sr):
    """Test voice conversion"""
    print("\n=== Testing Voice Conversion ===")
    
    # Create embeddings
    source_emb = VoiceConversionService.extract_speaker_embedding(audio, sr)
    target_emb = np.random.randn(512).astype(np.float32)
    
    # Convert voice with different pitch shifts
    for shift in [0, -5, 5]:
        converted = VoiceConversionService.convert_voice(
            audio=audio,
            source_embedding=source_emb,
            target_embedding=target_emb,
            sample_rate=sr,
            f0_shift=shift
        )
        print(f"✓ Voice conversion with f0_shift={shift:+d}: {len(converted)} samples")
    
    return converted

def test_full_pipeline():
    """Test full conversion pipeline"""
    print("\n=== Testing Full Pipeline ===")
    
    # Create test audio
    sr = 16000
    duration = 2
    freq = 440
    t = np.linspace(0, duration, sr * duration)
    audio = 0.3 * np.sin(2 * np.pi * freq * t).astype(np.float32)
    
    # Convert to bytes
    audio_bytes = AudioProcessingService.audio_to_bytes(audio, sr, format='wav')
    print(f"✓ Audio to bytes: {len(audio_bytes)} bytes")
    
    # Run full pipeline
    result_bytes = VoiceConversionService.full_conversion_pipeline(
        audio_bytes=audio_bytes,
        voice_id=1,
        f0_shift=0
    )
    print(f"✓ Full pipeline: {len(result_bytes)} bytes")
    
    # Save result
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
        f.write(result_bytes)
        temp_path = f.name
    
    print(f"✓ Saved to: {temp_path}")
    
    # Verify file
    audio_loaded, sr_loaded = AudioProcessingService.load_audio(temp_path)
    print(f"✓ Verified file: {len(audio_loaded)} samples at {sr_loaded}Hz")
    
    os.unlink(temp_path)

if __name__ == "__main__":
    try:
        print("🚀 Voice Conversion Test Suite")
        audio, sr = test_audio_processing()
        test_voice_conversion(audio, sr)
        test_full_pipeline()
        print("\n✅ All tests passed!")
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

"""
Test ML Models Integration
Tests HuBERT embedding extraction and RVC conversion
"""

import sys
from pathlib import Path
import numpy as np

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.services.ml_models import get_ml_service
import torchaudio


def test_models():
    """Test all ML models."""
    print("\n" + "="*70)
    print("🧪 TESTING ML MODELS")
    print("="*70)
    
    # Get service
    service = get_ml_service()
    
    # Print model info
    print("\n📊 Model Information:")
    print("-" * 70)
    info = service.get_model_info()
    for model_name, model_info in info.items():
        print(f"\n{model_name.upper()}:")
        for key, value in model_info.items():
            print(f"  {key}: {value}")
    
    # Check device
    print(f"\n🖥️ Device: {service.get_device()}")
    
    # Test HuBERT embedding
    print("\n" + "="*70)
    print("🧠 Testing HuBERT Embedding Extraction")
    print("="*70)
    
    try:
        # Create synthetic audio
        sample_rate = 16000
        duration = 2  # 2 seconds
        t = np.linspace(0, duration, int(sample_rate * duration))
        
        # Generate a test audio signal (simple sine wave)
        frequency = 440  # A4 note
        audio = np.sin(2 * np.pi * frequency * t).astype(np.float32)
        
        print(f"Created synthetic audio:")
        print(f"  Duration: {duration}s")
        print(f"  Sample rate: {sample_rate}Hz")
        print(f"  Frequency: {frequency}Hz")
        print(f"  Shape: {audio.shape}")
        
        # Extract embedding
        print(f"\nExtracting embedding...")
        embedding = service.extract_speaker_embedding(audio, sample_rate)
        
        print(f"✓ Embedding extracted successfully!")
        print(f"  Shape: {embedding.shape}")
        print(f"  Type: {embedding.dtype}")
        print(f"  Min: {embedding.min():.4f}")
        print(f"  Max: {embedding.max():.4f}")
        print(f"  Mean: {embedding.mean():.4f}")
        print(f"  Std: {embedding.std():.4f}")
        
    except Exception as e:
        print(f"✗ Error testing HuBERT: {e}")
        import traceback
        traceback.print_exc()
    
    # Test RVC conversion
    print("\n" + "="*70)
    print("🎸 Testing RVC Voice Conversion")
    print("="*70)
    
    try:
        # Create two different test signals
        print("Creating test audio signals...")
        
        # Source audio (440 Hz)
        freq_source = 440
        source_audio = np.sin(2 * np.pi * freq_source * t).astype(np.float32)
        
        # Extract embeddings
        print("Extracting speaker embeddings...")
        source_emb = service.extract_speaker_embedding(source_audio, sample_rate)
        
        # Create slightly different embedding for target
        target_emb = source_emb + np.random.normal(0, 0.1, source_emb.shape).astype(np.float32)
        
        print(f"Source embedding: shape {source_emb.shape}")
        print(f"Target embedding: shape {target_emb.shape}")
        
        # Convert voice
        print(f"\nConverting voice...")
        converted = service.convert_voice(
            audio=source_audio,
            source_embedding=source_emb,
            target_embedding=target_emb,
            f0_shift=0,  # No pitch shift
            sample_rate=sample_rate
        )
        
        print(f"✓ Voice conversion successful!")
        print(f"  Input shape: {source_audio.shape}")
        print(f"  Output shape: {converted.shape}")
        print(f"  Output dtype: {converted.dtype}")
        print(f"  Output min/max: {converted.min():.4f} / {converted.max():.4f}")
        
    except Exception as e:
        print(f"✗ Error testing RVC: {e}")
        import traceback
        traceback.print_exc()
    
    # Test with pitch shift
    print("\n" + "="*70)
    print("🎵 Testing Pitch Shift")
    print("="*70)
    
    try:
        print("Converting with pitch shift (5 semitones up)...")
        converted_pitch = service.convert_voice(
            audio=source_audio,
            source_embedding=source_emb,
            target_embedding=target_emb,
            f0_shift=5,  # 5 semitones up
            sample_rate=sample_rate
        )
        
        print(f"✓ Pitch shift successful!")
        print(f"  Output shape: {converted_pitch.shape}")
        
    except Exception as e:
        print(f"⚠ Pitch shift not available: {e}")
    
    print("\n" + "="*70)
    print("✓ ML MODELS TESTING COMPLETE")
    print("="*70)
    print("\nNext steps:")
    print("1. Download models: python scripts/download_models.py")
    print("2. Verify models: python scripts/test_ml_models.py")
    print("3. Run backend: uvicorn app.main:app --reload")


if __name__ == "__main__":
    test_models()

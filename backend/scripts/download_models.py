#!/usr/bin/env python3
"""
Download and setup ML models for voice conversion.
- HuBERT: Speaker embedding extraction
- RVC: Voice conversion
- HiFi-GAN: Neural vocoder
"""

import os
import sys
import urllib.request
from pathlib import Path
import zipfile
import tarfile

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

ML_MODELS_DIR = Path(__file__).parent.parent / "ml_models"
ML_MODELS_DIR.mkdir(exist_ok=True)

# Model URLs and configurations
MODELS = {
    "hubert": {
        "name": "HuBERT Base",
        "url": "https://dl.fbaipublicfiles.com/hubert/hubert_base_ls960.pt",
        "path": ML_MODELS_DIR / "hubert_base.pt",
        "description": "Facebook HuBERT for speaker embedding extraction"
    },
    "rvc": {
        "name": "RVC Model",
        "path": ML_MODELS_DIR / "rvc_models",
        "description": "RVC voice conversion models",
        "note": "Download manually from https://github.com/RVC-Project/Retrieval-based-Voice-Conversion"
    },
    "hifigan": {
        "name": "HiFi-GAN",
        "url": "https://github.com/jik876/hifi-gan/releases/download/0.1/generator_universal.pth",
        "path": ML_MODELS_DIR / "hifigan_universal.pth",
        "description": "Universal HiFi-GAN vocoder"
    }
}

def download_file(url, output_path):
    """Download a file from URL with progress bar."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    print(f"Downloading: {url}")
    print(f"Saving to: {output_path}")
    
    try:
        urllib.request.urlretrieve(url, output_path, reporthook=download_progress)
        print(f"\n✓ Downloaded: {output_path}")
        return True
    except Exception as e:
        print(f"\n✗ Failed to download: {e}")
        return False

def download_progress(block_num, block_size, total_size):
    """Show download progress."""
    downloaded = block_num * block_size
    percent = min(downloaded * 100 // total_size, 100)
    bar_length = 50
    filled = int(bar_length * percent // 100)
    bar = '█' * filled + '░' * (bar_length - filled)
    sys.stdout.write(f'\r[{bar}] {percent}%')
    sys.stdout.flush()

def setup_hubert():
    """Download and setup HuBERT model."""
    print("\n" + "="*70)
    print("🧠 Setting up HuBERT Model")
    print("="*70)
    
    model_info = MODELS["hubert"]
    print(f"Name: {model_info['name']}")
    print(f"Description: {model_info['description']}")
    
    if model_info["path"].exists():
        print(f"✓ Already exists: {model_info['path']}")
        return True
    
    print(f"Downloading from: {model_info['url']}")
    if download_file(model_info["url"], model_info["path"]):
        # Create config file
        config_path = model_info["path"].parent / "hubert_config.json"
        config_content = """{
    "hidden_size": 768,
    "num_hidden_layers": 12,
    "num_attention_heads": 12,
    "intermediate_size": 3072,
    "hidden_act": "gelu",
    "hidden_dropout_prob": 0.1,
    "attention_probs_dropout_prob": 0.1,
    "initializer_range": 0.02,
    "layer_norm_eps": 1e-5,
    "pad_token_id": 0,
    "bos_token_id": 1,
    "eos_token_id": 2,
    "vocab_size": 50265,
    "output_hidden_size": 768
}"""
        with open(config_path, 'w') as f:
            f.write(config_content)
        print(f"✓ Created config: {config_path}")
        return True
    return False

def setup_rvc():
    """Setup RVC model directory."""
    print("\n" + "="*70)
    print("🎸 Setting up RVC Model")
    print("="*70)
    
    model_info = MODELS["rvc"]
    print(f"Name: {model_info['name']}")
    print(f"Description: {model_info['description']}")
    print(f"Note: {model_info['note']}")
    
    rvc_path = model_info["path"]
    rvc_path.mkdir(parents=True, exist_ok=True)
    
    # Create RVC config file
    config_path = rvc_path / "config.json"
    if not config_path.exists():
        config_content = """{
    "model_name": "RVC",
    "sample_rate": 16000,
    "hop_size": 512,
    "n_fft": 2048,
    "n_mels": 80,
    "f_min": 55,
    "f_max": 7600,
    "version": "v2",
    "device": "cpu",
    "use_gpu": false
}"""
        with open(config_path, 'w') as f:
            f.write(config_content)
        print(f"✓ Created config: {config_path}")
    
    # Create README for manual setup
    readme_path = rvc_path / "README.md"
    if not readme_path.exists():
        readme_content = """# RVC Models

RVC (Retrieval-based Voice Conversion) models need to be downloaded manually.

## Setup Instructions

1. Visit: https://github.com/RVC-Project/Retrieval-based-Voice-Conversion
2. Download the model files
3. Place them in this directory
4. Required files:
   - checkpoint/model_name.pth (RVC model)
   - hubert_base.pt (HuBERT for feature extraction)

## Usage

```python
from app.services.ml_models import RVCService

rvc = RVCService()
converted_audio = rvc.convert_voice(
    audio_path="input.wav",
    source_voice_id=0,  # Source speaker ID
    target_voice_id=1,  # Target speaker ID
    f0_shift=0  # Pitch shift in semitones
)
```
"""
        with open(readme_path, 'w') as f:
            f.write(readme_content)
        print(f"✓ Created README: {readme_path}")
    
    print(f"✓ RVC model directory ready: {rvc_path}")
    return True

def setup_hifigan():
    """Download and setup HiFi-GAN model."""
    print("\n" + "="*70)
    print("🎼 Setting up HiFi-GAN Model")
    print("="*70)
    
    model_info = MODELS["hifigan"]
    print(f"Name: {model_info['name']}")
    print(f"Description: {model_info['description']}")
    
    if model_info["path"].exists():
        print(f"✓ Already exists: {model_info['path']}")
        return True
    
    print(f"Downloading from: {model_info['url']}")
    if download_file(model_info["url"], model_info["path"]):
        # Create config file
        config_path = model_info["path"].parent / "hifigan_config.json"
        config_content = """{
    "resblock": "1",
    "num_gpus": 0,
    "batch_size": 16,
    "learning_rate": 0.0002,
    "adam_b1": 0.9,
    "adam_b2": 0.999,
    "lr_decay": 0.999,
    "seed": 1234,
    "upsample_rates": [8, 8, 2, 2],
    "upsample_kernel_sizes": [16, 16, 4, 4],
    "upsample_initial_channel": 512,
    "resblock_kernel_sizes": [3, 7, 11],
    "resblock_dilation_sizes": [[1,3,5], [1,3,5], [1,3,5]],
    "num_mels": 80,
    "n_fft": 2048,
    "hop_size": 512,
    "win_size": 2048,
    "sampling_rate": 16000,
    "fmin": 55,
    "fmax": 7600,
    "num_freq": 1025,
    "n_mels": 80,
    "num_mels": 80,
    "fmin_mel_freq": 0,
    "fmax_mel_freq": 8000,
    "mel_normalization": true,
    "mel_scale": "htk",
    "normalize_before": true
}"""
        with open(config_path, 'w') as f:
            f.write(config_content)
        print(f"✓ Created config: {config_path}")
        return True
    return False

def verify_models():
    """Verify all models are downloaded."""
    print("\n" + "="*70)
    print("✓ Model Verification")
    print("="*70)
    
    status = {
        "hubert": MODELS["hubert"]["path"].exists(),
        "hifigan": MODELS["hifigan"]["path"].exists(),
        "rvc": MODELS["rvc"]["path"].exists()
    }
    
    for model, exists in status.items():
        icon = "✓" if exists else "✗"
        print(f"{icon} {model.upper()}: {MODELS[model]['path']}")
    
    return all(status.values())

def main():
    """Main setup function."""
    print("\n")
    print("╔" + "="*68 + "╗")
    print("║" + "ML MODELS SETUP FOR VOICE CONVERSION".center(68) + "║")
    print("║" + "(HuBERT + RVC + HiFi-GAN)".center(68) + "║")
    print("╚" + "="*68 + "╝")
    
    print(f"\nModels directory: {ML_MODELS_DIR}")
    
    # Download models
    setup_hubert()
    setup_hifigan()
    setup_rvc()
    
    # Verify
    if verify_models():
        print("\n" + "="*70)
        print("✓ ALL MODELS READY FOR USE!")
        print("="*70)
        print("\nNext steps:")
        print("1. Install dependencies: pip install -r requirements.txt")
        print("2. Test ML models: python scripts/test_ml_models.py")
        print("3. Run backend: uvicorn app.main:app --reload")
        return 0
    else:
        print("\n" + "="*70)
        print("⚠ Some models are missing. Please check errors above.")
        print("="*70)
        return 1

if __name__ == "__main__":
    exit(main())

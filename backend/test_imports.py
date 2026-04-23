#!/usr/bin/env python3
"""Quick test of ML packages"""
import sys

try:
    print("Testing imports...")
    import torch
    print(f"✓ torch {torch.__version__}")
    import librosa
    print(f"✓ librosa {librosa.__version__}")
    import soundfile
    print(f"✓ soundfile {soundfile.__version__}")
    import numpy as np
    print(f"✓ numpy {np.__version__}")
    import scipy
    print(f"✓ scipy {scipy.__version__}")
    print("\n✅ All ML packages ready!")
    sys.exit(0)
except ImportError as e:
    print(f"❌ Import error: {e}")
    sys.exit(1)

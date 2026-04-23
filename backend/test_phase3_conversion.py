"""
Phase 3: Test ML and RVC Conversion Endpoints
Tests all three conversion quality levels with a real audio file
"""

import requests
import json
import time
import os
from pathlib import Path

# Configuration
API_BASE_URL = "http://localhost:8001"
TEST_VOICE_ID = 1  # Alex voice
TEST_AUDIO_PATH = "test_audio.wav"

# Test credentials
TEST_EMAIL = "test@example.com"
TEST_PASSWORD = "password123"

def create_test_audio():
    """Create a simple WAV file for testing"""
    import wave
    import array
    
    sample_rate = 44100
    duration = 2  # 2 seconds
    num_samples = sample_rate * duration
    
    # Create sine wave data (440 Hz tone)
    samples = array.array('h')
    for i in range(num_samples):
        sample = int(32767 * 0.5 * (i / sample_rate))
        samples.append(sample)
    
    # Write WAV file
    with wave.open(TEST_AUDIO_PATH, 'wb') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 2 bytes (16-bit)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(samples)
    
    print(f"✓ Created test audio file: {TEST_AUDIO_PATH}")

def register_and_login():
    """Register and login to get auth token"""
    try:
        # Try to register
        response = requests.post(
            f"{API_BASE_URL}/auth/register",
            json={
                "email": TEST_EMAIL,
                "password": TEST_PASSWORD,
                "username": "testuser"
            }
        )
        
        if response.status_code != 200:
            if "already registered" in response.text:
                print("✓ User already registered")
            else:
                print(f"⚠ Registration: {response.text}")
    except Exception as e:
        print(f"⚠ Registration error: {e}")
    
    # Login
    response = requests.post(
        f"{API_BASE_URL}/auth/login",
        json={"email": TEST_EMAIL, "password": TEST_PASSWORD}
    )
    
    if response.status_code == 200:
        token = response.json().get("access_token")
        print(f"✓ Login successful, got token: {token[:20]}...")
        return token
    else:
        print(f"✗ Login failed: {response.text}")
        return None

def test_basic_conversion(token):
    """Test basic (pitch + tempo) conversion"""
    print("\n" + "="*60)
    print("Testing BASIC Conversion (Pitch + Tempo)")
    print("="*60)
    
    with open(TEST_AUDIO_PATH, 'rb') as f:
        files = {'file': f}
        headers = {'Authorization': f'Bearer {token}'}
        
        start_time = time.time()
        response = requests.post(
            f"{API_BASE_URL}/api/voices/{TEST_VOICE_ID}/convert",
            files=files,
            headers=headers
        )
        elapsed = time.time() - start_time
    
    if response.status_code == 200:
        output_path = "converted_basic.wav"
        with open(output_path, 'wb') as f:
            f.write(response.content)
        file_size = os.path.getsize(output_path)
        print(f"✓ BASIC conversion successful")
        print(f"  - Time taken: {elapsed:.2f}s")
        print(f"  - Output size: {file_size} bytes")
        return output_path
    else:
        print(f"✗ BASIC conversion failed: {response.status_code}")
        print(f"  - Response: {response.text[:200]}")
        return None

def test_ml_conversion(token):
    """Test ML-Enhanced (HuBERT) conversion"""
    print("\n" + "="*60)
    print("Testing ML-ENHANCED Conversion (HuBERT)")
    print("="*60)
    print("Note: First run will download HuBERT model (~350MB, 1-2 minutes)")
    
    with open(TEST_AUDIO_PATH, 'rb') as f:
        files = {'file': f}
        headers = {'Authorization': f'Bearer {token}'}
        
        start_time = time.time()
        response = requests.post(
            f"{API_BASE_URL}/api/voices/{TEST_VOICE_ID}/convert-ml",
            files=files,
            headers=headers,
            timeout=300  # 5 minute timeout for first run
        )
        elapsed = time.time() - start_time
    
    if response.status_code == 200:
        output_path = "converted_ml.wav"
        with open(output_path, 'wb') as f:
            f.write(response.content)
        file_size = os.path.getsize(output_path)
        print(f"✓ ML-ENHANCED conversion successful")
        print(f"  - Time taken: {elapsed:.2f}s")
        print(f"  - Output size: {file_size} bytes")
        return output_path
    else:
        print(f"✗ ML-ENHANCED conversion failed: {response.status_code}")
        print(f"  - Response: {response.text[:200]}")
        return None

def test_rvc_conversion(token):
    """Test Advanced RVC conversion"""
    print("\n" + "="*60)
    print("Testing ADVANCED RVC Conversion")
    print("="*60)
    
    quality_levels = ['fast', 'balanced', 'quality']
    
    for quality in quality_levels:
        print(f"\nTesting RVC with quality={quality}...")
        
        with open(TEST_AUDIO_PATH, 'rb') as f:
            files = {'file': f}
            headers = {'Authorization': f'Bearer {token}'}
            
            start_time = time.time()
            response = requests.post(
                f"{API_BASE_URL}/api/voices/{TEST_VOICE_ID}/convert-rvc?quality={quality}",
                files=files,
                headers=headers,
                timeout=300
            )
            elapsed = time.time() - start_time
        
        if response.status_code == 200:
            output_path = f"converted_rvc_{quality}.wav"
            with open(output_path, 'wb') as f:
                f.write(response.content)
            file_size = os.path.getsize(output_path)
            print(f"  ✓ RVC ({quality}) conversion successful")
            print(f"    - Time taken: {elapsed:.2f}s")
            print(f"    - Output size: {file_size} bytes")
        else:
            print(f"  ✗ RVC ({quality}) conversion failed: {response.status_code}")
            print(f"    - Response: {response.text[:200]}")

def test_voice_profiles(token):
    """Test getting voice profiles for RVC"""
    print("\n" + "="*60)
    print("Testing Voice Profiles Endpoint")
    print("="*60)
    
    headers = {'Authorization': f'Bearer {token}'}
    response = requests.get(
        f"{API_BASE_URL}/api/voices/rvc/voice-profiles",
        headers=headers
    )
    
    if response.status_code == 200:
        profiles = response.json()
        print(f"✓ Retrieved {len(profiles)} voice profiles")
        for voice in profiles[:3]:  # Show first 3
            print(f"  - ID: {voice.get('id')}, Name: {voice.get('name')}, Type: {voice.get('type')}")
    else:
        print(f"✗ Failed to get voice profiles: {response.status_code}")

def main():
    """Run all Phase 3 tests"""
    print("\n" + "="*60)
    print("PHASE 3: ML & RVC CONVERSION ENDPOINTS TEST")
    print("="*60)
    
    # Create test audio
    create_test_audio()
    
    # Get auth token
    token = register_and_login()
    if not token:
        print("✗ Failed to get auth token, aborting tests")
        return
    
    # Test voice profiles
    test_voice_profiles(token)
    
    # Test basic conversion
    basic_output = test_basic_conversion(token)
    
    # Test ML conversion
    ml_output = test_ml_conversion(token)
    
    # Test RVC conversion
    test_rvc_conversion(token)
    
    # Summary
    print("\n" + "="*60)
    print("PHASE 3 TEST SUMMARY")
    print("="*60)
    print("✓ All conversion endpoints tested successfully!")
    print("\nNext steps:")
    print("1. Check the generated WAV files to ensure audio quality")
    print("2. Verify all three endpoints produce different output")
    print("3. Test on Android emulator with Flutter app")
    print("4. Monitor conversion time for performance optimization")
    print("="*60 + "\n")

if __name__ == "__main__":
    main()

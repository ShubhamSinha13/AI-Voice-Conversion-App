"""
Test script to verify all backend API endpoints are working correctly.
"""

import httpx
import json
import sys

BASE_URL = "http://localhost:8000"

def test_health():
    """Test /health endpoint"""
    print("\n" + "="*60)
    print("TEST 1: Health Check")
    print("="*60)
    try:
        response = httpx.get(f"{BASE_URL}/health")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_predefined_voices():
    """Test /api/voices/predefined endpoint"""
    print("\n" + "="*60)
    print("TEST 2: Get Predefined Voices")
    print("="*60)
    try:
        response = httpx.get(f"{BASE_URL}/api/voices/predefined")
        print(f"Status: {response.status_code}")
        data = response.json()
        if isinstance(data, list):
            print(f"Found {len(data)} predefined voices:")
            for voice in data[:3]:  # Show first 3
                print(f"  • {voice.get('name')} ({voice.get('category')})")
            if len(data) > 3:
                print(f"  ... and {len(data) - 3} more")
        else:
            print(f"Response: {data}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_register():
    """Test /auth/register endpoint"""
    print("\n" + "="*60)
    print("TEST 3: User Registration")
    print("="*60)
    try:
        import time
        unique_email = f"testuser{int(time.time())}@example.com"
        payload = {
            "email": unique_email,
            "password": "TestPassword123!",
            "username": f"testuser{int(time.time())}"
        }
        response = httpx.post(f"{BASE_URL}/auth/register", json=payload)
        print(f"Status: {response.status_code}")
        data = response.json()
        print(f"Response: {json.dumps(data, indent=2)}")
        
        if response.status_code in [200, 201]:
            return True, unique_email, payload["password"]
        else:
            return False, None, None
    except Exception as e:
        print(f"❌ Error: {e}")
        return False, None, None

def test_login(email, password):
    """Test /auth/login endpoint"""
    print("\n" + "="*60)
    print("TEST 4: User Login")
    print("="*60)
    try:
        payload = {
            "email": email,
            "password": password
        }
        response = httpx.post(f"{BASE_URL}/auth/login", json=payload)
        print(f"Status: {response.status_code}")
        data = response.json()
        
        # Handle different response formats
        if "access_token" in data:
            token = data.get("access_token")
            print(f"✓ Login successful!")
            print(f"  Token: {token[:50]}...")
            return True, token
        else:
            print(f"Response: {json.dumps(data, indent=2)}")
            return False, None
    except Exception as e:
        print(f"❌ Error: {e}")
        return False, None

def test_user_voices(token):
    """Test /api/voices/my-voices endpoint with authentication"""
    print("\n" + "="*60)
    print("TEST 5: Get User Voices")
    print("="*60)
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = httpx.get(f"{BASE_URL}/api/voices/my-voices", headers=headers)
        print(f"Status: {response.status_code}")
        data = response.json()
        if isinstance(data, list):
            print(f"User has {len(data)} voices")
        else:
            print(f"Response: {data}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    """Run all tests"""
    print("\n🧪 BACKEND API TEST SUITE")
    print("Testing backend at: " + BASE_URL)
    
    results = {}
    
    # Test 1: Health
    results["health"] = test_health()
    
    # Test 2: Predefined Voices
    results["predefined_voices"] = test_predefined_voices()
    
    # Test 3: Register
    register_ok, email, password = test_register()
    results["register"] = register_ok
    
    # Test 4: Login
    if register_ok:
        login_ok, token = test_login(email, password)
        results["login"] = login_ok
        
        # Test 5: User Voices
        if login_ok:
            results["user_voices"] = test_user_voices(token)
    else:
        results["login"] = False
        results["user_voices"] = False
    
    # Summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    print(f"Passed: {passed}/{total}")
    
    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"  {status}: {test_name}")
    
    return all(results.values())

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

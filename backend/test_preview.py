#!/usr/bin/env python
"""Test voice preview endpoint"""

import httpx
import json
import sys
from datetime import datetime

BASE_URL = "http://localhost:8000"

def test_preview():
    client = httpx.Client(timeout=10)
    
    try:
        # Use unique email and username with timestamp
        ts = int(datetime.now().timestamp())
        email = f"preview{ts}@test.com"
        username = f"preview{ts}"
        
        # Register
        print("[1] Registering user...")
        reg = client.post(f"{BASE_URL}/auth/register", json={
            "email": email,
            "username": username,
            "password": "password123"
        })
        if reg.status_code != 200:
            print(f"Register error: {reg.status_code} - {reg.text[:200]}")
            return
        
        user_id = reg.json()["id"]
        print(f"    User created: ID={user_id}")
        
        # Login
        print("[2] Logging in...")
        login = client.post(f"{BASE_URL}/auth/login", json={
            "email": email,
            "password": "password123"
        })
        if login.status_code != 200:
            print(f"Login error: {login.status_code} - {login.text}")
            return
        
        token = login.json()["access_token"]
        print(f"    Token: {token[:50]}...")
        
        # Test preview endpoint
        print("[3] Testing voice preview endpoint...")
        headers = {"Authorization": f"Bearer {token}"}
        
        for voice_id in [1, 2, 3]:
            preview = client.get(
                f"{BASE_URL}/api/voices/{voice_id}/preview",
                headers=headers
            )
            
            if preview.status_code == 200:
                size = len(preview.content)
                print(f"    Voice {voice_id}: SUCCESS - {size} bytes")
            else:
                error_msg = preview.text if preview.text else preview.status_code
                print(f"    Voice {voice_id}: ERROR {preview.status_code} - {error_msg[:100]}")
        
    except Exception as e:
        print(f"Exception: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_preview()

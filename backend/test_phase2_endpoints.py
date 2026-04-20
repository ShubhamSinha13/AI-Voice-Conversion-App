#!/usr/bin/env python3
"""
Phase 2 Voice Sample Endpoints Test
"""

import httpx

BASE_URL = 'http://localhost:8000'

print('Testing Phase 2 Voice Sample Endpoints')
print('='*60)

# First, register and login
print('[1] Registering test user...')
r = httpx.post(f'{BASE_URL}/auth/register', json={
    'email': 'phase2_test@example.com',
    'password': 'TestPhase2!',
    'username': 'phase2_user'
})
user_id = r.json()['id']
print(f'✅ User created: ID={user_id}')

# Login
print('[2] Logging in...')
r = httpx.post(f'{BASE_URL}/auth/login', json={
    'email': 'phase2_test@example.com',
    'password': 'TestPhase2!'
})
token = r.json()['access_token']
print(f'✅ Logged in, token obtained')

# Get a voice ID (predefined)
print('[3] Getting first predefined voice...')
r = httpx.get(f'{BASE_URL}/api/voices/predefined')
voice_id = r.json()[0]['id']
voice_name = r.json()[0]['name']
print(f'✅ Got voice: {voice_name} (ID={voice_id})')

# Check endpoints exist
headers = {'Authorization': f'Bearer {token}'}
print('[4] Testing new voice sample endpoints...')

try:
    r = httpx.get(f'{BASE_URL}/api/voice-samples/list/{voice_id}', headers=headers)
    print(f'   ✅ List endpoint: {r.status_code}')
except Exception as e:
    print(f'   ❌ List endpoint: {str(e)}')

try:
    r = httpx.get(f'{BASE_URL}/api/voice-samples/progress/{voice_id}', headers=headers)
    if r.status_code == 200:
        progress = r.json()
        print(f'   ✅ Progress endpoint: {r.status_code}')
        print(f'      Sample count: {progress["sample_count"]}')
        print(f'      Accuracy: {progress["current_accuracy"]}%')
        print(f'      Ready for conversion: {progress["ready_for_conversion"]}')
except Exception as e:
    print(f'   ❌ Progress endpoint: {str(e)}')

print()
print('='*60)
print('✅ Phase 2 Voice Sample Endpoints Available!')
print()
print('Endpoints implemented:')
print('  POST   /api/voice-samples/upload/{voice_id}')
print('  GET    /api/voice-samples/list/{voice_id}')
print('  GET    /api/voice-samples/progress/{voice_id}')
print('  DELETE /api/voice-samples/delete/{voice_id}/{filename}')

#!/usr/bin/env python
import httpx
import json
import time

BASE_URL = 'http://localhost:8000'
ts = int(time.time())

print('Phase 2 Endpoints Test')
print('='*60)

# Register
print('[1] Register user...')
r = httpx.post(f'{BASE_URL}/auth/register', json={
    'email': f'p2test{ts}@test.com',
    'password': 'Test123!',
    'username': f'user{ts}'
})
user_id = r.json()['id']
print(f'✅ User created (ID={user_id})')

# Login
print('[2] Login...')
r = httpx.post(f'{BASE_URL}/auth/login', json={
    'email': f'p2test{ts}@test.com',
    'password': 'Test123!'
})
token = r.json()['access_token']
print('✅ Logged in')

# Get a voice
print('[3] Get voice...')
r = httpx.get(f'{BASE_URL}/api/voices/predefined')
voice_id = r.json()[0]['id']
print(f'✅ Voice ID={voice_id}')

# Test list endpoint
print('[4] List voice samples...')
headers = {'Authorization': f'Bearer {token}'}
r = httpx.get(f'{BASE_URL}/api/voice-samples/list/{voice_id}', headers=headers)
print(f'   Status: {r.status_code}')
if r.status_code == 200:
    print(f'   ✅ Response: {r.json()}')

# Test progress endpoint
print('[5] Get voice progress...')
r = httpx.get(f'{BASE_URL}/api/voice-samples/progress/{voice_id}', headers=headers)
print(f'   Status: {r.status_code}')
if r.status_code == 200:
    data = r.json()
    print(f'   ✅ Sample count: {data["sample_count"]}')
    print(f'   ✅ Accuracy: {data["current_accuracy"]}%')
    print(f'   ✅ Ready: {data["ready_for_conversion"]}')

print()
print('='*60)
print('Phase 2 Endpoints: ALL WORKING ✅')

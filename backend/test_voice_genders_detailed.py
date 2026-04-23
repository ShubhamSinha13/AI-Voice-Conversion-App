import httpx
import json

client = httpx.Client(timeout=60)

# Register test user
print('[1] Registering test user...')
reg = client.post('http://localhost:8000/auth/register', json={
    'email': 'voicegendertest@test.com', 'username': 'voicegendertest', 'password': 'pass123'
})
print(f'Register: {reg.status_code}')

# Login
print('[2] Logging in...')
login = client.post('http://localhost:8000/auth/login', json={
    'email': 'voicegendertest@test.com', 'password': 'pass123'
})

if login.status_code == 200:
    token = login.json()['access_token']
    print(f'Login: OK')
    
    # Get all voices metadata
    print('\n[3] Fetching voice metadata...')
    voices_resp = client.get('http://localhost:8000/api/voices/predefined')
    
    if voices_resp.status_code == 200:
        voices = voices_resp.json()
        
        print('\n' + '='*80)
        print('Voice Preview Test - Check Genders and Quality')
        print('='*80)
        
        for voice in voices[:12]:
            vid = voice.get('id')
            name = voice.get('name')
            voice_type = voice.get('type')
            
            print(f'\n[Voice {vid}] {name} ({voice_type.upper()})')
            print('-' * 80)
            
            # Get preview
            preview = client.get(
                f'http://localhost:8000/api/voices/{vid}/preview',
                headers={'Authorization': f'Bearer {token}'}
            )
            
            if preview.status_code == 200:
                size = len(preview.content)
                print(f'✓ Generated: {size} bytes')
                print(f'  Status: {preview.status_code}')
                print(f'  Content-Type: {preview.headers.get("content-type", "unknown")}')
                print(f'  Expected Gender: {voice_type}')
                print(f'  ACTION: Listen and verify this voice sounds like {voice_type}!')
            else:
                print(f'✗ Error: {preview.status_code}')
                print(f'  Message: {preview.text[:150]}')
        
        print('\n' + '='*80)
        print('Please listen to the generated audio files and verify:')
        print('1. Male voices (1,3,5,7,9,11) sound like males')
        print('2. Female voices (2,4,6,8,10,12) sound like females')
        print('3. No cracking or quality issues')
        print('='*80)
    else:
        print(f'Error fetching voices: {voices_resp.status_code}')
else:
    print(f'Login failed: {login.status_code}')

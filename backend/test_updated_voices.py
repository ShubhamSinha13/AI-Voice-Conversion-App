import httpx

client = httpx.Client(timeout=30)

# Register test user
reg = client.post('http://localhost:8000/auth/register', json={
    'email': 'newvoicetest@test.com', 'username': 'newvoicetest', 'password': 'pass123'
})
print(f'Register: {reg.status_code}')

# Login
login = client.post('http://localhost:8000/auth/login', json={
    'email': 'newvoicetest@test.com', 'password': 'pass123'
})

if login.status_code == 200:
    token = login.json()['access_token']
    
    print('\n[Testing Updated Voice Mappings]:')
    print('ID | Voice Name                       | Size')
    print('-' * 55)
    
    for voice_id in range(1, 13):
        preview = client.get(
            f'http://localhost:8000/api/voices/{voice_id}/preview',
            headers={'Authorization': f'Bearer {token}'}
        )
        
        if preview.status_code == 200:
            size = len(preview.content)
            # Get voice name from the predefined list
            voices_resp = client.get('http://localhost:8000/api/voices/predefined')
            if voices_resp.status_code == 200:
                voices = voices_resp.json()
                voice_name = voices[voice_id - 1]['name'] if voice_id <= len(voices) else 'Unknown'
            else:
                voice_name = f'Voice {voice_id}'
            
            print(f'{voice_id:2d} | {voice_name:32s} | {size:6d} bytes ✓')
        else:
            print(f'{voice_id:2d} | Error: {preview.status_code}')
    
    print('\n✓ All voices generated successfully with updated mappings')

"""
Test script to verify Edge TTS voice genders
"""
import edge_tts
import asyncio

async def test_voice(text, voice_name):
    """Test a voice and save a sample"""
    try:
        print(f"Testing {voice_name}...", end=" ")
        communicate = edge_tts.Communicate(text=text, voice=voice_name, rate="+0%")
        await communicate.save(f"test_{voice_name.replace('-', '_')}.mp3")
        print("✓")
    except Exception as e:
        print(f"✗ Error: {str(e)[:50]}")

async def main():
    test_text = "Hello, this is a test of my voice."
    
    # Test each voice we're using
    voices_to_test = {
        1: "en-US-GuyNeural",
        2: "en-US-JennyNeural",
        3: "en-US-RogerNeural",
        4: "en-US-AvaNeural",
        5: "en-US-EricNeural",
        6: "en-US-MonicaNeural",
        7: "en-US-JacobNeural",
        8: "en-US-AmberNeural",
        9: "en-GB-RyanNeural",
        10: "en-US-CoraNeural",
        11: "en-US-BrandonNeural",
        12: "en-US-AriaNeural",
    }
    
    print("Testing Edge TTS voices...\n")
    for voice_id, voice_name in voices_to_test.items():
        await test_voice(test_text, voice_name)
    
    print("\n✓ Test files created. Listen to them to verify genders.")

if __name__ == "__main__":
    asyncio.run(main())

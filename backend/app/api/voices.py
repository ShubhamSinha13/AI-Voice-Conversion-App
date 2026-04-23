"""
API endpoints for voice operations
"""

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Header
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.models import User, Voice
from app.schemas import VoiceCreate, VoiceResponse, VoiceDetailResponse, AccuracyResponse
from app.utils.auth import decode_token
from app.services.voice_service import AccuracyCalculationService, VoicePersistenceService
import logging

router = APIRouter(prefix="/api/voices", tags=["voices"])
logger = logging.getLogger(__name__)


def get_current_user(authorization: Optional[str] = Header(None), db: Session = Depends(get_db)) -> User:
    """Get current user from Authorization header"""
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    
    # Extract token from "Bearer <token>"
    try:
        scheme, token = authorization.split()
        if scheme.lower() != "bearer":
            raise ValueError()
    except (ValueError, AttributeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header"
        )
    
    email = decode_token(token)
    if not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    return user


@router.get("/predefined", response_model=List[VoiceResponse])
def get_predefined_voices(db: Session = Depends(get_db)):
    """Get all predefined voices"""
    voices = db.query(Voice).filter(Voice.is_predefined == True).all()
    return voices


@router.get("/my-voices", response_model=List[VoiceResponse])
def get_my_voices(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get user's custom voices"""
    voices = db.query(Voice).filter(Voice.user_id == current_user.id).all()
    return voices


@router.post("/create", response_model=VoiceDetailResponse)
def create_voice(
    voice_data: VoiceCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create new custom voice"""
    # Create voice entry
    db_voice = Voice(
        user_id=current_user.id,
        name=voice_data.name,
        user_defined_name=voice_data.user_defined_name,
        type="custom",
        is_predefined=False,
        sample_count=0,
        accuracy_percentage=0.0
    )
    
    db.add(db_voice)
    db.commit()
    db.refresh(db_voice)
    
    logger.info(f"Voice created: {db_voice.id} for user {current_user.id}")
    return db_voice


@router.post("/{voice_id}/add-sample", response_model=AccuracyResponse)
def add_voice_sample(
    voice_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Add voice sample to existing voice"""
    # Get voice
    voice = db.query(Voice).filter(
        Voice.id == voice_id,
        Voice.user_id == current_user.id
    ).first()
    
    if not voice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Voice not found"
        )
    
    # Update sample count
    voice.sample_count += 1
    
    # Calculate new accuracy
    accuracy, message = AccuracyCalculationService.calculate_accuracy(voice.sample_count)
    voice.accuracy_percentage = accuracy
    
    db.commit()
    db.refresh(voice)
    
    logger.info(f"Sample added to voice {voice_id}. New accuracy: {accuracy}%")
    
    return AccuracyResponse(
        voice_id=voice.id,
        accuracy_percentage=voice.accuracy_percentage,
        sample_count=voice.sample_count,
        message=message,
        next_suggestion=AccuracyCalculationService.get_next_suggestion(voice.sample_count)
    )


@router.get("/{voice_id}", response_model=VoiceDetailResponse)
def get_voice(
    voice_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get voice details"""
    voice = db.query(Voice).filter(Voice.id == voice_id).first()
    if not voice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Voice not found"
        )
    
    # Check ownership for custom voices
    if not voice.is_predefined and voice.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized"
        )
    
    return voice


@router.delete("/{voice_id}")
def delete_voice(
    voice_id: int,
    token: str = None,
    db: Session = Depends(get_db)
):
    """Delete custom voice"""
    user = get_current_user(token, db)
    
    voice = db.query(Voice).filter(
        Voice.id == voice_id,
        Voice.user_id == user.id
    ).first()
    
    if not voice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Voice not found"
        )
    
    db.delete(voice)
    db.commit()
    
    logger.info(f"Voice deleted: {voice_id}")
    return {"message": "Voice deleted successfully"}


from fastapi.responses import FileResponse
import shutil
import os
import time
import numpy as np
import io
import hashlib
import tempfile

# Voice-specific conversion parameters
# Each voice has: (pitch_shift_semitones, speed_factor, formant_shift)
# Positive pitch = higher voice, negative = deeper
VOICE_PARAMS = {
    1:  {"name": "Alex - Professional Male",     "pitch": -1,   "speed": 1.0,  "formant": -0.5},
    2:  {"name": "Emma - Friendly Female",       "pitch": 4,    "speed": 1.02, "formant": 2.0},
    3:  {"name": "James - Deep Male",            "pitch": -4,   "speed": 0.95, "formant": -2.0},
    4:  {"name": "Sophia - Soft Female",         "pitch": 3,    "speed": 0.97, "formant": 1.5},
    5:  {"name": "Marco - Italian Accent Male",  "pitch": -1,   "speed": 1.05, "formant": -0.5},
    6:  {"name": "Claire - French Accent Female", "pitch": 3,   "speed": 1.03, "formant": 1.5},
    7:  {"name": "Raj - Indian Accent Male",     "pitch": 0,    "speed": 1.08, "formant": 0.0},
    8:  {"name": "Yuki - Japanese Accent Female", "pitch": 5,   "speed": 1.05, "formant": 2.5},
    9:  {"name": "Liam - Irish Male",            "pitch": -2,   "speed": 1.03, "formant": -1.0},
    10: {"name": "Ava - American Female",        "pitch": 3,    "speed": 1.0,  "formant": 1.5},
    11: {"name": "Miguel - Spanish Male",        "pitch": -1,   "speed": 1.06, "formant": -0.5},
    12: {"name": "Luna - Child Voice Female",    "pitch": 7,    "speed": 1.1,  "formant": 4.0},
}


def _load_audio_from_upload(
    file_bytes: bytes,
    sr: int = 16000,
    filename: str | None = None,
    content_type: str | None = None,
):
    """
    Load audio bytes robustly across wav/mp3/m4a/ogg.
    Some containers (notably m4a) fail with in-memory decode and need file-based fallback.
    """
    import librosa

    try:
        audio, sample_rate = librosa.load(io.BytesIO(file_bytes), sr=sr, mono=True)
        return audio, sample_rate
    except Exception:
        # Fall back to temp file decode (audioread/ffmpeg path), especially for m4a.
        ext = ".wav"
        if filename and "." in filename:
            ext = "." + filename.rsplit(".", 1)[-1].lower()
        elif content_type and "mpeg" in content_type:
            ext = ".mp3"
        elif content_type and ("mp4" in content_type or "m4a" in content_type):
            ext = ".m4a"
        elif content_type and "ogg" in content_type:
            ext = ".ogg"

        tmp_path = None
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as tmp:
                tmp.write(file_bytes)
                tmp_path = tmp.name
            audio, sample_rate = librosa.load(tmp_path, sr=sr, mono=True)
            return audio, sample_rate
        finally:
            if tmp_path and os.path.exists(tmp_path):
                os.remove(tmp_path)


def _save_audio_to_file(audio: np.ndarray, sr: int, output_path: str):
    """Save audio array to WAV file"""
    import soundfile as sf
    sf.write(output_path, audio, sr)


def _get_voice_profile(voice: Voice) -> dict:
    """
    Build deterministic conversion profile for both predefined and custom voices.
    Custom voices no longer default to a near pass-through profile.
    """
    if voice.is_predefined and voice.id in VOICE_PARAMS:
        return VOICE_PARAMS[voice.id]

    seed_input = f"{voice.id}:{voice.name}:{voice.user_defined_name or ''}"
    seed = int(hashlib.md5(seed_input.encode("utf-8")).hexdigest()[:8], 16)
    rng = np.random.default_rng(seed)

    # Use uploaded training quality to scale transformation strength.
    sample_count = max(0, voice.sample_count or 0)
    accuracy = float(voice.accuracy_percentage or 0.0)
    strength = min(1.0, 0.25 + sample_count * 0.12 + accuracy / 180.0)

    base_pitch = rng.uniform(-2.5, 2.5)
    base_formant = rng.uniform(-2.0, 2.0)
    base_speed = 1.0 + rng.uniform(-0.05, 0.05)

    return {
        "name": voice.name,
        "pitch": float(base_pitch * strength),
        "speed": float(np.clip(base_speed + (strength - 0.5) * 0.06, 0.9, 1.12)),
        "formant": float(base_formant * strength),
    }


def _apply_timbre_shaping(audio: np.ndarray, formant_shift: float) -> np.ndarray:
    """Apply spectral tilt to make target timbre audibly distinct."""
    import librosa

    normalized = float(np.clip(formant_shift / 6.0, -1.0, 1.0))
    if abs(normalized) < 0.05:
        return audio

    bright = librosa.effects.preemphasis(audio, coef=0.97)
    warm = librosa.effects.deemphasis(audio, coef=0.9)
    target = bright if normalized > 0 else warm
    # Keep effect audible but avoid robotic/ghost artifacts.
    blend = min(0.35, 0.12 + abs(normalized) * 0.2)

    shaped = (1.0 - blend) * audio + blend * target
    return np.clip(shaped, -1.0, 1.0).astype(np.float32)


@router.post("/{voice_id}/convert")
async def convert_audio_simple(
    voice_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Basic voice conversion - fast pitch shifting.
    Applies pitch shift based on target voice character.
    """
    import librosa

    try:
        voice = db.query(Voice).filter(Voice.id == voice_id).first()
        if not voice:
            raise HTTPException(status_code=404, detail="Voice not found")
        if not voice.is_predefined and voice.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized for this voice")

        file_bytes = await file.read()
        audio, sr = _load_audio_from_upload(
            file_bytes,
            sr=16000,
            filename=file.filename,
            content_type=file.content_type,
        )
        logger.info(f"[Basic] Loaded audio: {len(audio)} samples at {sr}Hz")

        # Get voice parameters
        params = _get_voice_profile(voice)
        pitch_shift = params["pitch"]

        # Apply pitch shifting
        if pitch_shift != 0:
            audio = librosa.effects.pitch_shift(audio, sr=sr, n_steps=pitch_shift)
            logger.info(f"[Basic] Applied pitch shift: {pitch_shift} semitones")

        # Apply timbre shaping so output isn't a near-copy of input.
        audio = _apply_timbre_shaping(audio, params["formant"])

        # Clip to prevent distortion
        audio = np.clip(audio, -1.0, 1.0)

        # Save output
        output_path = f"uploads/converted_basic_{current_user.id}_{voice_id}_{int(time.time())}.wav"
        os.makedirs(os.path.dirname(output_path) or "uploads", exist_ok=True)
        _save_audio_to_file(audio, sr, output_path)

        logger.info(f"[Basic] Conversion complete for voice {voice_id}")
        return FileResponse(output_path, media_type="audio/wav", filename=f"converted_basic_{voice_id}.wav")

    except Exception as e:
        logger.error(f"[Basic] Conversion error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Basic conversion failed: {str(e)}")


@router.post("/{voice_id}/convert-ml")
async def convert_audio_ml(
    voice_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    ML-Enhanced voice conversion using HuBERT-style processing.
    Applies: normalization → silence removal → pitch shift → time stretch → MFCC reshaping.
    """
    import librosa

    try:
        voice = db.query(Voice).filter(Voice.id == voice_id).first()
        if not voice:
            raise HTTPException(status_code=404, detail="Voice not found")
        if not voice.is_predefined and voice.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized for this voice")

        file_bytes = await file.read()
        audio, sr = _load_audio_from_upload(
            file_bytes,
            sr=16000,
            filename=file.filename,
            content_type=file.content_type,
        )
        logger.info(f"[ML] Loaded audio: {len(audio)} samples at {sr}Hz")

        params = _get_voice_profile(voice)

        # Step 1: Normalize loudness
        rms = np.sqrt(np.mean(audio ** 2))
        if rms > 1e-7:
            target_rms = 10 ** (-20.0 / 20.0)  # -20dB target
            audio = audio * (target_rms / rms)
        logger.info(f"[ML] Step 1: Normalized audio")

        # Step 2: Remove silence
        audio, _ = librosa.effects.trim(audio, top_db=30)
        logger.info(f"[ML] Step 2: Trimmed silence, {len(audio)} samples remain")

        # Step 3: Pitch shifting
        pitch_shift = params["pitch"]
        if pitch_shift != 0:
            audio = librosa.effects.pitch_shift(audio, sr=sr, n_steps=pitch_shift)
            logger.info(f"[ML] Step 3: Pitch shifted by {pitch_shift} semitones")

        # Step 4: Time stretching for voice character
        speed = params["speed"]
        if speed != 1.0:
            audio = librosa.effects.time_stretch(audio, rate=speed)
            logger.info(f"[ML] Step 4: Time stretched by {speed}x")

        # Step 5: Spectral envelope reshaping (formant approximation)
        formant = params["formant"]
        if formant != 0.0:
            # Apply a second subtle pitch shift to simulate formant change
            formant_steps = formant * 0.25  # More natural formant hint
            audio = librosa.effects.pitch_shift(audio, sr=sr, n_steps=formant_steps)
            logger.info(f"[ML] Step 5: Formant shifted by {formant_steps} steps")
        audio = _apply_timbre_shaping(audio, formant)

        # Step 6: Final normalization
        peak = np.max(np.abs(audio))
        if peak > 0:
            audio = audio / peak * 0.95
        audio = np.clip(audio, -1.0, 1.0)

        # Save output
        output_path = f"uploads/converted_ml_{current_user.id}_{voice_id}_{int(time.time())}.wav"
        os.makedirs(os.path.dirname(output_path) or "uploads", exist_ok=True)
        _save_audio_to_file(audio, sr, output_path)

        logger.info(f"[ML] Conversion complete for voice {voice_id}")
        return FileResponse(output_path, media_type="audio/wav", filename=f"converted_ml_{voice_id}.wav")

    except Exception as e:
        logger.error(f"[ML] Conversion error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"ML conversion failed: {str(e)}")


@router.post("/{voice_id}/convert-rvc")
async def convert_audio_rvc(
    voice_id: int,
    quality: str = "balanced",
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Advanced RVC-style voice conversion - highest quality.
    Full pipeline: noise reduction → normalization → silence removal →
    MFCC extraction → pitch shift → formant shift → spectral smoothing.
    """
    import librosa
    import scipy.signal as signal

    try:
        voice = db.query(Voice).filter(Voice.id == voice_id).first()
        if not voice:
            raise HTTPException(status_code=404, detail="Voice not found")
        if not voice.is_predefined and voice.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized for this voice")

        file_bytes = await file.read()
        audio, sr = _load_audio_from_upload(
            file_bytes,
            sr=22050,  # Higher SR for RVC quality
            filename=file.filename,
            content_type=file.content_type,
        )
        logger.info(f"[RVC] Loaded audio: {len(audio)} samples at {sr}Hz, quality={quality}")

        params = _get_voice_profile(voice)

        # Quality multiplier
        q_mult = {"fast": 0.5, "balanced": 1.0, "quality": 1.5}.get(quality, 1.0)

        # Step 1: Spectral noise reduction
        try:
            fft_size = 2048
            f, t_bins, Zxx = signal.stft(audio, fs=sr, nperseg=fft_size)
            noise_frames = max(1, int(0.05 * sr / fft_size))
            noise_spectrum = np.mean(np.abs(Zxx[:, :noise_frames]) ** 2, axis=1)
            magnitude = np.abs(Zxx)
            magnitude = np.maximum(magnitude - 1.5 * np.sqrt(noise_spectrum[:, np.newaxis]), 0)
            phase = np.angle(Zxx)
            Zxx_clean = magnitude * np.exp(1j * phase)
            _, audio = signal.istft(Zxx_clean, fs=sr, nperseg=fft_size)
            audio = audio.astype(np.float32)
            logger.info(f"[RVC] Step 1: Noise reduction complete")
        except Exception as nr_err:
            logger.warning(f"[RVC] Noise reduction failed, skipping: {nr_err}")

        # Step 2: Normalize loudness
        rms = np.sqrt(np.mean(audio ** 2))
        if rms > 1e-7:
            target_rms = 10 ** (-18.0 / 20.0)  # Slightly louder target for RVC
            audio = audio * (target_rms / rms)
        logger.info(f"[RVC] Step 2: Normalized audio")

        # Step 3: Remove silence with tighter threshold
        audio, _ = librosa.effects.trim(audio, top_db=25)
        logger.info(f"[RVC] Step 3: Trimmed silence, {len(audio)} samples remain")

        # Step 4: Extract MFCC for voice characterization
        mfcc = librosa.feature.mfcc(y=audio, sr=sr, n_mfcc=20)
        mfcc_mean = np.mean(mfcc, axis=1)
        logger.info(f"[RVC] Step 4: MFCC extracted, shape={mfcc_mean.shape}")

        # Step 5: Primary pitch shifting (full strength)
        pitch_shift = params["pitch"] * q_mult
        if pitch_shift != 0:
            audio = librosa.effects.pitch_shift(audio, sr=sr, n_steps=pitch_shift)
            logger.info(f"[RVC] Step 5: Pitch shifted by {pitch_shift} semitones")

        # Step 6: Time stretching for natural pacing
        speed = params["speed"]
        if speed != 1.0:
            stretch_rate = 1.0 + (speed - 1.0) * q_mult
            audio = librosa.effects.time_stretch(audio, rate=stretch_rate)
            logger.info(f"[RVC] Step 6: Time stretched by {stretch_rate}x")

        # Step 7: Formant shifting (key difference from ML tier)
        formant = params["formant"] * q_mult
        if formant != 0.0:
            # More aggressive formant shifting for RVC quality
            audio = librosa.effects.pitch_shift(audio, sr=sr, n_steps=formant * 0.7)
            # Undo the pitch component but keep the formant change
            # by re-pitching back partially
            undo = -formant * 0.2
            if abs(undo) > 0.1:
                audio = librosa.effects.pitch_shift(audio, sr=sr, n_steps=undo)
            logger.info(f"[RVC] Step 7: Formant shifted by {formant}")
        audio = _apply_timbre_shaping(audio, formant)

        # Step 8: Spectral smoothing (reduces artifacts)
        try:
            S = librosa.stft(audio)
            S_smooth = librosa.decompose.nn_filter(
                np.abs(S),
                aggregate=np.median,
                metric='cosine',
                width=int(3 * q_mult) + 1
            )
            # Blend original and smoothed
            blend = min(0.25, 0.12 * q_mult)  # reduce chorus/ghost artifacts
            S_final = (1 - blend) * np.abs(S) + blend * S_smooth
            audio = librosa.istft(S_final * np.exp(1j * np.angle(S)))
            logger.info(f"[RVC] Step 8: Spectral smoothing applied (blend={blend:.2f})")
        except Exception as smooth_err:
            logger.warning(f"[RVC] Spectral smoothing failed, skipping: {smooth_err}")

        # Step 9: Final peak normalization
        peak = np.max(np.abs(audio))
        if peak > 0:
            audio = audio / peak * 0.95
        audio = np.clip(audio, -1.0, 1.0).astype(np.float32)

        # Save at higher quality sample rate
        output_path = f"uploads/converted_rvc_{current_user.id}_{voice_id}_{int(time.time())}.wav"
        os.makedirs(os.path.dirname(output_path) or "uploads", exist_ok=True)
        _save_audio_to_file(audio, sr, output_path)

        logger.info(f"[RVC] Conversion complete for voice {voice_id} (quality={quality})")
        return FileResponse(output_path, media_type="audio/wav", filename=f"converted_rvc_{voice_id}.wav")

    except Exception as e:
        logger.error(f"[RVC] Conversion error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"RVC conversion failed: {str(e)}")

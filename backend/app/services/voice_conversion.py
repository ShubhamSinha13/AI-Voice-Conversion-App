"""
Voice conversion service for real-time voice transformation
"""
import numpy as np
import logging
from typing import Tuple, Optional
import librosa
import soundfile as sf
import io
from pathlib import Path
from datetime import datetime

logger = logging.getLogger(__name__)


class AudioProcessingService:
    """Service for audio processing and normalization"""
    
    @staticmethod
    def load_audio(file_path: str, sr: int = 16000) -> Tuple[np.ndarray, int]:
        """
        Load audio file
        
        Args:
            file_path: Path to audio file
            sr: Target sample rate
            
        Returns:
            Tuple of (audio_data, sample_rate)
        """
        try:
            audio, sr = librosa.load(file_path, sr=sr, mono=True)
            logger.info(f"Loaded audio: {len(audio)} samples at {sr}Hz")
            return audio, sr
        except Exception as e:
            logger.error(f"Error loading audio: {e}")
            raise
    
    @staticmethod
    def load_audio_from_bytes(audio_bytes: bytes, sr: int = 16000) -> Tuple[np.ndarray, int]:
        """Load audio from bytes"""
        try:
            audio, sr = librosa.load(io.BytesIO(audio_bytes), sr=sr, mono=True)
            logger.info(f"Loaded audio from bytes: {len(audio)} samples at {sr}Hz")
            return audio, sr
        except Exception as e:
            logger.error(f"Error loading audio from bytes: {e}")
            raise
    
    @staticmethod
    def normalize_audio(audio: np.ndarray, target_db: float = -20.0) -> np.ndarray:
        """
        Normalize audio to target loudness
        
        Args:
            audio: Audio samples
            target_db: Target loudness in dB
            
        Returns:
            Normalized audio
        """
        # Remove silence/padding
        audio = librosa.effects.trim(audio, top_db=30)[0]
        
        # Calculate current loudness
        S = librosa.feature.melspectrogram(y=audio)
        S_db = librosa.power_to_db(S, ref=np.max)
        current_db = np.mean(S_db)
        
        # Apply gain
        gain = 10 ** ((target_db - current_db) / 20.0)
        audio = audio * gain
        
        # Clip to prevent clipping
        audio = np.clip(audio, -1.0, 1.0)
        
        logger.info(f"Normalized audio: {current_db:.1f}dB -> {target_db:.1f}dB")
        return audio
    
    @staticmethod
    def remove_silence(audio: np.ndarray, sample_rate: int = 16000, threshold_db: float = 40) -> np.ndarray:
        """
        Remove silence from audio
        
        Args:
            audio: Audio samples
            sample_rate: Sample rate
            threshold_db: Silence threshold
            
        Returns:
            Audio without silence
        """
        audio = librosa.effects.trim(audio, top_db=threshold_db)[0]
        logger.info(f"Removed silence: {len(audio)} samples remaining")
        return audio
    
    @staticmethod
    def resample_audio(audio: np.ndarray, orig_sr: int, target_sr: int) -> Tuple[np.ndarray, int]:
        """Resample audio to target sample rate"""
        if orig_sr != target_sr:
            audio = librosa.resample(audio, orig_sr=orig_sr, target_sr=target_sr)
            logger.info(f"Resampled audio: {orig_sr}Hz -> {target_sr}Hz")
        return audio, target_sr
    
    @staticmethod
    def save_audio(audio: np.ndarray, output_path: str, sample_rate: int = 16000):
        """Save audio to file"""
        sf.write(output_path, audio, sample_rate)
        logger.info(f"Saved audio to {output_path}")
    
    @staticmethod
    def audio_to_bytes(audio: np.ndarray, sample_rate: int = 16000, format: str = 'wav') -> bytes:
        """Convert audio to bytes"""
        output = io.BytesIO()
        sf.write(output, audio, sample_rate, format=format)
        output.seek(0)
        return output.getvalue()
    
    @staticmethod
    def apply_noise_reduction(
        audio: np.ndarray,
        sample_rate: int = 16000,
        fft_size: int = 2048
    ) -> np.ndarray:
        """
        Apply noise reduction using spectral subtraction
        
        Args:
            audio: Audio samples
            sample_rate: Sample rate in Hz
            fft_size: FFT size for analysis
            
        Returns:
            Noise-reduced audio
        """
        try:
            import scipy.signal as signal
            
            # Compute STFT
            f, t, Zxx = signal.stft(audio, fs=sample_rate, nperseg=fft_size)
            
            # Simple noise estimation from first 50ms
            noise_duration = int(0.05 * sample_rate / fft_size)
            noise_spectrum = np.mean(np.abs(Zxx[:, :noise_duration]) ** 2, axis=1)
            
            # Spectral subtraction
            magnitude = np.abs(Zxx)
            magnitude = np.maximum(magnitude - 2 * np.sqrt(noise_spectrum[:, np.newaxis]), 0)
            
            # Reconstruct phase
            phase = np.angle(Zxx)
            Zxx_denoised = magnitude * np.exp(1j * phase)
            
            # ISTFT
            _, denoised_audio = signal.istft(Zxx_denoised, fs=sample_rate, nperseg=fft_size)
            
            return denoised_audio.astype(np.float32)
        
        except Exception as e:
            logger.error(f"Error reducing noise: {e}")
            return audio


class VoiceConversionService:
    """Service for voice conversion"""
    
    @staticmethod
    def extract_speaker_embedding(audio: np.ndarray, sample_rate: int = 16000) -> np.ndarray:
        """
        Extract speaker embedding from audio
        
        For now, returns MFCC-based embedding. Will be replaced with actual HuBERT
        
        Args:
            audio: Audio samples
            sample_rate: Sample rate in Hz
            
        Returns:
            Speaker embedding (512-dim vector)
        """
        # Placeholder: Extract MFCC features as embedding
        mfcc = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=13)
        # Average across time and pad/truncate to 512 dims
        mfcc_mean = np.mean(mfcc, axis=1)  # (13,)
        embedding = np.zeros(512, dtype=np.float32)
        embedding[:13] = mfcc_mean
        
        logger.info(f"Extracted embedding shape: {embedding.shape}")
        return embedding
    
    @staticmethod
    def convert_voice(
        audio: np.ndarray,
        source_embedding: np.ndarray,
        target_embedding: np.ndarray,
        sample_rate: int = 16000,
        f0_shift: int = 0
    ) -> np.ndarray:
        """
        Convert voice from source to target speaker
        
        For now, applies pitch shift. Will use actual RVC model
        
        Args:
            audio: Input audio
            source_embedding: Source speaker embedding
            target_embedding: Target speaker embedding
            sample_rate: Sample rate in Hz
            f0_shift: Pitch shift in semitones
            
        Returns:
            Converted audio
        """
        try:
            converted = audio.copy()
            
            # Apply pitch shifting if requested
            if f0_shift != 0:
                converted = librosa.effects.pitch_shift(converted, sr=sample_rate, n_steps=f0_shift)
                logger.info(f"Applied pitch shift: {f0_shift} semitones")
            
            # Normalize
            converted = AudioProcessingService.normalize_audio(converted)
            
            logger.info(f"Voice conversion complete: {len(converted)} samples")
            return converted
        except Exception as e:
            logger.error(f"Error in voice conversion: {e}")
            raise
    
    @staticmethod
    def full_conversion_pipeline(
        audio_bytes: bytes,
        voice_id: int,
        sample_rate: int = 16000,
        f0_shift: int = 0
    ) -> bytes:
        """
        Complete voice conversion pipeline
        
        Args:
            audio_bytes: Input audio as bytes
            voice_id: Target voice ID
            sample_rate: Sample rate
            f0_shift: Pitch shift in semitones
            
        Returns:
            Converted audio as bytes
        """
        try:
            # 1. Load audio
            audio, sr = AudioProcessingService.load_audio_from_bytes(audio_bytes, sr=sample_rate)
            logger.info(f"[1/5] Audio loaded: {len(audio)} samples")
            
            # 2. Normalize
            audio = AudioProcessingService.normalize_audio(audio)
            logger.info(f"[2/5] Audio normalized")
            
            # 3. Remove silence
            audio = AudioProcessingService.remove_silence(audio, sr)
            logger.info(f"[3/5] Silence removed: {len(audio)} samples")
            
            # 4. Extract embeddings
            source_emb = VoiceConversionService.extract_speaker_embedding(audio, sr)
            # Target embedding would come from predefined voice
            target_emb = np.random.randn(512).astype(np.float32)
            logger.info(f"[4/5] Embeddings extracted")
            
            # 5. Convert voice
            converted = VoiceConversionService.convert_voice(
                audio=audio,
                source_embedding=source_emb,
                target_embedding=target_emb,
                sample_rate=sr,
                f0_shift=f0_shift
            )
            logger.info(f"[5/5] Voice converted")
            
            # Save as WAV bytes
            output_bytes = AudioProcessingService.audio_to_bytes(converted, sr, format='wav')
            logger.info(f"Converted audio size: {len(output_bytes)} bytes")
            
            return output_bytes
        except Exception as e:
            logger.error(f"Pipeline error: {e}")
            raise


class RealTimeAudioProcessor:
    """Handle real-time audio streaming and chunked processing"""
    
    def __init__(self, chunk_size: int = 4096, sample_rate: int = 16000):
        self.chunk_size = chunk_size
        self.sample_rate = sample_rate
        self.buffer = np.array([], dtype=np.float32)
    
    def process_chunk(
        self,
        chunk: np.ndarray,
        source_embedding: np.ndarray,
        target_embedding: np.ndarray
    ) -> np.ndarray:
        """
        Process audio chunk for real-time conversion
        
        Args:
            chunk: Audio chunk
            source_embedding: Source speaker embedding
            target_embedding: Target speaker embedding
            
        Returns:
            Converted audio chunk
        """
        try:
            # Add to buffer
            self.buffer = np.concatenate([self.buffer, chunk])
            
            # Process if buffer has enough data
            if len(self.buffer) >= self.chunk_size:
                output = VoiceConversionService.convert_voice(
                    self.buffer[:self.chunk_size],
                    source_embedding,
                    target_embedding,
                    self.sample_rate
                )
                
                # Remove processed chunk from buffer
                self.buffer = self.buffer[self.chunk_size:]
                
                return output
            else:
                return np.array([], dtype=np.float32)
        
        except Exception as e:
            logger.error(f"Error processing chunk: {e}")
            return np.array([], dtype=np.float32)
    
    def flush(self) -> np.ndarray:
        """Flush remaining audio in buffer"""
        if len(self.buffer) > 0:
            output = self.buffer
            self.buffer = np.array([], dtype=np.float32)
            return output
        return np.array([], dtype=np.float32)

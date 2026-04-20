"""
Voice conversion service for real-time voice transformation
"""
import numpy as np
import logging
from typing import Tuple, Optional
from .voice_conversion_models import hubert_extractor, rvc_converter, hifigan_vocoder

logger = logging.getLogger(__name__)


class VoiceConversionService:
    """Service for converting voice from one speaker to another"""
    
    @staticmethod
    def extract_speaker_embedding(audio: np.ndarray, sample_rate: int = 16000) -> np.ndarray:
        """
        Extract speaker embedding from audio
        
        Args:
            audio: Audio samples
            sample_rate: Sample rate in Hz
            
        Returns:
            Speaker embedding (512-dim vector)
        """
        try:
            embedding = hubert_extractor.extract_embedding(audio, sample_rate)
            logger.info(f"Extracted embedding shape: {embedding.shape}")
            return embedding
        except Exception as e:
            logger.error(f"Error extracting embedding: {e}")
            return np.random.randn(512).astype(np.float32)
    
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
            converted = rvc_converter.convert_voice(
                audio,
                source_embedding,
                target_embedding,
                sample_rate,
                f0_shift
            )
            logger.info(f"Voice conversion completed: {converted.shape}")
            return converted
        except Exception as e:
            logger.error(f"Error converting voice: {e}")
            return audio
    
    @staticmethod
    def synthesize_audio(
        acoustic_features: np.ndarray,
        sample_rate: int = 22050
    ) -> np.ndarray:
        """
        Synthesize audio from acoustic features using HiFi-GAN
        
        Args:
            acoustic_features: Mel-spectrogram or acoustic features
            sample_rate: Output sample rate
            
        Returns:
            Synthesized audio
        """
        try:
            audio = hifigan_vocoder.synthesize(acoustic_features, sample_rate)
            logger.info(f"Audio synthesis completed: {audio.shape}")
            return audio
        except Exception as e:
            logger.error(f"Error synthesizing audio: {e}")
            return np.zeros(22050).astype(np.float32)


class AudioProcessingService:
    """Audio preprocessing and postprocessing"""
    
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
        # Calculate RMS
        rms = np.sqrt(np.mean(audio ** 2))
        
        # Avoid division by zero
        if rms < 1e-7:
            return audio
        
        # Convert target dB to linear
        target_linear = 10 ** (target_db / 20.0)
        
        # Apply gain
        return (audio / rms) * target_linear
    
    @staticmethod
    def remove_silence(
        audio: np.ndarray,
        threshold: float = 0.01,
        min_duration: int = 512
    ) -> np.ndarray:
        """
        Remove silence from audio
        
        Args:
            audio: Audio samples
            threshold: Silence threshold (0-1)
            min_duration: Minimum audio duration to keep (samples)
            
        Returns:
            Audio with silence removed
        """
        # Simple silence detection
        energy = np.abs(audio)
        
        # Find non-silent frames
        non_silent = energy > threshold
        
        # Find edges
        edges = np.diff(non_silent.astype(int))
        
        # Get start and end indices
        starts = np.where(edges == 1)[0]
        ends = np.where(edges == -1)[0]
        
        if len(starts) == 0:
            return audio
        
        # Combine segments
        segments = []
        for start, end in zip(starts, ends):
            if end - start >= min_duration:
                segments.append(audio[start:end])
        
        if segments:
            return np.concatenate(segments)
        else:
            return audio
    
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
    
    @staticmethod
    def resample_audio(
        audio: np.ndarray,
        orig_sr: int,
        target_sr: int
    ) -> np.ndarray:
        """
        Resample audio to target sample rate
        
        Args:
            audio: Audio samples
            orig_sr: Original sample rate
            target_sr: Target sample rate
            
        Returns:
            Resampled audio
        """
        if orig_sr == target_sr:
            return audio
        
        try:
            import librosa
            return librosa.resample(audio, sr=orig_sr, target_sr=target_sr).astype(np.float32)
        except:
            logger.warning("librosa not available, using scipy resample")
            from scipy import signal
            
            num_samples = int(len(audio) * target_sr / orig_sr)
            return signal.resample(audio, num_samples).astype(np.float32)


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

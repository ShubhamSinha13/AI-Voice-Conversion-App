package com.voiceconverter.app

import android.app.Service
import android.content.Intent
import android.media.*
import android.os.Binder
import android.os.IBinder
import android.util.Log
import java.io.IOException

/**
 * Audio capture service for intercepting call audio
 * Captures microphone input and speaker output for voice conversion
 */
class AudioCaptureService : Service() {
    
    companion object {
        private const val TAG = "AudioCaptureService"
        private const val SAMPLE_RATE = 16000
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        private val MIN_BUFFER_SIZE = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            CHANNEL_CONFIG,
            AUDIO_FORMAT
        )
    }
    
    private val binder = AudioCaptureBinder()
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var isRecording = false
    private var audioBuffer = ByteArray(MIN_BUFFER_SIZE)
    
    inner class AudioCaptureBinder : Binder() {
        fun getService(): AudioCaptureService = this@AudioCaptureService
    }
    
    override fun onBind(intent: Intent): IBinder {
        return binder
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AudioCaptureService created")
        initializeAudioRecording()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopCapture()
        Log.d(TAG, "AudioCaptureService destroyed")
    }
    
    /**
     * Initialize audio recording from microphone
     */
    private fun initializeAudioRecording() {
        try {
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.VOICE_COMMUNICATION,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                MIN_BUFFER_SIZE * 2
            )
            
            Log.d(TAG, "AudioRecord initialized - State: ${audioRecord?.state}")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing AudioRecord: ${e.message}")
        }
    }
    
    /**
     * Start capturing audio
     */
    fun startCapture() {
        try {
            audioRecord?.startRecording()
            isRecording = true
            Log.d(TAG, "Audio capture started")
            
            // Start audio processing thread
            Thread {
                captureAudioData()
            }.start()
        } catch (e: Exception) {
            Log.e(TAG, "Error starting capture: ${e.message}")
        }
    }
    
    /**
     * Stop capturing audio
     */
    fun stopCapture() {
        try {
            isRecording = false
            audioRecord?.stop()
            audioRecord?.release()
            audioTrack?.stop()
            audioTrack?.release()
            Log.d(TAG, "Audio capture stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping capture: ${e.message}")
        }
    }
    
    /**
     * Capture audio data in real-time
     */
    private fun captureAudioData() {
        while (isRecording && audioRecord != null) {
            try {
                val bytesRead = audioRecord!!.read(audioBuffer, 0, audioBuffer.size)
                
                if (bytesRead > 0) {
                    // Process audio chunk
                    processAudioChunk(audioBuffer.copyOf(bytesRead))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error capturing audio: ${e.message}")
            }
        }
    }
    
    /**
     * Process audio chunk (convert voice)
     */
    private fun processAudioChunk(audioData: ByteArray) {
        try {
            // TODO: Send to Flutter backend for voice conversion
            // This would involve:
            // 1. Convert ByteArray to PCM samples
            // 2. Extract source embedding
            // 3. Convert to target embedding
            // 4. Synthesize output
            // 5. Play output through speaker
            
            Log.d(TAG, "Processing audio chunk: ${audioData.size} bytes")
            
            // Placeholder: Echo the audio back
            playAudioData(audioData)
        } catch (e: Exception) {
            Log.e(TAG, "Error processing audio: ${e.message}")
        }
    }
    
    /**
     * Play converted audio through speaker
     */
    private fun playAudioData(audioData: ByteArray) {
        try {
            if (audioTrack == null) {
                audioTrack = AudioTrack(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build(),
                    AudioFormat.Builder()
                        .setSampleRate(SAMPLE_RATE)
                        .setEncoding(AUDIO_FORMAT)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build(),
                    MIN_BUFFER_SIZE * 2,
                    AudioTrack.MODE_STREAM,
                    AudioManager.AUDIO_SESSION_ID_GENERATE
                )
                audioTrack?.play()
            }
            
            audioTrack?.write(audioData, 0, audioData.size, AudioTrack.WRITE_BLOCKING)
        } catch (e: Exception) {
            Log.e(TAG, "Error playing audio: ${e.message}")
        }
    }
    
    /**
     * Get current audio level
     */
    fun getAudioLevel(): Int {
        return audioRecord?.let {
            if (it.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                // Simple RMS calculation
                val rms = audioBuffer.indices.sumOf { i ->
                    val sample = audioBuffer[i].toInt() and 0xFF
                    sample * sample
                } / audioBuffer.size
                Math.sqrt(rms.toDouble()).toInt()
            } else {
                0
            }
        } ?: 0
    }
}

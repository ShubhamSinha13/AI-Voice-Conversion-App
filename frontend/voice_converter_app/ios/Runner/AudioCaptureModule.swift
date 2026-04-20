import AVFoundation

/**
 * Audio capture module for iOS
 * Captures microphone input and speaker output using AVAudioEngine
 */
class AudioCaptureModule {
    
    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private var isRecording = false
    
    private var audioConverter: AVAudioConverter?
    private let targetFormat: AVAudioFormat
    
    init() {
        self.inputNode = audioEngine.inputNode
        self.targetFormat = AVAudioFormat(
            standardFormatWithSampleRate: 16000,
            channels: 1
        ) ?? AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!
    }
    
    // MARK: - Audio Capture
    
    /**
     * Start capturing audio from microphone
     */
    func startCapture() {
        do {
            try setupAudioSession()
            try setupAudioEngine()
            
            inputNode.installTap(
                onBus: 0,
                bufferSize: 4096,
                format: inputNode.outputFormat(forBus: 0)
            ) { [weak self] buffer, time in
                self?.processAudioBuffer(buffer, time: time)
            }
            
            try audioEngine.start()
            isRecording = true
            print("✅ Audio capture started")
        } catch {
            print("❌ Error starting audio capture: \(error)")
        }
    }
    
    /**
     * Stop capturing audio
     */
    func stopCapture() {
        audioEngine.stop()
        audioEngine.reset()
        inputNode.removeTap(onBus: 0)
        isRecording = false
        print("✅ Audio capture stopped")
    }
    
    // MARK: - Audio Processing
    
    /**
     * Process audio buffer in real-time
     */
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        // TODO: Send to Flutter backend for voice conversion
        // This would involve:
        // 1. Convert AVAudioPCMBuffer to PCM samples
        // 2. Extract source embedding
        // 3. Convert to target embedding
        // 4. Synthesize output
        // 5. Play output through speaker
        
        guard let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)
        
        // Simple RMS calculation for audio level
        let rms = calculateRMS(channelData[0], length: frameLength)
        print("Audio Level: \(Int(rms * 100))%")
    }
    
    /**
     * Calculate RMS (Root Mean Square) for audio level
     */
    private func calculateRMS(_ samples: UnsafeMutablePointer<Float>, length: Int) -> Float {
        var sum: Float = 0
        for i in 0..<length {
            let sample = samples[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(length))
        return min(rms, 1.0)  // Clamp to 0-1
    }
    
    // MARK: - Audio Engine Setup
    
    /**
     * Setup audio session for voice communication
     */
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.duckOthers, .defaultToSpeaker]
        )
        
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    /**
     * Setup audio engine connections
     */
    private func setupAudioEngine() throws {
        let format = inputNode.outputFormat(forBus: 0) ?? targetFormat
        
        let mainMixer = audioEngine.mainMixerNode
        audioEngine.attach(mainMixer)
        
        audioEngine.connect(
            inputNode,
            to: mainMixer,
            format: format
        )
        
        audioEngine.connect(
            mainMixer,
            to: audioEngine.outputNode,
            format: format
        )
    }
    
    // MARK: - Audio Output
    
    /**
     * Play audio buffer through speaker
     */
    func playAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // In a real implementation, this would use AVAudioPlayerNode
        // to play the converted audio
        print("Playing audio: \(buffer.frameLength) frames")
    }
    
    // MARK: - State
    
    /**
     * Check if currently recording
     */
    func isCapturing() -> Bool {
        return isRecording && audioEngine.isRunning
    }
    
    /**
     * Get audio engine state
     */
    func getEngineState() -> String {
        if audioEngine.isRunning {
            return "Running"
        } else if isRecording {
            return "Initializing"
        } else {
            return "Stopped"
        }
    }
}

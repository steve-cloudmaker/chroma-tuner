import AVFoundation
import Combine

@MainActor
final class AudioManager: ObservableObject {
    @Published var detectedNote: NoteInfo?
    @Published var isListening = false
    @Published var microphoneUnavailable = false
    @Published var selectedNoteIndex = 0
    @Published var selectedOctave = 4
    @Published var isTonePlaying = false
    @Published var a4Reference: Double = MusicTheory.defaultA4
    @Published var inputLevel: Float = 0
    @Published var noiseGateLevel: Float

    private static let defaultNoiseGateLevel: Float = 0.05
    private static let noiseGateLevelKey = "noiseGateLevel"

    private var audioEngine: AVAudioEngine?
    private var pitchDetector: PitchDetector?
    private let pitchStabilizer = PitchStabilizer()
    private let tonePlayer = TonePlayer()
    private var smoothingBuffer: [Double] = []
    private let smoothingWindow = 8
    private var routeChangeObserver: NSObjectProtocol?

    var selectedNoteName: String {
        MusicTheory.noteNames[selectedNoteIndex]
    }

    var selectedFrequency: Double {
        MusicTheory.frequency(noteName: selectedNoteName, octave: selectedOctave, a4: a4Reference)
    }

    var selectedNoteDisplay: String {
        "\(selectedNoteName)\(selectedOctave.subscriptString)"
    }

    var gaugeNoteDisplay: String {
        detectedNote?.displayName ?? selectedNoteDisplay
    }

    var gaugeFrequency: Double {
        detectedNote?.frequency ?? selectedFrequency
    }

    var gaugeCents: Double {
        detectedNote?.cents ?? 0
    }

    init() {
        let savedGate = UserDefaults.standard.float(forKey: Self.noiseGateLevelKey)
        noiseGateLevel = savedGate > 0 ? savedGate : Self.defaultNoiseGateLevel
        pitchStabilizer.noiseGateLevel = noiseGateLevel

        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isListening else { return }
                self.restartListening()
            }
        }
    }

    deinit {
        if let routeChangeObserver {
            NotificationCenter.default.removeObserver(routeChangeObserver)
        }
    }

    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startListening() {
        guard !isListening else { return }
        stopTone()

        do {
            try configureSessionForRecording()
            let session = AVAudioSession.sharedInstance()
            try session.setPreferredSampleRate(44_100)
            try session.setPreferredIOBufferDuration(0.005)

            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let mixerNode = engine.mainMixerNode
            let hwFormat = inputNode.outputFormat(forBus: 0)
            let sampleRate = resolvedSampleRate(hwFormat: hwFormat, session: session)

            guard sampleRate > 0 else {
                microphoneUnavailable = true
                print("Microphone unavailable: invalid sample rate \(hwFormat.sampleRate)")
                return
            }

            let tapFormat: AVAudioFormat
            if hwFormat.sampleRate > 0 && hwFormat.channelCount > 0 {
                tapFormat = hwFormat
            } else if let fallback = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sampleRate,
                channels: 1,
                interleaved: false
            ) {
                tapFormat = fallback
            } else {
                microphoneUnavailable = true
                return
            }

            pitchDetector = PitchDetector(sampleRate: sampleRate)
            pitchStabilizer.reset()
            microphoneUnavailable = false

            // Input must be connected for the graph to pull mic data on device
            engine.connect(inputNode, to: mixerNode, format: tapFormat)
            mixerNode.outputVolume = 0

            inputNode.installTap(onBus: 0, bufferSize: 4096, format: tapFormat) { [weak self] buffer, _ in
                guard let self, let detector = self.pitchDetector else { return }
                let samples = Self.mixedSamples(from: buffer)
                guard !samples.isEmpty else { return }

                let level = Self.level(from: samples)
                let detection = detector.detectPitch(from: samples)

                Task { @MainActor in
                    self.updateInputLevel(level)
                    let result = self.pitchStabilizer.process(
                        frequency: detection?.frequency,
                        inputLevel: self.inputLevel
                    )

                    if result.shouldClearDisplay {
                        self.clearDetectedPitch()
                    } else if let frequency = result.frequency {
                        self.processDetectedFrequency(frequency)
                    }
                }
            }

            engine.prepare()
            try engine.start()
            audioEngine = engine
            isListening = true
        } catch {
            microphoneUnavailable = true
            print("AudioEngine error: \(error)")
        }
    }

    func stopListening() {
        guard let engine = audioEngine else {
            isListening = false
            clearDetectedPitch()
            inputLevel = 0
            pitchStabilizer.reset()
            return
        }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioEngine = nil
        isListening = false
        clearDetectedPitch()
        inputLevel = 0
        pitchStabilizer.reset()
    }

    func restartListening() {
        guard isListening else { return }
        stopListening()
        startListening()
    }

    func toggleTone() {
        if isTonePlaying {
            stopTone()
        } else {
            startTone()
        }
    }

    func startTone() {
        stopListening()

        do {
            let session = try configureSessionForPlayback()
            let sampleRate = session.sampleRate > 0 ? session.sampleRate : 44_100
            let started = tonePlayer.play(frequency: selectedFrequency, sampleRate: sampleRate)
            isTonePlaying = started
            if !started {
                print("TonePlayer failed to start")
            }
        } catch {
            isTonePlaying = false
            print("TonePlayer session error: \(error)")
        }
    }

    func stopTone() {
        tonePlayer.stop()
        isTonePlaying = false
    }

    func updateToneFrequency() {
        if isTonePlaying {
            tonePlayer.updateFrequency(selectedFrequency)
        }
    }

    func selectNote(at index: Int) {
        selectedNoteIndex = ((index % 12) + 12) % 12
        updateToneFrequency()
    }

    func incrementOctave() {
        selectOctave(selectedOctave + 1)
    }

    func decrementOctave() {
        selectOctave(selectedOctave - 1)
    }

    func selectOctave(_ octave: Int) {
        selectedOctave = max(0, min(8, octave))
        updateToneFrequency()
    }

    func setA4Reference(_ frequency: Double) {
        a4Reference = max(400, min(480, frequency.rounded(toPlaces: 1)))
        refreshPitchFromCalibration()
    }

    func resetA4() {
        setA4Reference(MusicTheory.defaultA4)
    }

    func setNoiseGateLevel(_ level: Float) {
        let clamped = max(0.01, min(0.5, level))
        noiseGateLevel = clamped
        pitchStabilizer.noiseGateLevel = clamped
        UserDefaults.standard.set(clamped, forKey: Self.noiseGateLevelKey)
    }

    func resetNoiseGateLevel() {
        setNoiseGateLevel(Self.defaultNoiseGateLevel)
    }

    private func refreshPitchFromCalibration() {
        if let freq = detectedNote?.frequency {
            detectedNote = MusicTheory.noteInfo(fromFrequency: freq, a4: a4Reference)
        }
        updateToneFrequency()
    }

    private func configureSessionForRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try activateSession(session)
    }

    @discardableResult
    private func configureSessionForPlayback() throws -> AVAudioSession {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try activateSession(session)
        return session
    }

    private func activateSession(_ session: AVAudioSession) throws {
        do {
            try session.setActive(true)
        } catch let error as NSError where error.code == 561017449 {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            try session.setActive(true)
        }
    }

    private func resolvedSampleRate(hwFormat: AVAudioFormat, session: AVAudioSession) -> Double {
        if hwFormat.sampleRate > 0 { return hwFormat.sampleRate }
        if session.sampleRate > 0 { return session.sampleRate }
        return 44_100
    }

    private func updateInputLevel(_ instant: Float) {
        inputLevel = inputLevel * 0.55 + instant * 0.45
    }

    private func clearDetectedPitch() {
        detectedNote = nil
        smoothingBuffer.removeAll()
    }

    private func processDetectedFrequency(_ frequency: Double) {
        smoothingBuffer.append(frequency)
        if smoothingBuffer.count > smoothingWindow {
            smoothingBuffer.removeFirst()
        }

        let sorted = smoothingBuffer.sorted()
        let median = sorted[sorted.count / 2]
        detectedNote = MusicTheory.noteInfo(fromFrequency: median, a4: a4Reference)
    }

    private static func mixedSamples(from buffer: AVAudioPCMBuffer) -> [Float] {
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0, let channelData = buffer.floatChannelData else { return [] }

        let channelCount = Int(buffer.format.channelCount)
        var samples = [Float](repeating: 0, count: frameCount)

        for channel in 0..<channelCount {
            let data = channelData[channel]
            for frame in 0..<frameCount {
                samples[frame] += data[frame]
            }
        }

        if channelCount > 1 {
            let scale = 1.0 / Float(channelCount)
            for frame in 0..<frameCount {
                samples[frame] *= scale
            }
        }

        return samples
    }

    private static func level(from samples: [Float]) -> Float {
        var peak: Float = 0
        for sample in samples {
            peak = max(peak, abs(sample))
        }
        guard peak > 0 else { return 0 }

        let db = 20 * log10(peak)
        let normalized = (db + 50) / 50
        return min(1, max(0, normalized))
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}

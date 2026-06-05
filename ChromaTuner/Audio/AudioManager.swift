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

    private var audioEngine: AVAudioEngine?
    private var pitchDetector: PitchDetector?
    private let tonePlayer = TonePlayer()
    private var smoothingBuffer: [Double] = []
    private let smoothingWindow = 5

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

            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let hwFormat = inputNode.outputFormat(forBus: 0)
            let sampleRate = resolvedSampleRate(hwFormat: hwFormat, session: session)

            guard sampleRate > 0,
                  let tapFormat = AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: sampleRate,
                    channels: 1,
                    interleaved: false
                  )
            else {
                microphoneUnavailable = true
                print("Microphone unavailable: invalid audio format (sample rate \(hwFormat.sampleRate))")
                return
            }

            pitchDetector = PitchDetector(sampleRate: sampleRate)
            microphoneUnavailable = false

            inputNode.installTap(onBus: 0, bufferSize: 4096, format: tapFormat) { [weak self] buffer, _ in
                guard let self, let detector = self.pitchDetector else { return }

                let frameCount = Int(buffer.frameLength)
                guard frameCount > 0, let channelData = buffer.floatChannelData?[0] else { return }
                let samples = Array(UnsafeBufferPointer(start: channelData, count: frameCount))

                if let frequency = detector.detectPitch(from: samples) {
                    Task { @MainActor in
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
            detectedNote = nil
            smoothingBuffer.removeAll()
            return
        }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioEngine = nil
        isListening = false
        detectedNote = nil
        smoothingBuffer.removeAll()
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

    func adjustA4(by amount: Double) {
        a4Reference = max(400, min(480, (a4Reference + amount).rounded(toPlaces: amount < 1 ? 1 : 0)))
        if let freq = detectedNote?.frequency {
            detectedNote = MusicTheory.noteInfo(fromFrequency: freq, a4: a4Reference)
        }
        updateToneFrequency()
    }

    func resetA4() {
        a4Reference = MusicTheory.defaultA4
        if let freq = detectedNote?.frequency {
            detectedNote = MusicTheory.noteInfo(fromFrequency: freq, a4: a4Reference)
        }
        updateToneFrequency()
    }

    private func configureSessionForRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
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
            // AVAudioSessionErrorInsufficientPriority — retry after releasing prior engine
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            try session.setActive(true)
        }
    }

    private func resolvedSampleRate(hwFormat: AVAudioFormat, session: AVAudioSession) -> Double {
        if hwFormat.sampleRate > 0 { return hwFormat.sampleRate }
        if session.sampleRate > 0 { return session.sampleRate }
        return 44_100
    }

    private func processDetectedFrequency(_ frequency: Double) {
        smoothingBuffer.append(frequency)
        if smoothingBuffer.count > smoothingWindow {
            smoothingBuffer.removeFirst()
        }

        let averaged = smoothingBuffer.reduce(0, +) / Double(smoothingBuffer.count)
        detectedNote = MusicTheory.noteInfo(fromFrequency: averaged, a4: a4Reference)
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}

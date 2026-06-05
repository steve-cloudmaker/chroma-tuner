import AVFoundation

final class TonePlayer {
    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var currentFrequency: Double = 440.0
    private var phase: Double = 0.0
    private(set) var isPlaying = false

    func play(frequency: Double) {
        stop()
        currentFrequency = frequency

        let engine = AVAudioEngine()
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        let sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let sampleRate = 44100.0
            let angularFrequency = 2.0 * .pi * self.currentFrequency / sampleRate

            for frame in 0..<Int(frameCount) {
                let sample = Float32(sin(self.phase))
                self.phase += angularFrequency
                if self.phase > 2.0 * .pi { self.phase -= 2.0 * .pi }

                for buffer in ablPointer {
                    let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                    buf?[frame] = sample * 0.3
                }
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            self.engine = engine
            self.sourceNode = sourceNode
            isPlaying = true
        } catch {
            print("TonePlayer error: \(error)")
        }
    }

    func updateFrequency(_ frequency: Double) {
        currentFrequency = frequency
    }

    func stop() {
        engine?.stop()
        engine = nil
        sourceNode = nil
        phase = 0.0
        isPlaying = false
    }
}

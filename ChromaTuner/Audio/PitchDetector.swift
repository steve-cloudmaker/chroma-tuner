import AVFoundation

struct PitchDetection {
    let frequency: Double
    let confidence: Float
}

final class PitchDetector {
    private let sampleRate: Double
    private let bufferSize: Int

    init(sampleRate: Double, bufferSize: Int = 2048) {
        self.sampleRate = sampleRate
        self.bufferSize = bufferSize
    }

    func detectPitch(from samples: [Float]) -> PitchDetection? {
        guard samples.count >= bufferSize else { return nil }

        let slice = Array(samples.suffix(bufferSize))
        let filtered = highPass(slice, cutoff: 80)
        let windowed = applyHannWindow(filtered)

        var energy: Float = 0
        for sample in windowed {
            energy += sample * sample
        }
        energy /= Float(windowed.count)

        let rms = sqrt(energy)
        guard rms > 0.004 else { return nil }

        let minLag = Int(sampleRate / 1500.0)
        let maxLag = min(Int(sampleRate / 70.0), windowed.count / 2)
        guard maxLag > minLag else { return nil }

        var peaks: [(lag: Int, correlation: Float)] = []

        for lag in minLag..<maxLag {
            var correlation: Float = 0
            let count = windowed.count - lag
            for i in 0..<count {
                correlation += windowed[i] * windowed[i + lag]
            }
            let normalized = correlation / (energy * Float(count))
            peaks.append((lag, normalized))
        }

        let sorted = peaks.sorted { $0.correlation > $1.correlation }
        guard let best = sorted.first, best.correlation > 0.82 else { return nil }

        if sorted.count > 1 {
            let second = sorted[1]
            guard best.correlation > second.correlation * 1.12 else { return nil }
        }

        let refinedLag = parabolicInterpolation(
            lag: best.lag,
            windowed: windowed,
            minLag: minLag,
            maxLag: maxLag,
            energy: energy
        )

        let frequency = sampleRate / refinedLag
        guard frequency >= 70, frequency <= 1500 else { return nil }

        return PitchDetection(frequency: frequency, confidence: best.correlation)
    }

    private func highPass(_ samples: [Float], cutoff: Double) -> [Float] {
        let rc = 1.0 / (2.0 * .pi * cutoff)
        let dt = 1.0 / sampleRate
        let alpha = Float(rc / (rc + dt))

        var filtered = [Float](repeating: 0, count: samples.count)
        guard let first = samples.first else { return filtered }

        var previousInput = first
        var previousOutput: Float = 0

        for index in 0..<samples.count {
            let input = samples[index]
            let output = alpha * (previousOutput + input - previousInput)
            filtered[index] = output
            previousInput = input
            previousOutput = output
        }

        return filtered
    }

    private func applyHannWindow(_ samples: [Float]) -> [Float] {
        let count = samples.count
        guard count > 1 else { return samples }
        var windowed = [Float](repeating: 0, count: count)
        for i in 0..<count {
            let window = 0.5 * (1.0 - cos(2.0 * .pi * Double(i) / Double(count - 1)))
            windowed[i] = samples[i] * Float(window)
        }
        return windowed
    }

    private func parabolicInterpolation(
        lag: Int,
        windowed: [Float],
        minLag: Int,
        maxLag: Int,
        energy: Float
    ) -> Double {
        guard lag > minLag, lag < maxLag - 1 else { return Double(lag) }

        func normalizedCorrelation(at lag: Int) -> Float {
            var correlation: Float = 0
            let count = windowed.count - lag
            for i in 0..<count {
                correlation += windowed[i] * windowed[i + lag]
            }
            return correlation / (energy * Float(count))
        }

        let y0 = normalizedCorrelation(at: lag - 1)
        let y1 = normalizedCorrelation(at: lag)
        let y2 = normalizedCorrelation(at: lag + 1)

        let denominator = 2.0 * Double(2.0 * y1 - y0 - y2)
        guard abs(denominator) > 1e-6 else { return Double(lag) }

        let offset = Double(y0 - y2) / denominator
        return Double(lag) + offset
    }
}

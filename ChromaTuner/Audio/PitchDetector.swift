import AVFoundation

final class PitchDetector {
    private let sampleRate: Double
    private let bufferSize: Int

    init(sampleRate: Double, bufferSize: Int = 2048) {
        self.sampleRate = sampleRate
        self.bufferSize = bufferSize
    }

    func detectPitch(from samples: [Float]) -> Double? {
        guard samples.count >= bufferSize else { return nil }

        let slice = Array(samples.suffix(bufferSize))
        let windowed = applyHannWindow(slice)

        var energy: Float = 0
        for sample in windowed {
            energy += sample * sample
        }
        energy /= Float(windowed.count)

        let rms = sqrt(energy)
        guard rms > 0.001 else { return nil }

        let minLag = Int(sampleRate / 2000.0)
        let maxLag = min(Int(sampleRate / 60.0), windowed.count / 2)
        guard maxLag > minLag else { return nil }

        var bestLag = minLag
        var bestCorrelation: Float = 0

        for lag in minLag..<maxLag {
            var correlation: Float = 0
            let count = windowed.count - lag
            for i in 0..<count {
                correlation += windowed[i] * windowed[i + lag]
            }
            let normalized = correlation / (energy * Float(count))
            if normalized > bestCorrelation {
                bestCorrelation = normalized
                bestLag = lag
            }
        }

        guard bestCorrelation > 0.75 else { return nil }

        let refinedLag = parabolicInterpolation(
            lag: bestLag,
            windowed: windowed,
            minLag: minLag,
            maxLag: maxLag,
            energy: energy
        )

        let frequency = sampleRate / refinedLag
        guard frequency >= 60, frequency <= 2000 else { return nil }
        return frequency
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

import AVFoundation

final class PitchDetector {
    private let sampleRate: Double
    private let bufferSize: Int

    init(sampleRate: Double, bufferSize: Int = 4096) {
        self.sampleRate = sampleRate
        self.bufferSize = bufferSize
    }

    func detectPitch(from samples: [Float]) -> Double? {
        guard samples.count >= bufferSize else { return nil }

        let windowed = applyHannWindow(samples)
        let rms = sqrt(windowed.map { $0 * $0 }.reduce(0, +) / Float(windowed.count))
        guard rms > 0.01 else { return nil }

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
            if correlation > bestCorrelation {
                bestCorrelation = correlation
                bestLag = lag
            }
        }

        guard bestCorrelation > 0.5 else { return nil }

        let refinedLag = parabolicInterpolation(
            lag: bestLag,
            correlations: windowed,
            minLag: minLag,
            maxLag: maxLag
        )

        let frequency = sampleRate / refinedLag
        guard frequency >= 60, frequency <= 2000 else { return nil }
        return frequency
    }

    private func applyHannWindow(_ samples: [Float]) -> [Float] {
        let count = min(samples.count, bufferSize)
        var windowed = [Float](repeating: 0, count: count)
        for i in 0..<count {
            let window = 0.5 * (1.0 - cos(2.0 * .pi * Double(i) / Double(count - 1)))
            windowed[i] = samples[i] * Float(window)
        }
        return windowed
    }

    private func parabolicInterpolation(lag: Int, correlations: [Float], minLag: Int, maxLag: Int) -> Double {
        guard lag > minLag, lag < maxLag - 1 else { return Double(lag) }

        func correlation(at lag: Int) -> Float {
            var sum: Float = 0
            let count = correlations.count - lag
            for i in 0..<count {
                sum += correlations[i] * correlations[i + lag]
            }
            return sum
        }

        let y0 = correlation(at: lag - 1)
        let y1 = correlation(at: lag)
        let y2 = correlation(at: lag + 1)

        let denominator = 2.0 * Double(2.0 * y1 - y0 - y2)
        guard abs(denominator) > 1e-6 else { return Double(lag) }

        let offset = Double(y0 - y2) / denominator
        return Double(lag) + offset
    }
}

import Foundation

struct PitchStabilizerResult {
    let frequency: Double?
    let shouldClearDisplay: Bool
}

final class PitchStabilizer {
    private var recentFrequencies: [Double] = []
    private var consecutiveStableFrames = 0
    private var silenceFrames = 0
    private var lastStableFrequency: Double?

    var noiseGateLevel: Float = 0.05
    private let requiredStableFrames = 5
    private let silenceFramesToClear = 12
    private let maxFrequencyJumpCents = 80.0
    private let stableFrameCentsTolerance = 12.0
    private let historySize = 9

    func reset() {
        recentFrequencies.removeAll()
        consecutiveStableFrames = 0
        silenceFrames = 0
        lastStableFrequency = nil
    }

    func process(frequency: Double?, inputLevel: Float) -> PitchStabilizerResult {
        guard inputLevel >= noiseGateLevel else {
            silenceFrames += 1
            consecutiveStableFrames = 0
            recentFrequencies.removeAll()

            if silenceFrames >= silenceFramesToClear {
                lastStableFrequency = nil
                return PitchStabilizerResult(frequency: nil, shouldClearDisplay: true)
            }

            return PitchStabilizerResult(frequency: lastStableFrequency, shouldClearDisplay: false)
        }

        silenceFrames = 0

        guard let frequency else {
            consecutiveStableFrames = max(0, consecutiveStableFrames - 1)
            return PitchStabilizerResult(frequency: lastStableFrequency, shouldClearDisplay: false)
        }

        if let last = lastStableFrequency {
            let jump = abs(centsBetween(frequency, and: last))
            if jump > maxFrequencyJumpCents && consecutiveStableFrames < requiredStableFrames {
                consecutiveStableFrames = 0
                return PitchStabilizerResult(frequency: lastStableFrequency, shouldClearDisplay: false)
            }
        }

        recentFrequencies.append(frequency)
        if recentFrequencies.count > historySize {
            recentFrequencies.removeFirst()
        }

        let median = medianFrequency(recentFrequencies)

        if let previous = recentFrequencies.dropLast().last {
            let drift = abs(centsBetween(median, and: previous))
            if drift <= stableFrameCentsTolerance {
                consecutiveStableFrames += 1
            } else {
                consecutiveStableFrames = 1
            }
        } else {
            consecutiveStableFrames = 1
        }

        guard consecutiveStableFrames >= requiredStableFrames else {
            return PitchStabilizerResult(frequency: lastStableFrequency, shouldClearDisplay: false)
        }

        lastStableFrequency = median
        return PitchStabilizerResult(frequency: median, shouldClearDisplay: false)
    }

    private func medianFrequency(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }

    private func centsBetween(_ a: Double, and b: Double) -> Double {
        1200.0 * log2(a / b)
    }
}

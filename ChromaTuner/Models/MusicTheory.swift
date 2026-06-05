import Foundation

enum AppMode {
    case chromatic
    case toneGenerator
}

struct NoteInfo: Equatable {
    let name: String
    let octave: Int
    let cents: Double
    let frequency: Double

    var displayName: String {
        "\(name)\(octave.subscriptString)"
    }

    var noteIndex: Int {
        MusicTheory.noteNames.firstIndex(of: name) ?? 0
    }

    var tuningDirection: TuningDirection {
        if abs(cents) < MusicTheory.inTuneThreshold { return .inTune }
        return cents < 0 ? .flat : .sharp
    }
}

enum TuningDirection {
    case flat, inTune, sharp
}

enum MusicTheory {
    static let noteNames = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
    static let defaultA4 = 440.0
    static let referenceMidi = 69
    static let inTuneThreshold = 5.0

    static func frequency(forMidiNote midi: Double, a4: Double = defaultA4) -> Double {
        a4 * pow(2.0, (midi - Double(referenceMidi)) / 12.0)
    }

    static func midiNote(fromFrequency frequency: Double, a4: Double = defaultA4) -> Double {
        12.0 * log2(frequency / a4) + Double(referenceMidi)
    }

    static func noteInfo(fromFrequency frequency: Double, a4: Double = defaultA4) -> NoteInfo? {
        guard frequency > 20, frequency < 5000 else { return nil }

        let midi = midiNote(fromFrequency: frequency, a4: a4)
        let roundedMidi = Int(round(midi))
        let cents = (midi - Double(roundedMidi)) * 100.0
        let noteIndex = ((roundedMidi % 12) + 12) % 12
        let octave = (roundedMidi / 12) - 1

        return NoteInfo(
            name: noteNames[noteIndex],
            octave: octave,
            cents: cents,
            frequency: frequency
        )
    }

    static func frequency(noteName: String, octave: Int, a4: Double = defaultA4) -> Double {
        guard let index = noteNames.firstIndex(of: noteName) else { return a4 }
        let midi = (octave + 1) * 12 + index
        return frequency(forMidiNote: Double(midi), a4: a4)
    }

    static func noteAngle(forNoteIndex index: Int) -> Double {
        Double(index) * 30.0 - 90.0
    }

    static func ringRotation(noteIndex: Int, cents: Double) -> Double {
        -Double(noteIndex) * 30.0 - cents * 0.3
    }
}

extension Int {
    var subscriptString: String {
        let subscripts = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]
        return String(self).compactMap { char in
            guard let digit = char.wholeNumberValue, digit < subscripts.count else { return nil }
            return subscripts[digit]
        }.joined()
    }
}

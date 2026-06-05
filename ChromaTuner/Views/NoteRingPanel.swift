import SwiftUI

struct NoteRingPanel: View {
    @EnvironmentObject private var audioManager: AudioManager
    let mode: AppMode

    @State private var dragRotation: Double = 0
    @State private var lastDragRotation: Double = 0
    @State private var isDragging = false

    private var tunerRotation: Double {
        guard let note = audioManager.detectedNote else { return 0 }
        return MusicTheory.ringRotation(noteIndex: note.noteIndex, cents: note.cents)
    }

    private var tunerHighlightIndex: Int? {
        audioManager.detectedNote?.noteIndex
    }

    private var ringRotation: Double {
        mode == .chromatic ? tunerRotation : dragRotation
    }

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

                ZStack {
                    NoteDialView(
                        accentColor: mode == .chromatic ? AppColors.gaugeAmberDark : AppColors.accentBlue,
                        highlightedNoteIndex: mode == .chromatic ? tunerHighlightIndex : audioManager.selectedNoteIndex,
                        rotationOffset: ringRotation
                    )
                    .animation(isDragging ? nil : .easeOut(duration: 0.08), value: ringRotation)

                    if mode == .toneGenerator {
                        CenterToneButton(
                            noteDisplay: audioManager.selectedNoteDisplay,
                            isPlaying: audioManager.isTonePlaying
                        ) {
                            audioManager.toggleTone()
                        }
                        .frame(width: size * 0.32, height: size * 0.32)
                    } else if let note = audioManager.detectedNote {
                        TunerCenterDisplay(noteDisplay: note.displayName)
                            .frame(width: size * 0.32, height: size * 0.32)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Circle())
                .gesture(mode == .toneGenerator ? rotationGesture(center: center) : nil)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal, 24)

            if mode == .toneGenerator {
                OctaveStepper(
                    octave: audioManager.selectedOctave,
                    onDecrement: { audioManager.decrementOctave() },
                    onIncrement: { audioManager.incrementOctave() }
                )
            }
        }
        .onAppear { syncDragRotation() }
        .onChange(of: mode) { _, newMode in
            if newMode == .toneGenerator {
                syncDragRotation()
            }
        }
    }

    private func syncDragRotation() {
        let snapped = -Double(audioManager.selectedNoteIndex) * 30.0
        dragRotation = snapped
        lastDragRotation = snapped
    }

    private func rotationGesture(center: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                isDragging = true
                let start = angle(from: center, to: value.startLocation)
                let current = angle(from: center, to: value.location)
                let delta = shortestAngleDelta(from: start, to: current)
                dragRotation = lastDragRotation + delta

                let noteIndex = noteIndex(for: dragRotation)
                if noteIndex != audioManager.selectedNoteIndex {
                    audioManager.selectNote(at: noteIndex)
                }
            }
            .onEnded { _ in
                let snapped = round(dragRotation / 30.0) * 30.0
                dragRotation = snapped
                lastDragRotation = snapped
                isDragging = false

                let noteIndex = noteIndex(for: snapped)
                audioManager.selectNote(at: noteIndex)
            }
    }

    private func noteIndex(for rotation: Double) -> Int {
        let normalized = ((-rotation).truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
        return Int(round(normalized / 30.0)) % 12
    }

    private func angle(from center: CGPoint, to point: CGPoint) -> Double {
        atan2(point.y - center.y, point.x - center.x) * 180 / .pi
    }

    private func shortestAngleDelta(from start: Double, to end: Double) -> Double {
        var delta = end - start
        while delta > 180 { delta -= 360 }
        while delta < -180 { delta += 360 }
        return delta
    }
}

private struct CenterToneButton: View {
    let noteDisplay: String
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColors.accentBlue, AppColors.accentBlueDark],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .overlay(Circle().stroke(AppColors.silverShadow, lineWidth: 2))

                VStack(spacing: 4) {
                    Text(noteDisplay)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct TunerCenterDisplay: View {
    let noteDisplay: String

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.ringFace, AppColors.ringInset.opacity(0.5)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .overlay(Circle().stroke(AppColors.silverShadow.opacity(0.5), lineWidth: 1))

            Text(noteDisplay)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.gaugeText)
        }
    }
}

private struct OctaveStepper: View {
    let octave: Int
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            StepperButton(label: "−", enabled: octave > 0, action: onDecrement)
            Text("Octave \(octave)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.labelWhite)
                .frame(width: 90)
            StepperButton(label: "+", enabled: octave < 8, action: onIncrement)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(AppColors.housingDark.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppColors.silverShadow.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

private struct StepperButton: View {
    let label: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(enabled ? AppColors.labelWhite : AppColors.labelMuted)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: enabled
                                    ? [AppColors.silverHighlight, AppColors.silverShadow]
                                    : [AppColors.housingLight, AppColors.housingDark],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

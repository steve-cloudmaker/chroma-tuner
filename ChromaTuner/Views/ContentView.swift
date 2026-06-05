import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var audioManager: AudioManager
    @State private var selectedMode: AppMode = .chromatic
    @State private var showSettings = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Text("Chromatic Instrument Tuner")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.labelWhite.opacity(0.9))
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                AnalogGaugeView(
                    noteDisplay: gaugeNote,
                    frequency: audioManager.gaugeFrequency,
                    cents: selectedMode == .chromatic ? audioManager.gaugeCents : 0,
                    showLiveNeedle: selectedMode == .chromatic && audioManager.detectedNote != nil
                )

                LEDIndicatorView(
                    direction: audioManager.detectedNote?.tuningDirection,
                    hasSignal: selectedMode == .chromatic && audioManager.detectedNote != nil
                )
                .padding(.vertical, 8)

                HardwareControlRow(selectedMode: $selectedMode)
                .padding(.bottom, 12)

                if audioManager.microphoneUnavailable && selectedMode == .chromatic {
                    Text("Microphone unavailable — use a physical device to tune.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.labelWhite.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                NoteRingPanel(mode: selectedMode)
                    .frame(maxHeight: .infinity)

                FooterBar(showSettings: $showSettings)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: min(geometry.size.width, 500))
            .frame(maxWidth: .infinity)
        }
        .background(
            LinearGradient(
                colors: [AppColors.housingLight, AppColors.housing, AppColors.housingDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .task {
            let granted = await audioManager.requestMicrophonePermission()
            if granted, selectedMode == .chromatic {
                audioManager.startListening()
            } else if !granted {
                audioManager.microphoneUnavailable = true
            }
        }
        .onDisappear {
            audioManager.stopListening()
            audioManager.stopTone()
        }
        .onChange(of: selectedMode) { _, newMode in
            switch newMode {
            case .chromatic:
                audioManager.stopTone()
                if !audioManager.isListening {
                    audioManager.startListening()
                }
            case .toneGenerator:
                audioManager.stopListening()
            }
        }
    }

    private var gaugeNote: String {
        switch selectedMode {
        case .chromatic:
            return audioManager.detectedNote?.displayName ?? "—"
        case .toneGenerator:
            return audioManager.selectedNoteDisplay
        }
    }
}

private struct FooterBar: View {
    @Binding var showSettings: Bool

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                Text("chroma-tuner")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(AppColors.labelWhite.opacity(0.7))

            Spacer()

            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.housingDark)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.silverHighlight, AppColors.silverShadow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AudioManager())
}

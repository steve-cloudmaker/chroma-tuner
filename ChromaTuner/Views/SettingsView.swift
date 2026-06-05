import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var audioManager: AudioManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Calibration") {
                    HStack {
                        Text("A4 Reference")
                        Spacer()
                        Text(String(format: "%.1f Hz", audioManager.a4Reference))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Button("Reset A4 to 440 Hz") {
                        audioManager.resetA4()
                    }
                }

                Section("Tuning") {
                    HStack {
                        Text("In-Tune Threshold")
                        Spacer()
                        Text("±\(Int(MusicTheory.inTuneThreshold)) cents")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    HStack {
                        Text("App")
                        Spacer()
                        Text("chroma-tuner")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

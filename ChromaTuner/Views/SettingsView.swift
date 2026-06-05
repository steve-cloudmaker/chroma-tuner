import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var audioManager: AudioManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var a4FieldFocused: Bool
    @State private var a4Input = ""

    private let a4Range = 400.0...480.0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("A4 Reference")
                        Spacer()
                        TextField("440.0", text: $a4Input)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                            .frame(width: 80)
                            .focused($a4FieldFocused)
                            .onSubmit(applyA4Input)
                        Text("Hz")
                            .foregroundStyle(.secondary)
                    }

                    Stepper(
                        value: Binding(
                            get: { audioManager.a4Reference },
                            set: { audioManager.setA4Reference($0) }
                        ),
                        in: a4Range,
                        step: 0.1
                    ) {
                        Text(String(format: "%.1f Hz", audioManager.a4Reference))
                            .monospacedDigit()
                    }
                    .onChange(of: audioManager.a4Reference) { _, newValue in
                        syncInput(from: newValue)
                    }

                    Button("Reset to 440 Hz") {
                        audioManager.resetA4()
                        syncInput(from: audioManager.a4Reference)
                    }
                } header: {
                    Text("Calibration")
                } footer: {
                    Text("Set the reference frequency for A4. Common values are 440 Hz (modern) and 442 Hz (orchestral).")
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
                    Button("Done") {
                        applyA4Input()
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        applyA4Input()
                        a4FieldFocused = false
                    }
                }
            }
            .onAppear {
                syncInput(from: audioManager.a4Reference)
            }
        }
    }

    private func syncInput(from value: Double) {
        a4Input = String(format: "%.1f", value)
    }

    private func applyA4Input() {
        let normalized = a4Input.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized) else {
            syncInput(from: audioManager.a4Reference)
            return
        }
        audioManager.setA4Reference(value)
        syncInput(from: audioManager.a4Reference)
    }
}

import SwiftUI

struct HardwareControlRow: View {
    @Binding var selectedMode: AppMode

    var body: some View {
        HStack(spacing: 24) {
            ModeButton(
                icon: "tuningfork",
                isActive: selectedMode == .chromatic,
                activeColor: AppColors.ledGreen
            ) {
                selectedMode = .chromatic
            }

            Spacer()

            ModeButton(
                icon: "speaker.wave.2.fill",
                isActive: selectedMode == .toneGenerator,
                activeColor: AppColors.accentBlue
            ) {
                selectedMode = .toneGenerator
            }
        }
        .padding(.horizontal, 16)
    }
}

private struct ModeButton: View {
    let icon: String
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    private let buttonSize: CGFloat = 72

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.silverHighlight, AppColors.silver, AppColors.silverShadow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(AppColors.silverShadow.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 2)

                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(isActive ? activeColor : AppColors.housingDark)
                    .shadow(color: isActive ? activeColor.opacity(0.6) : .clear, radius: 8)
            }
            .frame(width: buttonSize, height: buttonSize)
        }
        .buttonStyle(.plain)
    }
}

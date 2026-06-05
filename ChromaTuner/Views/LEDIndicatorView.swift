import SwiftUI

struct LEDIndicatorView: View {
    let direction: TuningDirection?
    let hasSignal: Bool

    var body: some View {
        HStack(spacing: 24) {
            HStack(spacing: 6) {
                Text("♭")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.labelMuted)
                LEDBulb(isOn: hasSignal && direction == .flat, color: AppColors.ledRed, glow: AppColors.ledRedGlow)
            }

            LEDBulb(
                isOn: hasSignal && direction == .inTune,
                color: AppColors.ledGreen,
                glow: AppColors.ledGreenGlow,
                size: 18
            )

            HStack(spacing: 6) {
                LEDBulb(isOn: hasSignal && direction == .sharp, color: AppColors.ledRed, glow: AppColors.ledRedGlow)
                Text("♯")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.labelMuted)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black.opacity(0.8), lineWidth: 1)
                )
        )
    }
}

private struct LEDBulb: View {
    let isOn: Bool
    let color: Color
    let glow: Color
    var size: CGFloat = 14

    var body: some View {
        Circle()
            .fill(isOn ? color : AppColors.ledOff)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isOn ? [glow, color] : [AppColors.ledOff, AppColors.ledOff.opacity(0.5)],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
            )
            .shadow(color: isOn ? glow.opacity(0.8) : .clear, radius: isOn ? 6 : 0)
    }
}

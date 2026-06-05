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

    var body: some View {
        Button(action: action) {
            ZStack {
                WingButtonShape()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.silverHighlight, AppColors.silver, AppColors.silverShadow],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 2)

                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(isActive ? activeColor : AppColors.housingDark)
                    .shadow(color: isActive ? activeColor.opacity(0.6) : .clear, radius: 8)
            }
            .frame(width: 100, height: 70)
        }
        .buttonStyle(.plain)
    }
}

private struct WingButtonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let curve = rect.height * 0.25

        path.move(to: CGPoint(x: rect.minX + 8, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - 8, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY + curve)
        )
        path.closeSubpath()
        return path
    }
}

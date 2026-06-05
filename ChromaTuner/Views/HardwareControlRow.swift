import SwiftUI

struct HardwareControlRow: View {
    @Binding var selectedMode: AppMode
    let onDecreaseA4: () -> Void
    let onIncreaseA4: () -> Void
    let onDecreaseA4Fine: () -> Void
    let onIncreaseA4Fine: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ModeButton(
                icon: "tuningfork",
                isActive: selectedMode == .chromatic,
                activeColor: AppColors.ledGreen
            ) {
                selectedMode = .chromatic
            }

            CalibControls(
                onDecrease: onDecreaseA4,
                onIncrease: onIncreaseA4,
                onDecreaseFine: onDecreaseA4Fine,
                onIncreaseFine: onIncreaseA4Fine
            )

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

private struct CalibControls: View {
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    let onDecreaseFine: () -> Void
    let onIncreaseFine: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text("CALIB")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.labelWhite.opacity(0.7))

            HStack(spacing: 16) {
                CalibButton(label: "−", onTap: onDecrease, onLongPress: onDecreaseFine)
                CalibButton(label: "+", onTap: onIncrease, onLongPress: onIncreaseFine)
            }
        }
    }
}

private struct CalibButton: View {
    let label: String
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var longPressTimer: Timer?
    @State private var isLongPressing = false

    var body: some View {
        Image(systemName: label == "−" ? "triangle.fill" : "triangle.fill")
            .font(.system(size: 10))
            .foregroundStyle(AppColors.housingDark)
            .rotationEffect(.degrees(label == "−" ? -90 : 90))
            .frame(width: 32, height: 28)
            .background(
                Triangle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.silverHighlight, AppColors.silverShadow],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay {
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.housingDark)
            }
            .onTapGesture {
                if !isLongPressing {
                    onTap()
                }
            }
            .onLongPressGesture(minimumDuration: 0.4, pressing: { pressing in
                if pressing {
                    isLongPressing = false
                    longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                        isLongPressing = true
                        onLongPress()
                    }
                } else {
                    longPressTimer?.invalidate()
                    longPressTimer = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isLongPressing = false
                    }
                }
            }, perform: {})
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

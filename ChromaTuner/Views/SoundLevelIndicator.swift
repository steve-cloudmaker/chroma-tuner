import SwiftUI

struct SoundLevelIndicator: View {
    let level: Float
    let isActive: Bool

    private let segmentCount = 12

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.55))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(AppColors.silverShadow.opacity(0.5), lineWidth: 1)
                        )

                    RoundedRectangle(cornerRadius: 2)
                        .fill(levelGradient)
                        .frame(width: geo.size.width * CGFloat(displayLevel))
                        .padding(2)
                        .animation(.easeOut(duration: 0.05), value: displayLevel)
                }
            }
            .frame(height: 14)

            HStack(spacing: 2) {
                ForEach(0..<segmentCount, id: \.self) { index in
                    Rectangle()
                        .fill(segmentColor(for: index))
                        .frame(height: 3)
                }
            }
        }
        .opacity(isActive ? 1 : 0.45)
    }

    private var displayLevel: Float {
        isActive ? level : 0
    }

    private var levelGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.ledGreen, AppColors.tunerYellow, AppColors.ledRed],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func segmentColor(for index: Int) -> Color {
        let threshold = Float(index + 1) / Float(segmentCount)
        guard isActive, displayLevel >= threshold else {
            return AppColors.housingDark.opacity(0.8)
        }

        if threshold <= 0.65 {
            return AppColors.ledGreen.opacity(0.9)
        }
        if threshold <= 0.85 {
            return AppColors.tunerYellow.opacity(0.9)
        }
        return AppColors.ledRed.opacity(0.9)
    }
}

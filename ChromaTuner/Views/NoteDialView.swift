import SwiftUI

struct NoteDialView: View {
    let accentColor: Color
    let highlightedNoteIndex: Int?
    var rotationOffset: Double = 0

    private let noteNames = MusicTheory.noteNames
    private let tickCount = 60

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColors.ringFace, AppColors.ringInset.opacity(0.3)],
                            center: .center,
                            startRadius: 0,
                            endRadius: radius
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [AppColors.silverHighlight, AppColors.silverShadow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

                ZStack {
                    ForEach(0..<tickCount, id: \.self) { tick in
                        let isMajor = tick % 5 == 0
                        let angle = Double(tick) * 6.0 - 90.0 + rotationOffset
                        let tickRadius = radius * 0.88

                        Rectangle()
                            .fill(AppColors.labelMuted.opacity(isMajor ? 0.7 : 0.35))
                            .frame(width: isMajor ? 2 : 1, height: isMajor ? 10 : 5)
                            .position(
                                x: radius + cos(angle * .pi / 180) * tickRadius,
                                y: radius + sin(angle * .pi / 180) * tickRadius
                            )
                            .rotationEffect(.degrees(angle + 90))
                    }

                    ForEach(0..<12, id: \.self) { index in
                        let angle = MusicTheory.noteAngle(forNoteIndex: index) + rotationOffset
                        let isHighlighted = highlightedNoteIndex == index
                        let labelRadius = radius * 0.72
                        let radians = angle * .pi / 180

                        Text(noteNames[index])
                            .font(.system(size: isHighlighted ? 15 : 13, weight: isHighlighted ? .bold : .regular))
                            .foregroundStyle(isHighlighted ? .white : AppColors.labelMuted)
                            .padding(.horizontal, isHighlighted ? 6 : 0)
                            .padding(.vertical, isHighlighted ? 3 : 0)
                            .background {
                                if isHighlighted {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(accentColor)
                                }
                            }
                            .position(
                                x: radius + cos(radians) * labelRadius,
                                y: radius + sin(radians) * labelRadius
                            )
                    }
                }

                SelectionWedge(color: accentColor)
                    .frame(width: 44, height: 20)
                    .position(x: radius, y: radius * 0.22)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct SelectionWedge: View {
    let color: Color

    var body: some View {
        ZStack {
            TrapezoidWedge()
                .fill(color)
            Rectangle()
                .fill(AppColors.housingDark)
                .frame(width: 2, height: 8)
                .offset(y: -12)
        }
    }
}

private struct TrapezoidWedge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - 18, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + 18, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + 12, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX - 12, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

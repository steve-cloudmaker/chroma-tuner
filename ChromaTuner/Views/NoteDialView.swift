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
                        Rectangle()
                            .fill(AppColors.labelMuted.opacity(isMajor ? 0.7 : 0.35))
                            .frame(width: isMajor ? 2 : 1, height: isMajor ? 10 : 5)
                            .offset(y: -radius * 0.84)
                            .rotationEffect(.degrees(Double(tick) * 6.0))
                    }

                    ForEach(0..<12, id: \.self) { index in
                        let isHighlighted = highlightedNoteIndex == index

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
                            .offset(y: -radius * 0.68)
                            .rotationEffect(.degrees(Double(index) * 30.0))
                    }
                }
                .rotationEffect(.degrees(rotationOffset))

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

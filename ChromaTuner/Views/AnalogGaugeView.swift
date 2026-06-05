import SwiftUI

struct AnalogGaugeView: View {
    let noteDisplay: String
    let frequency: Double
    let cents: Double
    let showLiveNeedle: Bool

    private var needlePosition: CGFloat {
        let clamped = max(-50, min(50, cents))
        return CGFloat(clamped / 50.0)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(AppColors.housingDark)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

            GaugeDisplayShape()
                .fill(
                    RadialGradient(
                        colors: [AppColors.gaugeAmber, AppColors.gaugeAmberDark.opacity(0.9)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .padding(8)

            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                Text(noteDisplay)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.gaugeText)

                Text(String(format: "%.1f Hz", frequency))
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppColors.gaugeText.opacity(0.8))
                    .padding(.top, 2)

                Spacer()

                CentScaleView(cents: cents, showNeedle: showLiveNeedle)
                    .frame(height: 80)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .padding(8)
        }
        .frame(height: 200)
        .padding(.horizontal, 20)
    }
}

private struct GaugeDisplayShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let archHeight = rect.width * 0.08

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + archHeight))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + archHeight),
            control: CGPoint(x: rect.midX, y: rect.minY - archHeight)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct CentScaleView: View {
    let cents: Double
    let showNeedle: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let arcY = h * 0.35

            ZStack {
                ForEach(-50...50, id: \.self) { cent in
                    if cent % 10 == 0 {
                        let x = centToX(cent, width: w)
                        Text(cent == 0 ? "0" : (cent > 0 ? "+\(cent)" : "\(cent)"))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppColors.gaugeText)
                            .position(x: x, y: arcY - 18)
                    }
                }

                Text("CENT")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(AppColors.gaugeText.opacity(0.7))
                    .position(x: w * 0.88, y: arcY - 28)

                ForEach([-20, 20], id: \.self) { cent in
                    let x = centToX(cent, width: w)
                    Triangle()
                        .fill(AppColors.gaugeText.opacity(0.5))
                        .frame(width: 6, height: 5)
                        .position(x: x, y: arcY + 2)
                }

                ForEach(-50...50, id: \.self) { cent in
                    if cent % 5 == 0 {
                        let x = centToX(cent, width: w)
                        let tickH: CGFloat = cent % 10 == 0 ? 8 : 4
                        Rectangle()
                            .fill(AppColors.gaugeText.opacity(0.5))
                            .frame(width: 1, height: tickH)
                            .position(x: x, y: arcY + tickH / 2 + 4)
                    }
                }

                if showNeedle {
                    let clamped = max(-50.0, min(50.0, cents))
                    let needleX = centPosition(clamped, width: w)
                    Rectangle()
                        .fill(AppColors.gaugeText)
                        .frame(width: 1.5, height: h * 0.55)
                        .position(x: needleX, y: h * 0.45)
                        .animation(.easeOut(duration: 0.08), value: cents)
                } else {
                    Rectangle()
                        .fill(AppColors.gaugeText)
                        .frame(width: 1.5, height: h * 0.55)
                        .position(x: w / 2, y: h * 0.45)
                }
            }
        }
    }

    private func centToX(_ cent: Int, width: CGFloat) -> CGFloat {
        centPosition(Double(cent), width: width)
    }

    private func centPosition(_ cent: Double, width: CGFloat) -> CGFloat {
        let normalized = (CGFloat(cent) + 50) / 100.0
        return width * 0.05 + normalized * width * 0.9
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

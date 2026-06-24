import SwiftUI

// Mouton mascotte animé — 5 niveaux avec comportements distincts
// Les images sont dans Assets.xcassets : sheep_lv1, sheep_lv3, sheep_lv5, sheep_lv7, sheep_lv9
struct SheepMascotView: View {
    let level: Int          // 1–10
    var size: CGFloat = 160

    @State private var floating  = false
    @State private var glowing   = false
    @State private var tilting   = false
    @State private var tearDrop  = false
    @State private var particles = (0..<10).map { _ in SheepParticle() }

    var body: some View {
        ZStack {
            // Particules dorées — lv 9-10
            if level >= 9 {
                ForEach(particles) { p in
                    Circle()
                        .fill(Color(red: 1.0, green: 0.84, blue: 0.26).opacity(glowing ? 0.9 : 0.1))
                        .frame(width: p.size, height: p.size)
                        .offset(x: p.x, y: glowing ? p.y - 30 : p.y)
                        .animation(
                            .easeInOut(duration: p.duration)
                            .repeatForever(autoreverses: true)
                            .delay(p.delay),
                            value: glowing
                        )
                }
            }

            // Lueur halo — lv 5+
            if level >= 5 {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 1.0, green: 0.84, blue: 0.26).opacity(0.45), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 55
                        )
                    )
                    .frame(width: 110, height: 44)
                    .scaleEffect(glowing ? 1.4 : 0.7)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: glowing)
                    .offset(y: -(size * 0.44))
            }

            // Image du mouton
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .offset(y: floating ? floatOffset : 0)
                .rotationEffect(.degrees(tilting ? tiltAngle : -tiltAngle))
                .animation(floatAnimation, value: floating)
                .animation(tiltAnimation,  value: tilting)

            // Larme qui tombe — lv 1-2
            if level <= 2 {
                Teardrop()
                    .fill(Color(red: 0.53, green: 0.81, blue: 0.98))
                    .frame(width: 8, height: 12)
                    .offset(x: 18, y: tearDrop ? size * 0.15 : -size * 0.05)
                    .opacity(tearDrop ? 0 : 1)
                    .animation(.easeIn(duration: 1.2).repeatForever(autoreverses: false), value: tearDrop)
            }
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Helpers

    private var imageName: String {
        switch level {
        case 1, 2:  return "sheep_lv1"
        case 3, 4:  return "sheep_lv3"
        case 5, 6:  return "sheep_lv5"
        case 7, 8:  return "sheep_lv7"
        default:    return "sheep_lv9"
        }
    }

    private var floatOffset: CGFloat {
        switch level {
        case 1, 2:  return 4      // légère descente triste
        case 3, 4:  return -7     // rebond joyeux
        case 5, 6:  return -11    // flottement doux
        case 7, 8:  return -16    // flottement angélique
        default:    return -22    // lévitation divine
        }
    }

    private var tiltAngle: Double { level <= 2 ? 5.0 : 0 }

    private var floatAnimation: Animation {
        switch level {
        case 1, 2:  return .easeInOut(duration: 3.0).repeatForever(autoreverses: true)
        case 3, 4:  return .easeInOut(duration: 1.1).repeatForever(autoreverses: true)
        case 5, 6:  return .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        case 7, 8:  return .easeInOut(duration: 1.6).repeatForever(autoreverses: true)
        default:    return .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
        }
    }

    private var tiltAnimation: Animation {
        .easeInOut(duration: 2.8).repeatForever(autoreverses: true)
    }

    private func startAnimations() {
        withAnimation(floatAnimation)  { floating = true }
        withAnimation(tiltAnimation)   { tilting  = true }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { glowing = true }
        if level <= 2 {
            withAnimation(.easeIn(duration: 1.2).repeatForever(autoreverses: false).delay(0.5)) {
                tearDrop = true
            }
        }
    }
}

// Forme larme pour le mouton lv 1-2
struct Teardrop: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w / 2, y: 0))
        p.addCurve(
            to:        CGPoint(x: w,     y: h * 0.65),
            control1:  CGPoint(x: w,     y: h * 0.25),
            control2:  CGPoint(x: w,     y: h * 0.5)
        )
        p.addArc(
            center:    CGPoint(x: w / 2, y: h * 0.65),
            radius:    w / 2,
            startAngle: .degrees(0),
            endAngle:  .degrees(180),
            clockwise: false
        )
        p.addCurve(
            to:        CGPoint(x: w / 2, y: 0),
            control1:  CGPoint(x: 0,     y: h * 0.5),
            control2:  CGPoint(x: 0,     y: h * 0.25)
        )
        return p
    }
}

// Particule dorée pour lv 9-10
struct SheepParticle: Identifiable {
    let id    = UUID()
    let x:        CGFloat = .random(in: -90...90)
    let y:        CGFloat = .random(in: -110...10)
    let size:     CGFloat = .random(in: 4...9)
    let duration: Double  = .random(in: 1.0...2.5)
    let delay:    Double  = .random(in: 0...1.5)
}

#Preview {
    VStack(spacing: 32) {
        HStack(spacing: 24) {
            SheepMascotView(level: 1, size: 100)
            SheepMascotView(level: 3, size: 100)
            SheepMascotView(level: 5, size: 100)
        }
        HStack(spacing: 24) {
            SheepMascotView(level: 7, size: 100)
            SheepMascotView(level: 9, size: 100)
        }
    }
    .padding()
    .background(Color(red: 0.95, green: 0.97, blue: 1.0))
}

import SwiftUI
import StepTellerCore

/// Colori fissi del widget (sempre tema scuro, come i mockup).
enum WidgetColors {
    static let bg = Color(red: 0x12 / 255, green: 0x15 / 255, blue: 0x17 / 255)
    static let ink = Color(red: 0xE4 / 255, green: 0xE2 / 255, blue: 0xDC / 255)
    static let soft = ink.opacity(0.52)
    static let accent = Color(red: 0x8C / 255, green: 0xCB / 255, blue: 0xBF / 255)
}

/// Sfondo del widget: antracite con due orb sfumati.
struct StepsWidgetBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                WidgetColors.bg
                Circle().fill(Color(red: 0x3C / 255, green: 0x6E / 255, blue: 0x68 / 255).opacity(0.55))
                    .frame(width: w * 0.76).blur(radius: w * 0.18).offset(x: -w * 0.26, y: -w * 0.32)
                Circle().fill(Color(red: 0x48 / 255, green: 0x42 / 255, blue: 0x78 / 255).opacity(0.42))
                    .frame(width: w * 0.68).blur(radius: w * 0.18).offset(x: w * 0.30, y: w * 0.34)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }
}

/// Widget piccolo «A1»: arco di 270° con i passi al centro e, nell'apertura, i minuti a piedi
/// (camminata a 4 km/h, solo un'idea di massima). Disegnato nello spazio 340×340 dei mockup e scalato.
struct StepsWidgetView: View {
    /// `nil` = dato non disponibile.
    let plan: Plan?

    var body: some View {
        GeometryReader { geo in
            let k = geo.size.width / 340
            content
                .frame(width: 340, height: 340)
                .scaleEffect(k, anchor: .topLeading)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
    }

    private var progress: Double { plan?.progress ?? 0 }
    private var done: Bool { plan?.isDone ?? false }

    private var content: some View {
        ZStack(alignment: .topLeading) {
            ring
            stepsCenter
            if done { extraBlock } else if plan != nil { minutesBlock }
        }
    }

    // MARK: anello

    private var ring: some View {
        // Sempre un arco di 270°: a obiettivo chiuso arriva a fondo scala e si ferma.
        let center = CGPoint(x: 170, y: 158)
        let track = Color.white.opacity(0.10)
        let line = StrokeStyle(lineWidth: 7, lineCap: .round)
        let p = min(1, max(0, progress))
        return ZStack {
            Circle().trim(from: 0, to: 0.75).stroke(track, style: line).rotationEffect(.degrees(135))
            Circle().trim(from: 0, to: 0.75 * p).stroke(WidgetColors.accent, style: line)
                .rotationEffect(.degrees(135))
                .shadow(color: WidgetColors.accent.opacity(0.45), radius: 6)
            let angle = (135 + 270 * p) * .pi / 180
            Circle().fill(WidgetColors.ink).frame(width: 11, height: 11)
                .shadow(color: WidgetColors.accent.opacity(0.8), radius: 5)
                .offset(x: 106 * cos(angle), y: 106 * sin(angle))
        }
        .frame(width: 212, height: 212)
        .position(center)
    }

    // MARK: testi

    private var stepsCenter: some View {
        VStack(spacing: 6) {
            Text("PASSI").font(.system(size: 11, weight: .semibold)).tracking(3.3)
                .foregroundStyle(WidgetColors.soft)
            Text(plan.map { ItalianFormat.integer($0.steps) } ?? "—")
                .font(.system(size: 62, weight: .ultraLight)).tracking(-3.1).monospacedDigit()
                .foregroundStyle(WidgetColors.ink).lineLimit(1).minimumScaleFactor(0.6)
            Text(plan.map { "su \(ItalianFormat.integer($0.goal))" } ?? "apri l'app")
                .font(.system(size: 13)).monospacedDigit().foregroundStyle(WidgetColors.soft)
        }
        .frame(width: 190)
        .position(x: 170, y: 151)
    }

    /// Nell'apertura dell'arco, a obiettivo chiuso: i passi oltre l'obiettivo.
    private var extraBlock: some View {
        VStack(spacing: 2) {
            Text(plan.map { "+" + ItalianFormat.integer(max(0, $0.steps - $0.goal)) } ?? "—")
                .font(.system(size: 38, weight: .light)).tracking(-1.5).monospacedDigit()
                .foregroundStyle(WidgetColors.accent).lineLimit(1).minimumScaleFactor(0.6)
            Text("OLTRE").font(.system(size: 11, weight: .semibold)).tracking(2.2)
                .foregroundStyle(WidgetColors.soft)
        }
        .frame(width: 150)
        .position(x: 170, y: 279)
    }

    private var minutesBlock: some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("≈").font(.system(size: 13)).foregroundStyle(WidgetColors.soft)
                Text(plan.map { String($0.minutes) } ?? "—")
                    .font(.system(size: 38, weight: .light)).tracking(-1.5).monospacedDigit()
                    .foregroundStyle(WidgetColors.accent)
                Text("min").font(.system(size: 15, weight: .medium)).foregroundStyle(WidgetColors.soft)
            }
            Text("A PIEDI").font(.system(size: 11, weight: .semibold)).tracking(2.2)
                .foregroundStyle(WidgetColors.soft)
        }
        .position(x: 170, y: 279)
    }
}

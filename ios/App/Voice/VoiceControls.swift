import SwiftUI
import StepTellerCore

extension NastyLevel {
    /// Name in the app's language («Senza pietà» in Italian, D-047).
    var label: String { L10n.text("voice.level.\(rawValue)") }
}

extension RoastFrequency {
    var label: String { L10n.text("set.voice.freq.\(rawValue)") }
}

/// The line under the goal when it is chosen or changed (T-023 §6): small heart on the left, Anton 15 red.
struct GoalVoiceLine: View {
    let quote: NastyQuote
    let level: NastyLevel
    var heart: CGFloat = 28
    var width: CGFloat = 280
    @Environment(\.manga) private var c

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            NastyHeart(level: level, size: heart)
            AntonLines(text: quote.text.uppercased(with: Locale.current), size: 15, width: width - heart - 8,
                       lineHeight: 1.1, color: c.red)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(quote.text)
        .transition(.opacity)
    }
}

/// Asks for a goal line after the goal stops changing (the ± buttons change it in steps of 500): one line for a
/// burst of changes, with the value before the burst as the old one.
@MainActor
@Observable
final class GoalLineAsker {
    private(set) var quote: NastyQuote?
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var before: Int??

    /// `old`: the goal before this change (nil: chosen for the first time, the introduction).
    func changed(old: Int?, new: Int, store: StepsStore) {
        if before == nil { before = .some(old) }
        task?.cancel()
        task = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled, let self else { return }
            let from = self.before ?? nil
            self.before = nil
            // back where it was: nothing changed
            if let from, from == new { return }
            withAnimation(.easeOut(duration: 0.2)) { self.quote = store.goalLine(old: from, new: new) }
        }
    }
}

/// The voice page of the introduction (T-023 §4): the explosion with the two hearts.
struct VoiceArt: View {
    let compact: Bool
    @Environment(\.manga) private var c

    var body: some View {
        let s: CGFloat = compact ? 168 / 300 : 1
        ZStack {
            RaysView(rays: Self.rays)
                .mask(RadialGradient(stops: [.init(color: .clear, location: 0.3), .init(color: .white, location: 0.6)],
                                     center: .center, startRadius: 0, endRadius: 220))
            KineticLines.star(cx: 160, cy: 110, points: 16, outer: 112, inner: 76, rotation: 0.1).fill(c.ink)
                .frame(width: 320, height: 220)
            KineticLines.star(cx: 160, cy: 110, points: 16, outer: 98, inner: 64, rotation: 0.1).fill(c.red)
                .frame(width: 320, height: 220)
            NastyHeart(level: .piccante, size: compact ? 74 / s : 120)
                .rotationEffect(.degrees(-10))
                .offset(x: -70, y: 10)
            NastyHeart(level: .nasty, size: compact ? 100 / s : 160)
                .rotationEffect(.degrees(8))
                .offset(x: 60, y: -6)
        }
        .frame(width: 390, height: 300)
        .scaleEffect(s)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }

    private static let rays = KineticLines.rays(cx: 195, cy: 150, count: 70, innerMin: 110, innerMax: 150, outer: 320, seed: 23, redEvery: 7)
}

/// One of the three choices of the introduction: slanted row, small heart (a dash for Normale), the chosen one
/// `ink` with a red shadow.
struct VoiceChoiceRow: View {
    let level: NastyLevel
    let selected: Bool
    let compact: Bool
    let action: () -> Void
    @Environment(\.manga) private var c

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Group {
                    if level == .normale {
                        Rectangle().fill(selected ? c.paper : c.ink).frame(width: compact ? 16 : 20, height: 3)
                    } else {
                        NastyHeart(level: level, size: compact ? 28 : 34)
                    }
                }
                .frame(width: compact ? 28 : 34)
                AntonText(level.label.uppercased(with: Locale.current), compact ? 19 : 22, tracking: 0.04,
                          color: selected ? c.paper : c.ink, minScale: 0.7)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(height: compact ? 44 : 56)
            .background(selected ? c.ink : c.paper)
            .overlay(Rectangle().strokeBorder(c.ink, lineWidth: 2.5))
            .background(Rectangle().fill(selected ? c.red : .clear).offset(x: 4, y: 4))
            .manga(skew: -8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScale())
        .accessibilityLabel(level.label)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

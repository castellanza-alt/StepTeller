import SwiftUI
import StepTellerCore

/// A Jolly pop-up waiting to be shown: the latest event of its kind and how many were found together.
struct JollyPopupItem: Identifiable, Equatable {
    let event: StreakEvent
    let count: Int
    var id: String { event.id }
}

/// «Jolly earned» / «Jolly used» pop-up, at the first opening after the event, never repeated (D-038).
/// **Provisional** (T-006): a vignette with the existing tokens and pieces of the celebration; shape, motion
/// and final texts come from the design (T-005). Closes on tap or by itself after a few seconds.
struct JollyPopup: View {
    let item: JollyPopupItem
    let onClose: () -> Void

    @Environment(\.manga) private var c
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var closing = false
    @State private var pop: CGFloat = 0.7

    private var earned: Bool { item.event.kind == .jollyEarned }

    private var title: String {
        if item.count > 1 { return L10n.format(earned ? "pop.earned.many" : "pop.used.many", "\(item.count)") }
        return L10n.text(earned ? "pop.earned.title" : "pop.used.title")
    }

    /// Streak line («15 GIORNI DI FILA» / «SERIE DI 22 GIORNI SALVA»).
    private var streakLine: String { L10n.format(earned ? "pop.earned.body" : "pop.used.body", "\(item.event.streak)") }
    /// Jollies available now.
    private var jollyLine: String { L10n.format("pop.jolly.left", "\(item.event.jolly)") }

    var body: some View {
        ZStack {
            c.paper.opacity(0.94)
            VStack(spacing: 18) {
                FlameIcon(kind: .jolly)
                    .frame(width: 64, height: 78)
                    .scaleEffect(pop)
                AntonText(title, 32, tracking: 0.02)
                    .manga(rotate: -5, skew: -10)
                TagText(text: streakLine, size: 18, tracking: 0.12, foreground: c.paper, background: earned ? c.red : c.ink)
                    .manga(rotate: -3, skew: -10)
                AntonText(jollyLine, 22, tracking: 0.04)
                    .manga(rotate: -3, skew: -8)
            }
            .opacity(shown ? 1 : 0)
            .scaleEffect(closing ? 0.96 : 1)
        }
        .ignoresSafeArea()
        .opacity(closing ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture { close() }
        .sensoryFeedback(earned ? .success : .warning, trigger: shown)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(streakLine). \(jollyLine)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(L10n.text("party.close.vo"))
        .task {
            if reduceMotion {
                pop = 1
                withAnimation(.easeOut(duration: 0.3)) { shown = true }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { shown = true }
                withAnimation(.spring(duration: 0.5, bounce: 0.45).delay(0.05)) { pop = 1 }
            }
            try? await Task.sleep(for: .seconds(4))
            // taken off screen meanwhile (the goal celebration came first): it comes back later, not closed
            guard !Task.isCancelled else { return }
            close()
        }
    }

    private func close() {
        guard !closing else { return }
        withAnimation(.easeIn(duration: 0.3)) { closing = true }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            onClose()
        }
    }
}

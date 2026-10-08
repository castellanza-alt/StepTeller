import ActivityKit
import SwiftUI
import WidgetKit
import StepTellerCore

@main
struct StepTellerWidgets: WidgetBundle {
    var body: some Widget { TreadmillLiveActivity() }
}

/// Live Activity sul Blocco schermo e nella Dynamic Island: minuti restanti con conto alla rovescia.
struct TreadmillLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TreadmillActivityAttributes.self) { context in
            LockScreenView(state: context.state, goal: context.attributes.goal)
                .activityBackgroundTint(Theme.bg)
                .activitySystemActionForegroundColor(Theme.accent)
        } dynamicIsland: { context in
            let s = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(s.gait.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(2)
                        .foregroundStyle(Theme.accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(ItalianFormat.number(s.speed, decimals: 1)) km/h").font(.system(size: 13, weight: .medium))
                }
                DynamicIslandExpandedRegion(.center) {
                    CountdownText(state: s, size: 40)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(s.finished ? "Obiettivo chiuso" : "mancano \(ItalianFormat.integer(s.remainingSteps)) passi")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "figure.run").foregroundStyle(Theme.accent)
            } compactTrailing: {
                CountdownText(state: s, size: 13).frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "figure.run").foregroundStyle(Theme.accent)
            }
        }
    }
}

/// Conto alla rovescia (m:ss) o «Fatto».
private struct CountdownText: View {
    let state: TreadmillActivityAttributes.ContentState
    let size: CGFloat

    var body: some View {
        if state.finished || state.endDate <= Date() {
            Text("Fatto").font(.system(size: size, weight: .light))
        } else {
            Text(timerInterval: Date()...state.endDate, countsDown: true)
                .font(.system(size: size, weight: .light)).monospacedDigit()
                .multilineTextAlignment(.center)
        }
    }
}

private struct LockScreenView: View {
    let state: TreadmillActivityAttributes.ContentState
    let goal: Int

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MINUTI SUL TAPPETO")
                    .font(.system(size: 10, weight: .semibold)).tracking(2.4).foregroundStyle(Theme.soft)
                CountdownText(state: state, size: 44).foregroundStyle(Theme.ink)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(ItalianFormat.number(state.speed, decimals: 1)) km/h")
                    .font(.system(size: 17, weight: .medium)).foregroundStyle(Theme.ink)
                Text(state.gait.uppercased())
                    .font(.system(size: 10, weight: .semibold)).tracking(2.4).foregroundStyle(Theme.accent)
                Text(state.finished ? "obiettivo chiuso" : "mancano \(ItalianFormat.integer(state.remainingSteps)) passi")
                    .font(.system(size: 12)).foregroundStyle(Theme.soft)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
    }
}

#if DEBUG
import Foundation
import StepTellerCore

/// Fake provider, **Debug builds only** (simulator screenshots: the simulator has no Health data).
/// Enabled by the launch argument `-stepteller.debugSteps 7200`. Absent from shipped (Release) builds.
final class DebugStepsProvider: StepsProvider, @unchecked Sendable {
    let value: Int?
    init(value: Int?) { self.value = value }
    var isAvailable: Bool { true }
    func requestAccess() async {}
    func steps(from startOfDay: Date, to now: Date) async -> Int? { value }
    func observe(_ onChange: @escaping @Sendable () async -> Void) async {}
    func stopObserving() async {}
}

/// Fake history for the screenshots (Debug only): the last 24 days as in the mockups
/// (streak 22 with 1 Jolly spent), before that about 2 years of plausible data.
final class DebugHistoryProvider: HistoryProvider, @unchecked Sendable {
    let todaySteps: Int
    init(todaySteps: Int) { self.todaySteps = todaySteps }

    func dailyRecords(until now: Date) async -> [DayRecord] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        var out: [DayRecord] = []
        var seed: UInt64 = 42
        func rnd() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double((seed >> 33) % 10_000) / 10_000
        }
        for back in stride(from: 700, through: 0, by: -1) {
            guard let day = cal.date(byAdding: .day, value: -back, to: today) else { continue }
            var steps: Int
            if back == 0 { steps = todaySteps }
            else if back == 8 { steps = 7_900 }                       // the day saved by the Jolly
            else if back < 24 { steps = 10_300 + Int(rnd() * 2_400) } // recent streak
            else { steps = rnd() < 0.82 ? 10_000 + Int(rnd() * 3_500) : 4_000 + Int(rnd() * 5_500) }
            // 0.78 m per step: plausible km for the fake history
            out.append(DayRecord(day: day, steps: steps, km: Double(steps) * 0.00078))
        }
        return out
    }
}
#endif

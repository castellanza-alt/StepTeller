#if DEBUG
import Foundation
import StepTellerCore

/// Fornitore finto, **solo build Debug** (screenshot sul simulatore, che non ha dati di Salute).
/// Si attiva con l'argomento di avvio `-stepteller.debugSteps 7200`. Non esiste nelle build
/// distribuite (Release).
final class DebugStepsProvider: StepsProvider, @unchecked Sendable {
    let value: Int?
    init(value: Int?) { self.value = value }
    var isAvailable: Bool { true }
    func requestAccess() async {}
    func steps(from startOfDay: Date, to now: Date) async -> Int? { value }
    func observe(_ onChange: @escaping @Sendable () async -> Void) async {}
    func stopObserving() async {}
}

/// Storico finto per gli screenshot (solo Debug): ultimi 24 giorni come nei mockup
/// (streak 22 con 1 Jolly speso), prima circa 2 anni di dati verosimili.
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
            else if back == 8 { steps = 7_900 }                       // il giorno salvato dal Jolly
            else if back < 24 { steps = 10_300 + Int(rnd() * 2_400) } // streak recente
            else { steps = rnd() < 0.82 ? 10_000 + Int(rnd() * 3_500) : 4_000 + Int(rnd() * 5_500) }
            out.append(DayRecord(day: day, steps: steps, km: Double(steps) * 0.00078))
        }
        return out
    }
}
#endif

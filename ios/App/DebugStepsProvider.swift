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
#endif

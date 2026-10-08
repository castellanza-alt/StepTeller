import Foundation

/// Fornitore dei passi di oggi. In app è HealthKit; nei test e negli screenshot è finto.
public protocol StepsProvider: Sendable {
    /// `false` se il dispositivo non ha Salute: si resta in modalità manuale, senza errori.
    var isAvailable: Bool { get }
    /// Chiede il permesso di lettura (idempotente).
    func requestAccess() async
    /// Passi dall'inizio di `day` fino a `now`. `nil` = nessun campione o errore
    /// (iOS non distingue «nessun dato» da «permesso negato»).
    func steps(from startOfDay: Date, to now: Date) async -> Int?
    /// Chiamata ogni volta che Salute riceve nuovi passi, anche con l'app in background
    /// (Salute risveglia l'app al massimo ogni ora). L'adattatore segnala a iOS la fine del lavoro
    /// solo dopo che `onChange` è terminata.
    func observe(_ onChange: @escaping @Sendable () async -> Void) async
    func stopObserving() async
}

/// Origine del numero mostrato.
public enum StepsOrigin: Equatable, Sendable {
    case health
    case manual
}

/// Stato puro (testabile) della sorgente dei passi.
/// Regole: Salute → manuale → «Usa Salute»; la sovrascrittura scade al cambio di giorno;
/// nessun dato/errore ⇒ 0 passi, fonte «manuale» e avviso.
public struct StepsState: Equatable, Sendable {
    public private(set) var healthSteps: Int = 0
    public private(set) var override: Int?
    public private(set) var overrideDay: Date?
    public private(set) var lastUpdate: Date?
    /// Salute non ha restituito dati (vuoto, negato o errore): mostra l'avviso.
    public private(set) var noHealthData = false
    public private(set) var healthAvailable = true

    public init() {}

    public var origin: StepsOrigin {
        override != nil || noHealthData || !healthAvailable ? .manual : .health
    }
    public var steps: Int { override ?? (noHealthData ? 0 : healthSteps) }
    /// Avviso «Nessun dato da Salute…» solo se Salute esiste e non ha risposto.
    public var showsNoDataWarning: Bool { healthAvailable && noHealthData }

    public mutating func setHealthAvailable(_ value: Bool) { healthAvailable = value }

    /// Esito di una lettura da Salute (`nil` = nessun dato o errore).
    public mutating func applyHealth(_ value: Int?, at date: Date) {
        if let value, value > 0 {
            healthSteps = value
            noHealthData = false
        } else {
            healthSteps = 0
            noHealthData = true
        }
        lastUpdate = date
    }

    /// Sovrascrittura manuale di Will, valida per il giorno di `date`.
    public mutating func setManual(_ value: Int, at date: Date, calendar: Calendar) {
        override = max(0, value)
        overrideDay = calendar.startOfDay(for: date)
        lastUpdate = date
    }

    /// «Usa Salute»: toglie la sovrascrittura.
    public mutating func useHealth() {
        override = nil
        overrideDay = nil
    }

    /// Cambio di giorno: la sovrascrittura scade e i passi di ieri non valgono.
    /// Restituisce `true` se qualcosa è cambiato.
    @discardableResult
    public mutating func rollDay(now: Date, calendar: Calendar) -> Bool {
        guard let day = overrideDay, day != calendar.startOfDay(for: now) else { return false }
        useHealth()
        return true
    }
}

import Foundation
import StepTellerCore

/// Unit shown by app and widget: the choice in Settings (App Group), «automatic» follows the phone's
/// region (US or UK measurement system → miles). Speeds and distances stay in km inside.
enum Units {
    static var regionUsesMiles: Bool {
        let system = Locale.current.measurementSystem
        return system == .us || system == .uk
    }

    static var current: DistanceUnit { SharedStore.unitPreference.resolved(regionUsesMiles: regionUsesMiles) }
}

extension DistanceUnit {
    /// Catalog key of this unit: the kilometer text or its miles variant.
    func pick(_ km: String, _ mi: String) -> String { self == .miles ? mi : km }

    /// Distance in this unit with 1 decimal, as the km («6,7»).
    func distanceText(km: Double) -> String { LocalFormat.number(value(fromKm: km), decimals: 1) }

    /// Speed (km/h inside) in this unit with 1 decimal («4,0» km/h, «2,5» mph).
    func speedText(kmh: Double) -> String { LocalFormat.number(value(fromKm: kmh), decimals: 1) }
}

import ActivityKit
import Foundation

/// Dati della Live Activity «tappeto». File condiviso tra app e estensione.
struct TreadmillActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Quando finisce il tappeto, alla velocità scelta: il conto alla rovescia scende da solo.
        var endDate: Date
        var speed: Double
        var remainingSteps: Int
        /// «cammino» o «corsa».
        var gait: String
        /// Obiettivo chiuso.
        var finished: Bool
    }

    var goal: Int
}

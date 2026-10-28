import Foundation

/// Manual backup (Settings → Backup): the values the app keeps besides Health, in a JSON file the user saves
/// where they want. Never Health data: steps and workouts stay in Health and are reread from there.
/// Every field is optional: a value never saved is not written, and on import a missing value is not touched.
public struct BackupFile: Codable, Equatable, Sendable {
    public static let format = "neat-backup"
    public static let currentVersion = 1

    public var format = BackupFile.format
    public var version = BackupFile.currentVersion
    public var exportedAt: Date
    public var goal: Int?
    /// Always in km/h, like in the app.
    public var speed: Double?
    /// `UnitPreference` raw value.
    public var units: String?
    public var reminderOn: Bool?
    /// Minutes from midnight.
    public var reminderMinutes: Int?
    /// Day/night theme raw value.
    public var theme: String?
    public var streakStart: Date?
    public var goalHistory: GoalHistory?
    public var calibration: CalibrationResult?

    public init(exportedAt: Date) { self.exportedAt = exportedAt }

    public enum ReadError: Error, Equatable {
        /// Not a NEAT backup (other JSON or not JSON at all).
        case notABackup
        /// Made by a newer version of the app.
        case newerVersion
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    public static func decode(_ data: Data) throws -> BackupFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let file = try? decoder.decode(BackupFile.self, from: data), file.format == format else {
            throw ReadError.notABackup
        }
        guard file.version <= currentVersion else { throw ReadError.newerVersion }
        return file
    }

    /// Streak start after an import: the earliest of the two. The streak is computed from Health, so an earlier
    /// start only counts days that really happened; a later one would throw away a streak still going.
    public static func mergedStreakStart(current: Date?, imported: Date?) -> Date? {
        switch (current, imported) {
        case let (c?, i?): return min(c, i)
        default: return current ?? imported
        }
    }
}

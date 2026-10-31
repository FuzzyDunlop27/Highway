// Purpose: Codable shapes for Content/offline.json (decoded and checked now; used from 1D). Notes: docs/features/core-api.md
import Foundation

public struct OfflineContent: Codable, Sendable {
    public let schemaVersion: Int
    public let timeFactor: TimeFactorDef
    public let hordeAlert: HordeAlertDef
}

public struct TimeFactorDef: Codable, Sendable {
    public let defaultEnabled: Bool
    public let maxOfflineCreditHours: Double
    public let catchUpStepSeconds: Double
    public let productionEfficiency: Double
    public let queuesThatProgress: [String]
    public let combatWhileAway: Bool
    public let hordeClockAdvancesWhileAway: Bool
    public let clockBackwardsGrantsNothing: Bool
    public let welcomeBackMinAwaySeconds: Double
}

public struct HordeAlertDef: Codable, Sendable {
    public let defaultEnabled: Bool
    public let minAwayMinutes: Double
    /// [earliest, latest] minutes after leaving.
    public let notifyWindowMinutes: [Double]
    public let maxPerAbsence: Int
    public let quietHours: QuietHoursDef
    public let notificationText: String
}

public struct QuietHoursDef: Codable, Sendable {
    public let startHour: Int
    public let endHour: Int
}

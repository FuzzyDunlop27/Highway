// Purpose: Things that happened during a tick, for the App to draw (shots, deaths, warnings). Not saved. Notes: docs/features/core-api.md
import Foundation

public enum SimEvent: Equatable, Sendable {
    /// The next horde is coming from these edges in `seconds` in-game seconds.
    case hordeWarning(edges: [String], seconds: Double)
    case hordeStarted(day: Int, edges: [String], isBonus: Bool)
    case zombieSpawned(ZombieID)
    /// A tower fired at a zombie (hitscan: the damage is already applied).
    case shot(from: BuildingID, at: ZombieID)
    /// A trap (spikes) hurt a zombie standing on it.
    case trapHit(BuildingID, ZombieID)
    case zombieDied(ZombieID, defId: String, x: Double, y: Double)
    /// A zombie hit a building (walls, HQ, anything in the way).
    case buildingDamaged(BuildingID)
    /// A building reached 0 hp and became rubble.
    case buildingDestroyed(BuildingID)
    /// A defender holding a spot fired at a zombie.
    case defenderShot(from: DefenderID, at: ZombieID)
    case defenderKnockedOut(DefenderID)
    /// A defender finished training, or came back from being knocked out.
    case defenderReady(DefenderID)
    /// A scavenging run came home; its reward waits at the post.
    case runFinished(buildingId: BuildingID)
    case researchFinished(String)
    case hordeEnded(HordeResult)
}

public enum HordeResult: Equatable, Sendable {
    /// Every zombie died; the completion bonus was added.
    case held(bonus: Cost)
    /// The HQ fell; stored resources lost this much (economy.json hqFall).
    case hqFell(lost: Cost)
}

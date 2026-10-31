// Purpose: Turns Core's placement problems and command errors into short player-facing text. Notes: docs/features/input.md
import HoldoutCore

enum PlacementMessages {
    static func text(for problem: PlacementProblem, content: GameContent) -> String {
        switch problem {
        case .unknownBuilding(let id): "Unknown building: \(id)"
        case .offMap: "That spot is off the map."
        case .blockedTerrain: "Can't build on the highway or wreckage."
        case .occupied: "Something is already there."
        case .limitReached(let max): "Limit reached: \(max) allowed at this HQ level."
        case .needsHqLevel(let level): "Needs HQ level \(level)."
        case .needsBuilding(let id, let level): "Needs \(name(id, content)) level \(level)."
        case .needsResearch(let id): "Needs research: \(id)."
        case .notEnoughResources(let needed): "Not enough resources. Costs \(costText(needed))."
        }
    }

    static func text(for error: CommandError, content: GameContent) -> String {
        switch error {
        case .placement(let problem): text(for: problem, content: content)
        case .unknownBuildingID: "That building no longer exists."
        case .cannotDemolish(let defId): "The \(name(defId, content)) can't be demolished."
        case .invalidSpeed(let speed): "Speed \(speed)x isn't available."
        }
    }

    /// "50 scrap · 20 food", leaving out zero parts ("free" if both are zero).
    static func costText(_ cost: Cost) -> String {
        let parts = [cost.scrap > 0 ? "\(cost.scrap) scrap" : nil, cost.food > 0 ? "\(cost.food) food" : nil].compactMap { $0 }
        return parts.isEmpty ? "free" : parts.joined(separator: " · ")
    }

    static func name(_ defId: String, _ content: GameContent) -> String {
        content.buildingDef(defId)?.displayName ?? defId
    }
}

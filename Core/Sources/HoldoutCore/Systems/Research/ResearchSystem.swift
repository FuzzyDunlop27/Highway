// Purpose: Workshop research: start one item, count it down while the Workshop is staffed, store the result as Knowledge. Notes: docs/features/scavenging-research.md
import Foundation

public enum ResearchProblem: Error, Equatable, Sendable {
    case unknownItem
    case alreadyKnown
    /// One at a time (`research.json concurrentResearch`).
    case alreadyResearching
    /// No finished Workshop of the required level.
    case needsWorkshop
    /// The Workshop is there but not fully staffed.
    case workshopNotStaffed
    case needsHqLevel(Int)
    case notEnoughResources(needed: Cost)
}

enum ResearchSystem {
    /// The finished Workshop that meets `researchRequires`, if any.
    static func workshop(_ state: GameState, content: GameContent) -> Building? {
        let rule = content.research.researchRequires
        return state.base.buildings.first { $0.defId == (rule.building ?? "workshop") && $0.isComplete && $0.level >= (rule.level ?? 1) }
    }

    private static func isStaffed(_ workshop: Building, content: GameContent) -> Bool {
        workshop.staffed >= (content.buildingDef(workshop.defId)?.workers ?? 0)
    }

    static func problem(_ id: String, state: GameState, content: GameContent) -> ResearchProblem? {
        guard let item = content.research.items.first(where: { $0.id == id }) else { return .unknownItem }
        if state.group.knowledge.contains(id) { return .alreadyKnown }
        if state.base.research != nil { return .alreadyResearching }
        guard let shop = workshop(state, content: content) else { return .needsWorkshop }
        if !isStaffed(shop, content: content) { return .workshopNotStaffed }
        if state.base.hqLevel < item.requiredHq { return .needsHqLevel(item.requiredHq) }
        if !state.base.stock.covers(item.cost) { return .notEnoughResources(needed: item.cost) }
        return nil
    }

    static func start(_ id: String, state: inout GameState, content: GameContent) -> Result<CommandOutcome, CommandError> {
        if let problem = problem(id, state: state, content: content) { return .failure(.research(problem)) }
        let item = content.research.items.first { $0.id == id }!
        let shop = workshop(state, content: content)!
        let speed = content.buildingDef(shop.defId)?.level(shop.level)?.effects.researchSpeedMultiplier ?? 1
        let ticks = max(1, content.ticks(forSeconds: item.researchSeconds / max(speed, 0.01)))
        state.base.stock.scrap -= item.cost.scrap
        state.base.stock.food -= item.cost.food
        state.base.research = ActiveResearch(itemId: id, ticksLeft: ticks, ticksTotal: ticks, paid: item.cost)
        return .success(.researchStarted(cost: item.cost))
    }

    /// Counts down while the Workshop is finished and staffed; at 0 the item joins `Group.knowledge` (sorted).
    static func tick(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {
        guard var active = state.base.research else { return }
        guard let shop = workshop(state, content: content), isStaffed(shop, content: content) else { return }
        active.ticksLeft = max(0, active.ticksLeft - 1)
        if active.ticksLeft == 0 {
            state.group.knowledge = (state.group.knowledge + [active.itemId]).sorted()
            state.base.research = nil
            events.append(.researchFinished(active.itemId))
        } else {
            state.base.research = active
        }
    }

    /// The last Workshop is gone (demolished): research in progress is refunded in full and stops.
    static func workshopRemoved(_ state: inout GameState, content: GameContent) {
        guard let active = state.base.research, workshop(state, content: content) == nil else { return }
        state.base.stock = state.base.stock + active.paid
        state.base.research = nil
        StorageRules.clampToCaps(&state.base, content: content)
    }
}

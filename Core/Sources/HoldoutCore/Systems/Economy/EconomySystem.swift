// Purpose: Per-tick production (Farm → food, Scavenger Post → scrap) and survivor arrival. Notes: docs/features/economy.md
import Foundation

enum EconomySystem {
    /// Below this, leftover fractional production is treated as a whole unit (guards against 0.9999… from Double math).
    private static let roundingSlack = 1e-9

    static func tick(_ state: inout GameState, content: GameContent) {
        produce(&state.base, content: content)
        arriveSurvivors(&state, content: content)
    }

    /// Each finished building makes `productionPerMin × staffed / workers` per minute, stopped at the cap.
    static func produce(_ base: inout Base, content: GameContent) {
        let ticksPerMinute = Double(content.economy.ticksPerSecond) * 60
        for b in base.buildings where b.isComplete {
            guard let def = content.buildingDef(b.defId),
                  let output = def.level(b.level)?.effects.productionPerMin else { continue }
            let staffShare = def.workers == 0 ? 1 : Double(b.staffed) / Double(def.workers)
            for (kind, perMin) in output {
                base.productionCarry[kind, default: 0] += perMin * staffShare / ticksPerMinute
            }
        }
        for kind in ResourceKind.allCases {
            let carry = base.productionCarry[kind, default: 0]
            let whole = Int((carry + roundingSlack).rounded(.down))
            base.stock[kind] += whole
            base.productionCarry[kind] = max(0, carry - Double(whole))
            let cap = StorageRules.cap(kind, base: base, content: content)
            if base.stock[kind] >= cap {
                base.stock[kind] = cap
                base.productionCarry[kind] = 0
            }
        }
    }

    /// A survivor joins every `intervalSeconds` while housing is free and food ≥ `foodCost` (food is spent).
    /// The timer resets while housing is full; if food is short it waits at full until food is enough.
    static func arriveSurvivors(_ state: inout GameState, content: GameContent) {
        let rule = content.resources.survivorArrival
        let interval = content.ticks(forSeconds: rule.intervalSeconds)
        let housingFree = state.group.survivors < StorageRules.housing(base: state.base, content: content)
        guard housingFree || !rule.requiresFreeHousing else {
            state.base.survivorArrivalTicks = 0
            return
        }
        state.base.survivorArrivalTicks = min(state.base.survivorArrivalTicks + 1, interval)
        if state.base.survivorArrivalTicks >= interval && state.base.stock.food >= rule.foodCost {
            state.base.stock.food -= rule.foodCost
            state.group.survivors += 1
            state.base.survivorArrivalTicks = 0
        }
    }
}

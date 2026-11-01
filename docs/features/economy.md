# Feature: Economy

## Purpose
Farms make food, Scavenger Posts make scrap, Shelters raise the survivor cap, HQ/Storage raise storage caps, and new survivors arrive over time.

## Files involved
- `Core/Sources/HoldoutCore/Systems/Economy/EconomySystem.swift` — per-tick production + survivor arrival.
- `Core/Sources/HoldoutCore/Systems/Economy/StorageRules.swift` — food/scrap caps and housing.
- `Core/Sources/HoldoutCore/Systems/Economy/Staffing.swift` — gives survivors their worker slots (chosen counts, oldest first; see `jobs-defenders.md`).
- `Core/Sources/HoldoutCore/Systems/Economy/ResourceSnapshot.swift` — HUD numbers.
- `Core/Sources/HoldoutCore/Model/Base.swift` (stock, carry, arrival timer), `Model/Group.swift` (survivors).
- `Core/Sources/HoldoutCore/Content/ResourceDefs.swift`, `EconomyDefs.swift`.
- Tests: `Core/Tests/HoldoutCoreTests/Systems/Economy/EconomySystemTests.swift`

## Data files
- `Content/resources.json` → `starting`, `baseCap`, `survivorArrival.intervalSeconds` / `foodCost` / `requiresFreeHousing`.
- `Content/buildings.json` → level `effects.productionPerMin`, `storageAdded`, `housing`; building `workers`.
- `Content/economy.json` → `ticksPerSecond`, `speedOptions`, `maxFrameSeconds`.

## Key rules
- Output per minute = `productionPerMin × staffed / workers`; only finished buildings produce.
- Stock is whole numbers; fractions wait in `productionCarry`. At the cap, stock stops and the carry is dropped (overflow is lost). Stock never sits above the cap (demolishing a Storage trims it).
- Cap = `baseCap` + `storageAdded` of finished buildings. Housing = `housing` of finished buildings.
- **Staffing (2B, D-034):** each finished building gets `assignedWorkers` (default: all its slots) from the survivors left after defenders, trainees, runners and builders, oldest building first. The player lowers it with `Command.setWorkers`. Details: `jobs-defenders.md`.
- Survivor arrival: the timer runs while housing is free; at `intervalSeconds` a survivor joins if food ≥ `foodCost` (food is spent), else it waits until food is enough. Housing full resets the timer. While a horde is attacking the timer holds still (`pausedDuringHorde`).
- `foodUpkeepPerSurvivorPerMin` must stay 0: the loader rejects other values until upkeep is built.
- Output also × the research `productionMultiplier` (Agriculture: farms × 1.25, 2C). Not yet: offline efficiency (4B).

## Known issues
- (none yet)

## Change log
- 2026-11-01 — Chunks 2B/2C: chosen worker counts replace auto-staffing (D-034); Agriculture multiplier.
- 2026-10-31 — Survivor arrival pauses while a horde is active (1B).
- 2026-10-31 — Built production, caps, housing, survivor arrival, auto-staffing (1A).

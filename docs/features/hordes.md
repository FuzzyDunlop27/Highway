# Feature: Hordes (clock, warning, spawning, outcome)

## Purpose
Every so often a horde of zombies attacks the town from the map's edges. The player gets a warning with the edges, the horde spawns, and it ends either **held** (all zombies dead → bonus) or with the **HQ falling** (a setback, never game over, D-007).

## Files involved
- `Core/Sources/HoldoutCore/Systems/Hordes/HordeSystem.swift` — the clock, the warning, starting a horde, spawning; `startNow` (debug "Horde now").
- `Core/Sources/HoldoutCore/Systems/Hordes/HordeComposer.swift` — budget (day + town value), the zombie mix, the edges; `roll` = seeded pick.
- `Core/Sources/HoldoutCore/Systems/Hordes/HordeResolution.swift` — after combat: dead zombies (loot), 0-hp buildings → rubble, detects HQ fall / held.
- `Core/Sources/HoldoutCore/Systems/Hordes/HordeOutcome.swift` — held (bonus), HQ fall (loss, HQ restored), ending a horde (day + 1).
- `Core/Sources/HoldoutCore/Systems/Hordes/HordeStatus.swift` — HUD summary (`GameLoop.hordeStatus`).
- Model: `Model/HordeState.swift`, `Model/Zombie.swift`; events: `Simulation/SimEvent.swift`.
- Tests: `Core/Tests/HoldoutCoreTests/Systems/Hordes/HordeSystemTests.swift`, `HordeComposerTests.swift`, `HordeResolutionTests.swift` (`GameLoop.edited` test helper lives in `HordeSystemTests.swift`).

## Data files
- `Content/hordes.json` → `schedule` (first/interval/warning seconds), `budget`, `composition` (day ranges, `edgeCount`, `guaranteed`, `weights`), `spawnEdges`, `spawnIntervalSeconds`, `completionBonus`, `bonusHorde.advancesDay`.
- `Content/zombies.json` → `hp`, `threatCost`, `loot`.
- `Content/economy.json` → `hqFall` (`resourceLossPct`, `affects`, `hqRestoreHpPct`, `endsHorde`).
- `Content/maps/<map>.json` → `spawnEdges` rectangles.
- `Content/resources.json` → `survivorArrival.pausedDuringHorde`.

## Key rules
- **Clock:** counts down only inside ticks (app open, scaled by speed), frozen while a horde is active (`ticksUntilNext` is nil then). Day 1 waits `firstHordeSeconds`; later days wait `intervalSeconds` after the last horde **ended**.
- **Warning:** at `warningSeconds` left, the edges are picked (seeded) into `warningEdges` and `.hordeWarning` fires once. The horde then uses those edges.
- **Budget:** `round((baseBudget + budgetPerDay × (day − 1)) × clamp(1 + townValue / townValueDivisor, 1, townFactorMax))`. Town value = food + scrap `invested` in non-rubble buildings (starting buildings are free → 0; stored resources never count; repairs add to invested). Composed when the horde starts.
- **Mix:** the bracket whose `days` holds the day (past the end → last bracket). `guaranteed` first (sorted by id), paid from the budget; then weighted picks among types with weight > 0 that still fit the remaining budget, until none fit.
- **Spawning:** the first wave enters on the start tick, then every `spawnIntervalSeconds` **one zombie per active edge** (so they split evenly), on a random tile in the edge's rectangle, standing in the tile middle, with full hp.
- **Deaths:** zombies at hp ≤ 0 are removed; `loot × lootMultiplier` (rounded down) goes to stock, clamped to caps; `killed += 1`.
- **Rubble:** a non-HQ building at hp ≤ 0 becomes rubble (`isRubble`, hp 0, staffed 0); it does nothing until rebuilt (see construction.md → Repair).
- **HQ fall:** each `affects` resource loses `resourceLossPct` % (rounded down), the HQ comes back at `hqRestoreHpPct` % of its level's max hp, all zombies leave, the horde ends. Survivors are never lost.
- **Held:** queue empty and no zombies → `completionBonus` (base + perDay × day, × loot multiplier) clamped to caps; the event reports what was actually added.
- **After either end:** `active = nil`, `day += 1`, the clock is rescheduled next tick with `intervalSeconds`. A bonus horde (1D) leaves day and clock alone unless `bonusHorde.advancesDay`.
- **Survivors:** the arrival timer holds still during a horde (`pausedDuringHorde`).
- All randomness uses `state.random` via `HordeComposer.roll` (plain modulo, same on every platform).

## Known issues
- `economy.json hqFall.destroyedBuildingsBecomeRubble` is not read: destroyed buildings always become rubble.

## Change log
- 2026-10-31 — Built the horde clock, warning, composer, spawning, deaths/loot, rubble, HQ fall, held bonus (1B Core).

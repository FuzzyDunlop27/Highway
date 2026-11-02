# Feature: Construction (place / move / demolish)

## Purpose
The player places buildings and defenses on the grid, moves them, or demolishes them; the App's ghost preview asks Core whether a spot is valid.

## Files involved
- `Core/Sources/HoldoutCore/Systems/Construction/PlacementRules.swift` — ground check + rule check; `PlacementProblem`, `PlacementCheck`.
- `Core/Sources/HoldoutCore/Systems/Construction/ConstructionSystem.swift` — place, move, demolish (queues a build job).
- `Core/Sources/HoldoutCore/Systems/Construction/BuildQueue.swift` — slots, waiting queue, builders, start/finish/cancel jobs (D-033); `BuildQueueStatus.swift` — numbers for the HUD strip.
- `Core/Sources/HoldoutCore/Systems/Construction/UpgradeSystem.swift` — `Command.upgrade`, `UpgradeProblem`.
- `Core/Sources/HoldoutCore/Model/ConstructionJob.swift` — one job (build / upgrade / rebuild).
- `Core/Sources/HoldoutCore/Systems/Construction/RepairSystem.swift` — repair damaged buildings, rebuild rubble (`Command.repair`).
- `Core/Sources/HoldoutCore/Model/Building.swift`, `Model/GridPoint.swift`, `Model/NewGame.swift` (starting layout).
- `Core/Sources/HoldoutCore/Model/Facing.swift` — `Facing` (south/west/north/east), turned footprint size and tiles (`def.size(facing:)`, `building.footprintTiles(def)`).
- `Core/Sources/HoldoutCore/Systems/Construction/SpotFinder.swift` — `GameLoop.suggestSpot` (nearest spot that fits).
- `Core/Sources/HoldoutCore/Content/BuildingDefs.swift`, `Content/MapDef.swift`.
- `Content/maps/phase1_chicago.json` — the map new games use (D-044, `map-chicago.md`); `phase1_exit.json` — the old highway map (old saves, test fixture).
- Tests: `Core/Tests/HoldoutCoreTests/Systems/Construction/BuildQueueTests.swift`, `PlacementRulesTests.swift`, `ConstructionSystemTests.swift`, `RepairSystemTests.swift`, `FootprintRotationTests.swift`, `SpotFinderTests.swift`; `Content/StartingCompoundTests.swift` (13 × 9 ring on both maps + early-horde check)

## Data files
- `Content/buildings.json` → `footprint` (as facing south), `rotatable`, `rules.suggestSpotRadiusTiles`, `maxCountByHq`, `sharesCountWith`, `requires`, level 1 `cost` / `buildSeconds` / `hp` / `requiredHq`, `rules.demolishRefundPct`, `rules.cancelRefundPct`, `rules.constructionSlotsByHq` / `constructionQueueLength` / `buildersPerJob` / `buildDuringHorde`, `rules.repair`, `rules.rubble`, `startingLayout`.
- `Content/maps/phase1_exit.json` → `rows` + `legend` (`buildable`), `decorations`, `startingPositions`, `spawnEdges`.

## Key rules
- Grid y runs down; a footprint's origin is its top-left tile.
- A spot is bad if any footprint tile is off the map, on an unbuildable tile (highway lanes, highway crossing), on a decoration, or on another building. `badTiles` lists them.
- Rule checks, in order: HQ level ≥ L1 `requiredHq`, count < `maxCountByHq[hqLevel-1]` (walls share one count), `requires` (finished building at level, or research on the Group), cost affordable.
- Placing adds a build job. It starts (and pays the L1 cost) when a slot, a free builder and the money are all there, usually at once; then it builds for `buildSeconds`. Unfinished buildings don't produce or count for caps.
- Moving is free and instant (finished or not); it may overlap its own old tiles.
- **Facing (CORE-010):** `Command.placeBuilding(defId:at:facing:)` (default south) and `.moveBuilding(id:to:facing:)` (nil = keep). East/west swap width and height; north/south keep them. Only `rotatable` buildings turn; others are stored facing south whatever was asked. The origin is always the top-left tile of the *turned* footprint. Every footprint use in Core (placement, pathing, zombie hits, tower range middle, survivor strolling, tap lookup) goes through `building.footprintTiles(def)` / `size(def)`. `checkPlacement`/`checkMove` take the same facing.
- **Spot finder:** `GameLoop.suggestSpot(defId:facing:near:ignoring:)` → the top-left tile within `rules.suggestSpotRadiusTiles` whose footprint middle is closest to `near` and whose ground is free; ties go to the lower row, then lower column. Ground only (cost, limits, queue are `checkPlacement`'s job). Pass `ignoring:` the building being moved. Nil = nothing fits ("No room — expand your fence" in APP-006).
- **Starting compound:** a closed 13 × 9 ring of 40 Chain Fence pieces on both maps (Chicago x11–23, y13–21; highway x18–30, y15–23); the HQ and watchtower stayed where they were, so the HQ sits left of centre with more room on the east. Three Chicago props (junk pile, crates, a wreck) and one highway wreck moved out of the ring.
- Demolish refunds `demolishRefundPct` of `invested`, clamped to caps. The HQ can't be demolished. Starting-layout buildings were free, so they refund nothing.
- Ramps, side roads and the town road are buildable so players can wall them off; the highway itself isn't.

## Build queue and upgrades (chunk CORE-001, D-033)
- Slots: `constructionSlotsByHq[hq level − 1]` jobs run at once; up to `constructionQueueLength` more wait. Each running job borrows `buildersPerJob` survivors (`Staffing` hands out the rest). Jobs start oldest first; one that can't be paid yet is skipped. `buildDuringHorde: false` would stop new starts during a horde.
- Placement/upgrade/rebuild fail with `.queueFull` when slots and queue are full. `GameLoop.buildQueue` → slots, active, queued, free builders.
- `Command.upgrade(id)` → `.upgradeQueued(cost:)`: next level's `cost`, `buildSeconds`, `requiredHq` gate (`UpgradeProblem`: maxLevel, notFinished, alreadyWorking, needsHqLevel, queueFull, notEnoughResources). The building keeps working at its old level; level, hp and all effects (HQ caps/housing too) switch when it finishes. `invested` grows by the cost at start, so demolish refunds stay right. `GameLoop.upgradeProblem(id:)` / `upgradeCost(id:)` feed the future Upgrade button.
- `Command.cancelJob(buildingId:)` → `.cancelled(refund:)`: waiting = free; running = `cancelRefundPct` of its cost back. A cancelled new building disappears, a cancelled rebuild goes back to rubble, a cancelled upgrade leaves the old level.
- Rubble rebuild (`Command.repair`) is a `.rebuild` job. A building destroyed while a job runs loses the job; demolishing drops it.
- Save v3: `Base.jobs`; a v2 half-built building becomes a running paid job with 0 builders.
- Not yet: manual worker assignment (CORE-002), App panels (APP-002).

## Wall lines
- `GameLoop.planLine(defId:from:to:)` → `LinePlan` (path, buildable / alreadyBuilt / blocked tiles, total cost, problem, canBuild); `Command.placeLine` builds every buildable tile at once → `.placedLine(ids)`, or nothing if it can't afford the whole line. Path: straight, or an L along the longer axis first. Limit: tiles beyond the HQ-level cap are blocked (`problem = limitReached`) but the rest can still be built. Code: `Systems/Construction/WallLinePlanner.swift`; tests `WallLinePlannerTests.swift`.

## Repair (1B)
- `Command.repair(id)` works on a **damaged finished** building (hp < its level's max, not under construction) or on **rubble**. Buildings keep their level.
- Damaged: cost = level cost × `rules.repair.costPctOfLevelCost` % × missing-hp fraction, **rounded up** per resource; the building heals **at once** and keeps working (D-020). `minSeconds`/`timePctOfBuildTime` are kept for 1C, when repairs need builders.
- Rubble: cost = `invested` × `rules.rubble.rebuildCostPctOfInvested` % (rounded down); free starting buildings (invested 0) use their level cost instead. Time = `buildSeconds` × `rebuildTimePctOfInvested` % (the field name says "invested" but it is a share of build time).
- On success: pay at once, hp = max, cost added to `invested` (raises town value and demolish refunds). Rubble also runs a construction timer and does nothing until it ends.
- Errors (nothing changes): `unknownBuildingID`, `nothingToRepair` (full hp, or still being built/repaired), `notEnoughResources(needed:)`.
- 0-hp buildings become rubble in `HordeResolution` (see hordes.md). No builder limit until 1C.

## Known issues

## Change log
- 2026-11-02 — Ticket CORE-010: 2×1 footprints + facing/rotation, spot finder, 13 × 9 starting fence, wall limit +12, save v6 (D-046, D-048).
- 2026-11-01 — Chunk CORE-001: build slots, queue and builders, pay-on-start, upgrades, cancel, save v3 (D-033); queue-full is a `PlacementProblem`.
- 2026-10-31 — Wall lines: planLine + placeLine (all-or-nothing on cost).
- 2026-10-31 — Added repair / rubble rebuild (`RepairSystem`, 1B).
- 2026-10-31 — Damaged buildings now heal at once instead of going offline (a repaired Storage was deleting stock).
- 2026-10-31 — Built placement rules, place/move/demolish, build timers, Phase 1 map (1A).

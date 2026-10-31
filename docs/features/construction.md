# Feature: Construction (place / move / demolish)

## Purpose
The player places buildings and defenses on the grid, moves them, or demolishes them; the App's ghost preview asks Core whether a spot is valid.

## Files involved
- `Core/Sources/HoldoutCore/Systems/Construction/PlacementRules.swift` — ground check + rule check; `PlacementProblem`, `PlacementCheck`.
- `Core/Sources/HoldoutCore/Systems/Construction/ConstructionSystem.swift` — place, move, demolish, build countdown.
- `Core/Sources/HoldoutCore/Systems/Construction/RepairSystem.swift` — repair damaged buildings, rebuild rubble (`Command.repair`).
- `Core/Sources/HoldoutCore/Model/Building.swift`, `Model/GridPoint.swift`, `Model/NewGame.swift` (starting layout).
- `Core/Sources/HoldoutCore/Content/BuildingDefs.swift`, `Content/MapDef.swift`.
- `Content/maps/phase1_exit.json` — the map.
- Tests: `Core/Tests/HoldoutCoreTests/Systems/Construction/PlacementRulesTests.swift`, `ConstructionSystemTests.swift`, `RepairSystemTests.swift`

## Data files
- `Content/buildings.json` → `footprint`, `maxCountByHq`, `sharesCountWith`, `requires`, level 1 `cost` / `buildSeconds` / `hp` / `requiredHq`, `rules.demolishRefundPct`, `rules.repair`, `rules.rubble`, `startingLayout`.
- `Content/maps/phase1_exit.json` → `rows` + `legend` (`buildable`), `decorations`, `startingPositions`, `spawnEdges`.

## Key rules
- Grid y runs down; a footprint's origin is its top-left tile.
- A spot is bad if any footprint tile is off the map, on an unbuildable tile (highway lanes, highway crossing), on a decoration, or on another building. `badTiles` lists them.
- Rule checks, in order: HQ level ≥ L1 `requiredHq`, count < `maxCountByHq[hqLevel-1]` (walls share one count), `requires` (finished building at level, or research on the Group), cost affordable.
- Placing pays the full L1 cost at once and builds for `buildSeconds`; unfinished buildings don't produce or count for caps.
- Moving is free and instant (finished or not); it may overlap its own old tiles.
- Demolish refunds `demolishRefundPct` of `invested`, clamped to caps. The HQ can't be demolished. Starting-layout buildings were free, so they refund nothing.
- Ramps, side roads and the town road are buildable so players can wall them off; the highway itself isn't.
- Not yet (1C): build slots, queue, builders, upgrades.

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
- 2026-10-31 — Wall lines: planLine + placeLine (all-or-nothing on cost).
- 2026-10-31 — Added repair / rubble rebuild (`RepairSystem`, 1B).
- 2026-10-31 — Damaged buildings now heal at once instead of going offline (a repaired Storage was deleting stock).
- 2026-10-31 — Built placement rules, place/move/demolish, build timers, Phase 1 map (1A).

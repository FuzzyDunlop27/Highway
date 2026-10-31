# Feature: Construction (place / move / demolish)

## Purpose
The player places buildings and defenses on the grid, moves them, or demolishes them; the App's ghost preview asks Core whether a spot is valid.

## Files involved
- `Core/Sources/HoldoutCore/Systems/Construction/PlacementRules.swift` — ground check + rule check; `PlacementProblem`, `PlacementCheck`.
- `Core/Sources/HoldoutCore/Systems/Construction/ConstructionSystem.swift` — place, move, demolish, build countdown.
- `Core/Sources/HoldoutCore/Model/Building.swift`, `Model/GridPoint.swift`, `Model/NewGame.swift` (starting layout).
- `Core/Sources/HoldoutCore/Content/BuildingDefs.swift`, `Content/MapDef.swift`.
- `Content/maps/phase1_exit.json` — the map.
- Tests: `Core/Tests/HoldoutCoreTests/Systems/Construction/PlacementRulesTests.swift`, `ConstructionSystemTests.swift`

## Data files
- `Content/buildings.json` → `footprint`, `maxCountByHq`, `sharesCountWith`, `requires`, level 1 `cost` / `buildSeconds` / `hp` / `requiredHq`, `rules.demolishRefundPct`, `startingLayout`.
- `Content/maps/phase1_exit.json` → `rows` + `legend` (`buildable`), `decorations`, `startingPositions`, `spawnEdges`.

## Key rules
- Grid y runs down; a footprint's origin is its top-left tile.
- A spot is bad if any footprint tile is off the map, on an unbuildable tile (highway lanes, highway crossing), on a decoration, or on another building. `badTiles` lists them.
- Rule checks, in order: HQ level ≥ L1 `requiredHq`, count < `maxCountByHq[hqLevel-1]` (walls share one count), `requires` (finished building at level, or research on the Group), cost affordable.
- Placing pays the full L1 cost at once and builds for `buildSeconds`; unfinished buildings don't produce or count for caps.
- Moving is free and instant (finished or not); it may overlap its own old tiles.
- Demolish refunds `demolishRefundPct` of `invested`, clamped to caps. The HQ can't be demolished. Starting-layout buildings were free, so they refund nothing.
- Ramps, side roads and the town road are buildable so players can wall them off; the highway itself isn't.
- Not yet (1C): build slots, queue, builders, upgrades. Not yet (1B): repair, rubble.

## Known issues
- (none yet)

## Change log
- 2026-10-31 — Built placement rules, place/move/demolish, build timers, Phase 1 map (1A).

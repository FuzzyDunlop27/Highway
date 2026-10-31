# Feature: Combat

_Towers shooting zombies (this note), plus zombies bashing and traps (documented in `pathing.md`)._

## Purpose
Staffed towers shoot zombies in range during a horde, so a well-placed Watchtower or MG Nest holds the line.

## Files involved
- `Core/Sources/HoldoutCore/Systems/Combat/TowerFiring.swift` — each tick, finished + staffed towers whose turn it is shoot one zombie (hitscan).
- `Core/Sources/HoldoutCore/Systems/Combat/TargetingSystem.swift` — picks the zombie: `TargetingMode` (from JSON) + range check + tie-break.
- `Core/Sources/HoldoutCore/Systems/Combat/ZombieMovement.swift` — walking, bashing, traps: see `pathing.md`.
- Runs from `Simulation/GameLoop.swift` after `ZombieMovement`, before `HordeResolution` (which removes the dead and pays loot).
- Tests: `Core/Tests/HoldoutCoreTests/Systems/Combat/TargetingSystemTests.swift`, `TowerFiringTests.swift` (also holds `CombatFixtures.tower(...)`).

## Data files
- `Content/buildings.json` defenses → `targeting` (`single_nearest_to_hq` / `single_nearest`), `workers`, `footprint`; per level `effects.range` (tiles), `effects.damage` (per shot), `effects.fireRate` (shots per second).
- `Content/economy.json` → `ticksPerSecond` (turns fireRate into ticks between shots).

## Key rules
- **What is a tower:** any building whose current level's effects have `range`, `damage` and `fireRate`.
- **When it fires:** only if finished and not rubble (`isComplete`) and `staffed >= workers`. Garrisoned defenders counting as the worker is 1C (not built). Marksmanship range research is 1C (not built).
- **Fire timing (no saved cooldown):** `ticksPerShot = max(1, round(ticksPerSecond / fireRate))`; a tower fires on ticks where `(tick + towerID) % ticksPerShot == 0`. Derived from the tick and id only, so towers are staggered, deterministic, and save/load can't change their rhythm. Trade-off: a new tower may wait up to one period for its first shot, and fire rates are rounded to whole ticks (10/sec → 5 shots/s = every 2 ticks exactly).
- **Range:** straight-line distance in tiles from the middle of the tower's footprint to the zombie's (x, y); exactly at range counts.
- **Targets:** only zombies with hp > 0 in range.
  - `single_nearest_to_hq` → lowest flow-field cost to the HQ at the zombie's tile (field with path weight 1.0, the plain field; fetched once per tick from `FlowFieldCache`, only if such a tower shoots).
  - `single_nearest` → closest to the tower.
  - Unknown or missing `targeting` → behaves like `single_nearest` (no crash).
  - Ties → lower zombie id.
- **Hitscan:** `damage` is subtracted at once (hp may go below 0) and `SimEvent.shot(from:at:)` is emitted. Towers act in building order; a zombie at hp ≤ 0 is never picked again in the same tick.

## Traps and bashing
- Barbed wire (`slowPct`), spikes (`dps`), and zombies hitting buildings live in `ZombieMovement`; see `pathing.md`.

## Known issues
- (none yet)

## Change log
- 2026-10-31 — Created for 1B task B6: tower targeting (nearest-to-HQ / nearest) and stateless staggered firing.

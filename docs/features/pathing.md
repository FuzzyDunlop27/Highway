# Feature: Pathing (flow field), zombie movement, wall bashing, traps

## Purpose
Zombies walk toward the HQ along the cheapest route, prefer weak walls over strong ones, bash whatever blocks them, and are hurt or slowed by traps they walk over.

## Files involved
- `Core/Sources/HoldoutCore/Systems/Pathing/FlowField.swift` — Dijkstra from the HQ: `cost`, `distance(at:)`, `nextStep(from:)`; shared rules `blocks`, `isWall`, `hpSteps`.
- `Core/Sources/HoldoutCore/Systems/Pathing/FlowFieldCache.swift` — one field per `pathCostWeight`, rebuilt only when buildings change (owned by `GameLoop.flowFields`, not saved).
- `Core/Sources/HoldoutCore/Systems/Combat/ZombieMovement.swift` — the per-tick zombie loop and walking; also `ZombieClock` (per-tick whole amounts, event throttle) and `BuildingTileIndex` (tile → building).
- `Core/Sources/HoldoutCore/Systems/Combat/WallBashing.swift` — what a blocked zombie attacks, and the damage.
- `Core/Sources/HoldoutCore/Systems/Combat/Traps.swift` — spikes damage, barbed-wire slow, trap wear.
- Tests: `Core/Tests/HoldoutCoreTests/Systems/Pathing/FlowFieldTests.swift`, `Systems/Combat/ZombieMovementTests.swift`, helpers in `Systems/Combat/CombatTestSupport.swift`.

## Data files
- `Content/hordes.json` → `pathing.openTileCost`, `pathing.wallTileCostPerHp`, `pathing.buildingTileCostPerHp`.
- `Content/zombies.json` → `speed`, `damageVsBuildingsPerSec`, `wallBashMultiplier`, `pathCostWeight`.
- `Content/buildings.json` → `blocksPath` (`"bashable"` = wall, `false` = trap), level `hp`, `effects.slowPct`, `effects.dps`, `durabilityLossPerZombieSecond`, `footprint`.
- `Content/economy.json` → `ticksPerSecond`. `Content/maps/*.json` → `decorations` (impassable).

## Key rules
- Field: Dijkstra from the HQ's tiles (cost 0) over the whole map, 8 neighbors. Stepping onto a tile costs `openTileCost`; a standing (not rubble) blocking building adds `hp × costPerHp × weight` (walls use `wallTileCostPerHp`, everything else `buildingTileCostPerHp`). Diagonal steps cost √2 × that. Traps and rubble add nothing. Decorations are impassable. All terrain (highway too) is walkable.
- The hp part is rounded **up to whole `openTileCost` steps** (`hpSteps`), so a field only changes when a wall loses/gains a whole step of cost (20 hp with today's numbers). The cache keys on that, so it rebuilds rarely, and the field is still a pure function of the state: a loaded save gives identical paths.
- No corner-cutting: a diagonal step is not allowed past a decoration or blocking building (HQ included) on either side.
- `nextStep` = the allowed neighbor with the lowest (its cost + cost to step onto it); fixed neighbor order (E, S, W, N, then diagonals) breaks ties.
- Buildings under construction already block (they have full hp while scaffolded); only finished traps work.
- Each tick, per living zombie in array order: (1) a finished, standing trap on its tile acts; (2) if the HQ is next to it (8 neighbors) or `nextStep` holds a blocking building, it attacks that (`attacking` = its id) and settles into its own tile's middle; (3) otherwise it walks toward the middle of `nextStep` at `speed / ticksPerSecond` × (1 − `slowPct`/100 on barbed wire). `heading` points where it walks/attacks.
- Bash damage per second = `damageVsBuildingsPerSec` × `wallBashMultiplier` (walls only; not the HQ or other buildings). Building hp is a whole number, so a zombie deals floor((t+1)·r) − floor(t·r) per tick (r = rate/tps, t = tick + zombie id): exact over every second, no saved remainder. Trap wear uses the same rule.
- Spikes: `dps`/tps per tick to each zombie on them. Any trap with `durabilityLossPerZombieSecond` (spikes and barbed wire) loses that per zombie-second. Hp clamps at 0.
- Never removes dead zombies or makes rubble (HordeResolution does). `.buildingDamaged` / `.trapHit` are sent about once per second per zombie ((tick + id) % tps == 0).
- No randomness used.

## Known issues
- Zombies don't push each other; many can stand on one tile.
- A zombie stops for a 0-hp building until HordeResolution (same tick) turns it to rubble.

## Change log
- 2026-10-31 — Created for milestone 1B (B4 flow field, B5 movement, bashing, traps).

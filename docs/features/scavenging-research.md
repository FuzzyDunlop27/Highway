# Feature: Scavenging runs and research (chunk CORE-003)

## Purpose
Send survivors on timed runs for loot, and research three upgrades at the Workshop. Both only run on Core's ticks, so a later catch-up (CORE-004) can advance them too.

## Files involved
- `Core/Sources/HoldoutCore/Systems/Scavenging/ScavengingSystem.swift` — start, tick, collect, `RunProblem`.
- `Core/Sources/HoldoutCore/Systems/Research/ResearchSystem.swift` — start, tick, `ResearchProblem`.
- `Core/Sources/HoldoutCore/Systems/Research/ResearchEffects.swift` — tower range bonus and production multiplier from `Group.knowledge`.
- `Core/Sources/HoldoutCore/Model/ScavengingRun.swift` (`ScavengingRun`, `ActiveResearch`), `Model/Base.swift` (`runs`, `research`), `Model/Building.swift` (`heldReward`), `Model/Group.swift` (`knowledge`).
- Used by `TowerFiring` (range), `EconomySystem` and `ResourceSnapshot` (farm output), `PlacementRules` (wall_metal needs the research).
- Tests: `Core/Tests/HoldoutCoreTests/Systems/Scavenging/ScavengingTests.swift`, `Systems/Research/ResearchTests.swift`.

## Data files
- `Content/buildings.json` → scavenger `runs.types` (`durationSeconds`, `survivorsSent`, `cost`, `reward`), level `effects.runsUnlocked`, `runRewardMultiplier`; workshop `effects.researchSpeedMultiplier`.
- `Content/research.json` → `items` (`cost`, `researchSeconds`, `requiredHq`, `effect`), `researchRequires`, `concurrentResearch` (kept at 1).

## Key rules
- **Runs:** `Command.startRun(buildingId, runId)` on a finished Scavenger Post: the run must be in the level's `runsUnlocked`, the post has no run out, enough survivors (`survivorsSent`) are free (workers step aside), and the food cost is affordable (paid at the start). The survivors are away (not working, not at risk, no matter what a horde does) until the timer ends.
- **Reward:** when a run ends, `reward × runRewardMultiplier` (the post's level, rounded down per resource) is added to `Building.heldReward` and waits there. `Command.collectRun(buildingId)` moves what fits under the storage caps; the rest stays at the post. Several finished runs add up. Demolishing the post brings survivors home and pays out the held reward (what fits).
- **Research:** `Command.startResearch(id)`: needs a finished Workshop at the required level that is fully staffed, the item's `requiredHq`, the cost (paid at the start), nothing else researching, and the item not already known. Time = `researchSeconds ÷ researchSpeedMultiplier` (Workshop level). It only counts down while the Workshop is finished and staffed. At the end the id joins `Group.knowledge` (sorted; carries to future bases). Demolishing the last Workshop refunds research in progress.
- **Effects:** `metal_fortification` makes `wall_metal` placeable (existing `requires.research`); `marksmanship` adds the value to the range of the listed towers (`GameLoop.towerRange(id:)` gives the number to draw); `agriculture` multiplies the listed buildings' output (farms × 1.25), also in the HUD rates.
- Not built (by scope): risk of losses on runs, more research items, cancelling research.

## Known issues
- No App UI yet (APP-002). `GameLoop.runProblem`, `researchProblem`, `trainingProblem` give the reason a button would be greyed out.

## Change log
- 2026-11-01 — Chunk CORE-003: scavenging runs with held rewards, Workshop research with three effects; save v5 (D-035).

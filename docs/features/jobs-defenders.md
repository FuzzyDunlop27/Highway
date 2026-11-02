# Feature: Jobs and defenders (chunk CORE-002)

## Purpose
The player chooses how many survivors work in each building, and the Barracks trains defenders who garrison towers or hold a spot and fight.

## Files involved
- `Core/Sources/HoldoutCore/Systems/Jobs/Roster.swift` — who is where; `PopulationSnapshot` (`GameLoop.population`).
- `Core/Sources/HoldoutCore/Systems/Economy/Staffing.swift` — hands out worker slots from the chosen counts.
- `Core/Sources/HoldoutCore/Systems/Jobs/WorkerAssignment.swift` — `Command.setWorkers`, `JobsProblem`.
- `Core/Sources/HoldoutCore/Systems/Jobs/DefenderTraining.swift` — Barracks queue (`Command.trainDefender`, `.cancelTraining`), `TrainingProblem`.
- `Core/Sources/HoldoutCore/Systems/Jobs/DefenderPosts.swift` — `.garrison`, `.holdSpot`, `.recallDefender`, `DefenderProblem`.
- `Core/Sources/HoldoutCore/Systems/Jobs/DefenderCombat.swift` — hold-spot shooting, zombies hurting defenders, knock-out and return, garrison damage boost (read by `TowerFiring`).
- `Core/Sources/HoldoutCore/Model/Defender.swift` (`Defender`, `TrainingJob`), `Model/Base.swift` (`defenders`, `training`), `Model/Building.swift` (`assignedWorkers`).
- Tests: `Core/Tests/HoldoutCoreTests/Systems/Jobs/` (`WorkerAssignmentTests`, `DefenderTrainingTests`, `DefenderPostsTests`, `JobsTestSupport`).

## Data files
- `Content/units.json` → defender `hp`, `range`, `damage`, `fireRate`, `training` (`cost`, `trainSeconds`, `consumesSurvivors`), `garrison` (`allowedIn`, `towerDamageMultiplier`), `knockedOutSeconds`.
- `Content/buildings.json` → Barracks `effects.maxDefenders`, `trainingQueueLength`, `trainTimeMultiplier`; building `workers`; `rules.cancelRefundPct`.
- `Content/zombies.json` → `damageVsUnitsPerSec`, `attackRange` (how zombies hurt a defender on a spot).

## Key rules
- **Everyone is in exactly one place:** working, building (borrowed by a construction job), away (CORE-003 runs), a defender, in training, or idle. `Roster.snapshot` adds up to `survivors`. Defenders and trainees still count toward housing (they stay in `Group.survivors`).
- **Order of claims (D-034):** defenders, trainees and runners come off the top, then builders, then workers get whoever is left (oldest building first). So a new command (train, send a run) never needs the player to un-assign anyone first: workers step aside, like they already do for builders.
- **Workers:** `Command.setWorkers(id, count)`, 0 up to the building's `workers`. `assignedWorkers == nil` means "full" (new buildings fill themselves, so the game still just works). Output scales with `staffed / workers`. Errors: `.jobs(.notAWorkplace)`, `.jobs(.tooManyWorkers)`, `.unknownBuildingID`.
- **Training:** needs a finished Barracks. The cost and one survivor are taken when queued (not when it starts). Queue length and `maxDefenders` (defenders + queued) come from the Barracks level. Only the first job counts down, and only while the Barracks is staffed; time = `trainSeconds × trainTimeMultiplier`. Cancel: a waiting job refunds everything, the one in progress refunds `cancelRefundPct`. Demolishing the Barracks refunds the whole queue.
- **Garrison:** a defender in a `garrison.allowedIn` tower counts as that tower's worker (the civilian who worked there is freed) and the tower's damage × `towerDamageMultiplier`. One defender per worker slot. A tower that turns to rubble or is demolished sends its defenders back to the HQ. Garrisoned defenders can't be hurt.
- **Hold a spot:** stands on a map tile and shoots the nearest zombie in `range` (lower id on ties) on the same staggered rhythm as towers. Every living zombie within its `attackRange` of the spot hurts the defender by `damageVsUnitsPerSec`.
- **Knocked out:** at 0 hp it is out for `knockedOutSeconds` (no orders accepted), then returns at the HQ with full hp. It never dies and still counts against `maxDefenders`.
- Tick order in `GameLoop.step`: build queue → release broken garrisons → training → runs → research → Staffing → economy → horde → zombies → towers → defenders → resolution.

## Known issues
- A hurt defender doesn't heal until it is knocked out and returns (no rule for it yet; balance question).
- No App UI yet (APP-002).

## Change log
- 2026-11-01 — Chunk CORE-002: worker counts, Barracks training, garrison, hold spot, knock-out; save v4 (D-034).

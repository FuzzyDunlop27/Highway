# BUILD-QUEUE — build chunks, dependencies, status

_Label = wave + track (1A, 2A, 1B…). Wave 1 chunks can be done in any order, any time. Wave N needs ALL chunks of waves below N done, unless a chunk's "Needs" says otherwise. Mirror status changes into the Craft log._

_Seeded 2026-10-31 from `PHASE1-TASKS.md` 1C–1E and STATUS open questions. Done so far (milestones, older scheme): 1A, 1V, 1B, isometric placement (D-022), wall-line tool (D-024)._

| Chunk | Goal | Needs | Status |
|---|---|---|---|
| 1A | Art: realistic walker static cutouts (Codex) | — | Done |
| 2A | Art: ZWALK-1 realistic walker limb animation | 1A only | In progress — ZWALK-1M waiting for owner FBX downloads |
| 1B | Core: upgrades + build queue + builders | — | Ready |
| 1C | App: speed buttons + menu thumbnails | — | Ready |
| 1D | Art: realistic static walker pilot | — | Done — 2026-10-31 |
| 2B | Core: jobs (manual workers) + defenders | 1B only | Blocked by 1B |
| 2C | Core: scavenging runs + research stub | 1B only | Blocked by 1B |
| 3B | App: all 1C panels + 1C exit check | 1B, 2B, 2C (not the A art track) | Blocked by 1B, 2B, 2C |
| 4B | Core: offline catch-up, tamper guard, bonus horde, settings in save | 3B (not the A art track) | Blocked by 3B |
| 5B | App: settings, welcome back, Horde Alerts, Engage + 1D exit check | 4B | Blocked by 4B |
| 6B | Art swap, balance pass, TestFlight (owner-led) | 5B (A art track optional) | Blocked by 5B |

Track A = zombie art (details at the bottom of this file). Track B = 1C–1E gameplay. Track C = small parallel side work.

**Save versions:** the save is v2 now. Each Core chunk that changes saved data bumps the version by one, adds a migration, and adds a test that decodes a sample from the previous version. If 2B and 2C run at the same time, whichever merges second rebases onto the other's version (for example v4 instead of v3).

## Chunk details

### 1B — Core: upgrades + build queue + builders
- **Goal:** buildings level up 1→3, and construction is limited by build slots and free builders, the way `buildings.json rules` describes.
- **Needs:** nothing.
- **Scope (Core only):**
  - **Upgrades:** `Command.upgrade(id)`. Pays the next level's `cost`, checks `requiredHq`, takes `buildSeconds`. The building keeps working during its upgrade at its old level, and new-level effects (including HQ caps/housing) apply when it's done. `invested` grows so demolish refunds stay right.
  - **Build queue:** `rules.constructionSlotsByHq` active jobs, up to `constructionQueueLength` queued. The cost is paid when a job *starts*, not when it's queued. A queued job starts by itself when a slot, a free builder and the resources are all available. Each active job borrows `buildersPerJob` idle survivors until it's done. Commands: cancel a queued job (no charge) and cancel an active one (refund per a new JSON field, if you need one).
  - This replaces the timer-only build from D-012. Add a DECISIONS entry saying which entry it replaces.
  - Placement checks (`checkPlacement`, wall-line `planLine`/`placeLine`) still answer "is the spot valid?". Queue-full becomes a new `PlacementProblem` case.
  - Save: bump the version, and migrate in-progress builds into active jobs.
- **Do NOT build:** manual job assignment (2B), App UI (3B), offline catch-up (4B).
- **Exit check:** `cd Core && swift test` passes, with new tests for: upgrade cost/time/HQ gate, effects applying only when done, slot limit per HQ level, queue auto-start, pay-on-start, builders borrowed and returned, cancel refunds, and migration of a v2 save that has a half-built building.
- **Start prompt:** "Implement chunk 1B: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/construction.md, and the 1B section of docs/BUILD-QUEUE.md only."

### 1C — App: speed buttons + menu thumbnails
- **Goal:** pause / 1x / 2x in the HUD, and real pictures on the build menu cards that still use placeholders.
- **Needs:** nothing. Core already has `Command.setSpeed` and `economy.json speedOptions`.
- **Scope (App only):** three HUD buttons built from `speedOptions` (no hardcoded speeds), with the current speed highlighted and remembered through the save. Finish the menu thumbnails listed in `docs/reviews/2026-10-31-art-and-build-review.md` / the UI kit handoff.
- **Do NOT build:** settings screen (5B), pause menu or inventory screens (suggest them in STATUS instead).
- **Exit check:** in the simulator, pause stops the horde clock and production, 2x doubles them, the speed survives a relaunch, and every build card shows a picture.
- **Start prompt:** "Implement chunk 1C: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/hud-ui.md, and the 1C section of docs/BUILD-QUEUE.md only."

### 2B — Core: jobs + defenders
- **Goal:** the player chooses how many survivors work each building, and the Barracks trains defenders who garrison towers or hold a spot.
- **Needs:** 1B only, because builders and workers share the same idle survivors.
- **Scope (Core only):**
  - **Jobs:** `Command.setWorkers(id, n)`. This replaces auto-staffing from D-011 (add a DECISIONS entry). New buildings still auto-fill from idle survivors, so it keeps "just working". Survivors split into working, building, away and idle.
  - **Defenders:** Barracks training uses `units.json training` (cost, `trainSeconds` × `trainTimeMultiplier`), `trainingQueueLength` and `maxDefenders`, and each defender uses up one survivor. **Garrison:** `garrison.allowedIn`, counts as the tower's worker, damage × `towerDamageMultiplier`. **Hold a spot:** shoots zombies in `range` with its own `damage`/`fireRate`. At 0 HP a defender is knocked out for `knockedOutSeconds`, then reappears at the HQ; it never dies.
  - Save migration.
- **Do NOT build:** permanent death (open balance question), App UI.
- **Exit check:** `swift test` passes, with tests for: worker limits, survivors never double-booked, staffing scaling production, training queue/cost/time, garrison counting as a worker with the boost, hold-spot combat, knock-out and return, and migration.
- **Start prompt:** "Implement chunk 2B: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/economy.md and combat.md, and the 2B section of docs/BUILD-QUEUE.md only."

### 2C — Core: scavenging runs + research stub
- **Goal:** send survivors on timed runs for loot, and research the 3 stub items at the Workshop.
- **Needs:** 1B only, because both use idle survivors and the same save. It can run in parallel with 2B.
- **Scope (Core only):**
  - **Runs:** one active run per post (`scavenger.runs.types`, `runsUnlocked` per level). Survivors are away (not working, not at risk) for `durationSeconds`. Rewards wait at the post and are multiplied by `runRewardMultiplier`; collecting clamps to caps and the remainder stays at the post.
  - **Research:** `research.json` items. Needs a finished, staffed Workshop; one at a time; `researchSeconds` ÷ `researchSpeedMultiplier`. Results go in `Group.knowledge` (they carry to future bases). Effects: unlock `wall_metal` (placement already checks for it), tower range +1, farm production × 1.25 (the Agriculture multiplier left out in milestone 1A).
  - Save migration.
- **Do NOT build:** risk of losses on runs (not in Phase 1), more research items.
- **Exit check:** `swift test` passes, with tests for: run timer/absence/reward/clamped collect, levels unlocking runs, research gate/time/effects, and Knowledge surviving a save round-trip.
- **Start prompt:** "Implement chunk 2C: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/economy.md, and the 2C section of docs/BUILD-QUEUE.md only."

### 3B — App: 1C panels + 1C exit check
- **Goal:** everything from 1B/2B/2C can be used on screen, and a 30-minute session feels like progress.
- **Needs:** 1B, 2B, 2C (not the A art track).
- **Scope (App only):** upgrade button (cost, `ui_level_badge` + tint per level), build-queue strip, worker −/+ on the building panel, Barracks panel (training queue), assigning a defender to a tower, defender units (directional) with a hold-spot command, Scavenger Post panel (start run, timer, collect), Workshop research panel. Optional, only if cheap: cosmetic survivors walking between the HQ and workplaces.
- **Do NOT build:** settings / welcome back / notifications (5B).
- **Exit check (milestone 1C):** a 30-minute session from a fresh start reaches HQ level 2–3 and faces brutes. Write down any balance knobs that feel off for 6B.
- **Start prompt:** "Implement chunk 3B: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/hud-ui.md and input.md, and the 3B section of docs/BUILD-QUEUE.md only."

### 4B — Core: time & alerts
- **Goal:** time away counts (when the setting is on), and a Horde Alert leaves a frozen bonus horde waiting.
- **Needs:** 3B (so every queue that catch-up has to advance already exists). Not the A art track.
- **Scope (Core only):**
  - **Catch-up:** `OfflineCatchUp.run(state, awaySeconds)`. The App passes the wall-clock gap; Core still reads no clock. Capped at `maxOfflineCreditHours`, run in `catchUpStepSeconds` steps, output × `productionEfficiency`. It advances everything in `queuesThatProgress`, with **no combat**, and **the horde clock doesn't move**. It returns a summary (resource changes, things finished).
  - **Tamper guard:** a negative gap grants nothing; forward jumps are capped.
  - **Bonus horde:** `spawnBonusHorde` / `engageBonusHorde`, using `hordes.json bonusHorde` (size ×, loot ×, `maxWaiting`, frozen until Engage).
  - **Settings in `GameState`:** time factor (default OFF), Horde Alerts (default from `offline.json`). Save migration.
- **Do NOT build:** notifications or UI.
- **Exit check:** `swift test` passes, with tests for: the cap, no combat while away, the tamper guard, catch-up giving the same result as live ticking with no horde, the bonus horde never moving on its own, and migration.
- **Start prompt:** "Implement chunk 4B: read AGENTS.md, docs/STATUS.md, docs/MAP.md, the 1D section of docs/PHASE1-TASKS.md, and the 4B section of docs/BUILD-QUEUE.md only."

### 5B — App: time & alerts
- **Goal:** the player can turn on the time factor and alerts, comes back to a summary, and can fight the bonus horde whenever they choose.
- **Needs:** 4B.
- **Scope (App only):** `SettingsView` (Time factor, Horde Alerts, View style); `WelcomeBackView` (when away ≥ `welcomeBackMinAwaySeconds`); `NotificationScheduler` (one alert in the random window, honoring `quietHours` and `minAwayMinutes`, and asking notification permission only when the toggle is first turned on); `AppLifecycle` (saves the wall-clock time, runs catch-up on launch, checks whether the alert fired); an Engage button while a bonus horde waits; a DEBUG "pretend I was away N hours" option.
- **Exit check (milestone 1D):** queue work, close the app for 4 hours (or use the debug option), reopen. The summary feels good, and ignoring the alert costs nothing.
- **Start prompt:** "Implement chunk 5B: read AGENTS.md, docs/STATUS.md, docs/MAP.md, the 1D App section of docs/PHASE1-TASKS.md, and the 5B section of docs/BUILD-QUEUE.md only."

### 6B — Art swap, balance, TestFlight (owner-led)
- **Goal:** Phase 1 is done: a 30-minute playtest leaves you wanting more, and coming back after 4 hours feels rewarding.
- **Needs:** 5B (A art track optional).
- **Scope:** final art import and anchor fixes in `presentation.json`; a balance pass with the `docs/features/balance.md` knobs; answering the STATUS balance questions. Food upkeep is one of them: Core rejects a non-zero `foodUpkeepPerSurvivorPerMin` until upkeep is built, so a "yes" needs a small Core task. Also: sound hooks, an app icon check, the two art-import questions in STATUS, and TestFlight (the owner signs in Xcode; the agent prepares the archive command and checklist).
- **Exit check:** the Phase 1 "done when" line in `PHASE1-PLAN.md`.
- **Start prompt:** "Start chunk 6B: read AGENTS.md, docs/STATUS.md, docs/features/balance.md, and the 6B section of docs/BUILD-QUEUE.md; walk me through the balance questions first."


## Chunk 1D — Realistic static walker [Done]
- **Goal:** demonstrate one realistic zombie end to end in the current game.
- **Needs:** none; owner-authorized art pilot, independent of milestone 1C.
- **Scope:** front/back transparent cutouts, base fallback, existing mirrored directions, matching canvas, importer, app build and simulator review. Sources and documentation in `HighwayHoldout_Iso_Art/realistic-walker/`.
- **What NOT to build:** limb animation, extra zombie types, top-down replacement, new gameplay or 3D rig.
- **Exit check:** build succeeds; all four directions render with clean transparency in the real app. Passed; `in-game-four-facings.png` uses a paused review fixture. Pre-test save restored byte-for-byte.
- **Start prompt (review only):** “Review chunk 1D realistic walker: open its README, preview and simulator capture; do not regenerate art.”

## Chunk 2A — Realistic walker limb animation [In progress]
- **Goal:** the walker visibly steps and swings its arms while moving; owner approved a Mixamo stock replacement in D-026.
- **Needs:** chunk 1A static walker only (also recorded as 1D by the static-art chat); no gameplay chunk dependency.
- **Scope:** six poses in each of two source facings, mirrored west, stable canvas/feet, distance-driven cached textures, static fallback, presentation JSON and simulator checks. First prototype is implemented; see `docs/features/zombie-walk-animation.md`.
- **What NOT to build:** runner/brute art, attack swings, top-down replacement, gameplay or save changes.
- **Exit check:** smooth alternating steps without scale/anchor jitter, clean four-facing movement, pause/attack stop, missing-frame fallback, build and Core tests pass; day-40 performance matches baseline. Initial build/tests and day-7 horde passed; full visual exit check remains.
- **Current route / dependency:** ZWALK-1M step 0 approved; prototype preserved in `c12e557`. Step 1 waiting for owner-provided in-place and preferably root-motion FBX files. See `docs/features/zombie-walk-mixamo.md`; browser control failed.
- **Start prompt:** “Continue ZWALK-1M / chunk 2A: read docs/features/zombie-walk-mixamo.md. Step 0 is approved in D-026; prototype is committed. Check walker-mixamo/source for FBX downloads, then perform steps 2–5. Walker only.”

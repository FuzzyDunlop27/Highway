# BUILD-QUEUE — build chunks, dependencies, status

_Label = wave + track (1A, 2A, 1B…). Wave 1 chunks can be done in any order, any time. Wave N needs ALL chunks of waves below N done, unless a chunk's "Needs" says otherwise. Mirror status changes into the Craft log._

_Seeded 2026-10-31 from `PHASE1-TASKS.md` 1C–1E and STATUS open questions. Done so far (milestones, older scheme): 1A, 1V, 1B, isometric placement (D-022), wall-line tool (D-024)._

| Chunk | Goal | Needs | Status |
|---|---|---|---|
| 1A | Art: realistic walker static cutouts (Codex) | — | Done |
| 2A | Art: ZWALK-1 realistic walker limb animation | 1A only | Retired 2026-11-01 — 2D walker frames no longer used (D-030); animated 3D zombie = 3M |
| 1B | Core: upgrades + build queue + builders | — | Done 2026-11-01 (D-033); 152 Core tests, save v3 |
| 1C | App: speed buttons + menu thumbnails | — | Done 2026-11-01 — speed buttons checked in the simulator; all 13 cards already had a picture (8 older iso renders; kit-style art is an art task) |
| 1D | Art: realistic static walker pilot | — | Done — 2026-10-31 |
| 2B | Core: jobs (manual workers) + defenders | 1B only | Done 2026-11-01 (D-034); save v4 |
| 2C | Core: scavenging runs + research stub | 1B only | Done 2026-11-01 (D-035); save v5; 198 Core tests |
| 3B | App: all 1C panels + 1C exit check | 1B, 2B, 2C (not the A art track) | Done 2026-11-01 — panels + 30-min playtest (agent-played, iPhone 18 Pro sim); notes in `docs/features/balance.md` "Playtest 3B" |
| 4B | Core: offline catch-up, tamper guard, bonus horde, settings in save | 3B (not the A art track) | Ready — 3B completed 2026-11-01; matches Craft Next |
| 5B | App: settings, welcome back, Horde Alerts, Engage + 1D exit check | 4B | Blocked by 4B |
| 6B | Art swap, balance pass, TestFlight (owner-led) | 5B, 3W (A art track optional) | Blocked by 5B and 3W |
| 1W | Core: food & water survival basics — water, upkeep, shortages, starter supplies, Garden, Well, Rain Catcher | 3B (done) | Specced 2026-11-01 — Ready (owner design, D-042) |
| 2W | Core: more food — canned goods + Cannery, Foraging, Hunting Lodge, Chicken Coop, Water Filter research | 1W | Specced 2026-11-01 — blocked by 1W |
| 1L | Core: spotters — Lookout Post, watched edges, warning time, Binoculars/Radio research | 3B (done) | Specced 2026-11-01 — Ready (owner design, D-042) |
| 3W | App: survival + spotter screens (water/canned in HUD, shortage banner, new panels, "Horde spotted" callout) | 1W, 2W, 1L | Specced 2026-11-01 — blocked by 1W, 2W, 1L |
| 1R | 3D: go/no-go spike on a real phone (DEBUG only) | — | Done 2026-11-01 — GO (D-028); iPhone 18 Pro 60 fps at 100 walkers with shadows |
| 2R | 3D: game playable in 3D, labeled boxes | 1R | Done 2026-11-01 — 3D view, ticker, camera, ModelRegistry (switch then removed by 6R) |
| 2M | 3D art: models for buildings, defenses, decorations (CC0, D-036) | 1R | Done 2026-11-01 — 19 models in App/Models, checker 19/19 (D-037) |
| 3R | 3D: placement, selection, walls | 2R | Done 2026-11-01 — ray picking, ghost/grid/footprint, wall line, outline + range ring, fading (D-032) |
| 3M | 3D art: animated zombies (+ survivors/defenders) | 2R, 2M | Done 2026-11-01 (D-038) — walk/attack/idle walker, runner/brute variants; Mixamo files local only; defenders still boxes |
| 1X | **Owner:** download assets (terrain textures, foliage, Mixamo humans, props) into the working folder | — | Ready — **you, not an agent**; checklist in `docs/OWNER-DOWNLOADS.md`, tick parts A–D. Start with A (terrain, unblocks 1T). Part C is now "more farmer clips first" (the farmer is in the game); other humans optional. Mirrored in the Craft doc "Owner Downloads" and board card |
| 1T | 3D: ground textures + map edge/road dressing | 2R; 1X part A | Specced 2026-11-01 — blocked by 1X part A |
| 2T | 3D: foliage and scatter (trees, bushes, grass, rocks) | 1T; 1X part B | Specced 2026-11-01 — blocked by 1T and 1X part B |
| 3M-2 | 3D art: human characters — defender + 4 survivor looks, task animations | 3M | Doing — first look in game 2026-11-01: farmer drawn for defenders + strolling survivors; more looks/clips (idle, carry, hammer…) still to come |
| 3M-2MH | MakeHuman trial: body-to-FBX script + medieval blacksmith profile | Owner request only; no wave dependency | Done 2026-11-01 — script/profile preparation; live MakeHuman export/import pending; does not complete 3M-2 |
| 3M-2MH-I | Install MakeHuman on the owner's Mac | Owner request only; no wave dependency | Done 2026-11-01 — modeling screen opened, scripting/FBX plugins loaded; real export/import next |
| 3M-2MH-V | Generate the real MakeHuman body and verify FBX in Blender | 3M-2MH, 3M-2MH-I only | Done 2026-11-01 — actual FBX/MHM + Blender model/preview; 2.44386 m, 28,796 triangles; look/optimization/rig still pending |
| 3M-2MH-L | Clothed blacksmith draft within mesh budget | 3M-2MH-V only | Done — 9,209 triangles, one atlas/material, FBX/GLB/blend + four previews, clean FBX reimport; rig/art polish pending |
| 3M-2MH-F | Farmer survivor model + committed portable review assets | Installed MakeHuman pipeline only | Done — 9,196 triangles; source + FBX/GLB/blend/atlas/four views; both model packages verified; delivery on chunk-3m-2-humans |
| 3M-3 | 3D: town life — survivors walk between home and work and do their jobs (Tropico feel) | 3M-2 | Specced 2026-11-01 (draft) — blocked by 3M-2 |
| 4R | 3D: combat effects, overlays, health bars | 3R, 3M | Done 2026-11-01 (D-039) — tracers, muzzle flash, goo, dust, shake, trap flash, health/progress bars, aiming turrets, warning arrows; day-40 ~60 fps (simulator) |
| 5R | 3D: performance pass, fps readout, Battery saver (3D is already the only view) | 4R | Ready |
| 6R | 3D: retire 2D | owner yes | Done 2026-11-01 early, owner's call (D-030) |

Track A = zombie art (details at the bottom of this file; 2D zombie art is retired, D-030). Track B = 1C–1E gameplay. Track C = small parallel side work.
Track R = 3D renderer code, track M = 3D models (owner picked the 3D option on 2026-11-01, D-027). R/M "Needs" lines override the wave rule: they depend only on each other, not on track B. Full scope, exit checks and start prompts: `docs/plans/3d-rendering-plan.md` §6. The 2D living-world plan (`docs/plans/living-world-plan.md`, chunks 1K 1N 1F 1U 1S 2F 2S) is parked, not queued.

**Save versions:** the save is v5 now (2B → v4, 2C → v5). 4B, 1W, 2W and 1L each add one; whichever merges first takes v6, the next v7, and so on (rebase onto the other's migration). Each Core chunk that changes saved data bumps the version by one, adds a migration, and adds a test that decodes a sample from the previous version. If 2B and 2C run at the same time, whichever merges second rebases onto the other's version (2B → v4, 2C → v5, or the other way round).

## Chunk details

### 1B — Core: upgrades + build queue + builders [Done 2026-11-01]
- **Result:** `BuildQueue`, `UpgradeSystem`, `ConstructionJob` in Core; `Command.upgrade` / `.cancelJob`; `PlacementProblem.queueFull`; `rules.cancelRefundPct` (75) added; save v3 with migration. Tests in `BuildQueueTests.swift` cover every exit-check item. Decision D-033 (replaces D-012). **Notes for 2B/3B:** until 2B, workers are auto-assigned, so builders come out of the whole survivor pool; 3B shows `loop.buildQueue`, `upgradeProblem(id:)`, `upgradeCost(id:)`. Repair of a damaged building is still instant (D-020).
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

### 1C — App: speed buttons + menu thumbnails [Done 2026-11-01]
- **Result:** `SpeedButtonsView` in the HUD, built from `speedOptions`, current speed highlighted, remembered by the save. Simulator (iPhone 18 Pro): pause froze the horde clock and production, 2x ran twice as fast, 2x survived a relaunch. Menu thumbnails: no card is a placeholder any more (13 of 13 resolve); five use kit art, eight use the old isometric renders from `Art/Menu`. Replacing those with kit-style 3/4 art is an art job for ChatGPT (`tools/import_art.py --view ui`), not code.
- **Goal:** pause / 1x / 2x in the HUD, and real pictures on the build menu cards that still use placeholders.
- **Needs:** nothing. Core already has `Command.setSpeed` and `economy.json speedOptions`.
- **Scope (App only):** three HUD buttons built from `speedOptions` (no hardcoded speeds), with the current speed highlighted and remembered through the save. Finish the menu thumbnails listed in `docs/reviews/2026-10-31-art-and-build-review.md` / the UI kit handoff.
- **Do NOT build:** settings screen (5B), pause menu or inventory screens (suggest them in STATUS instead).
- **Exit check:** in the simulator, pause stops the horde clock and production, 2x doubles them, the speed survives a relaunch, and every build card shows a picture.
- **Start prompt:** "Implement chunk 1C: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/hud-ui.md, and the 1C section of docs/BUILD-QUEUE.md only."

### 2B — Core: jobs + defenders [Done 2026-11-01]
- **Result:** `Command.setWorkers`, `.trainDefender`, `.cancelTraining`, `.garrison`, `.holdSpot`, `.recallDefender` in Core (`Systems/Jobs/`, notes `docs/features/jobs-defenders.md`, D-034). `GameLoop.population` (working / building / away / defenders / training / idle, adds up to survivors), `trainingProblem()`. New events `defenderShot`, `defenderKnockedOut`, `defenderReady`. Save v4 (a v3 town keeps its full staffing). 46 new tests across 2B and 2C. **Notes for 3B:** `Building.assignedWorkers == nil` means full; defenders are `loop.state.base.defenders` (post `.hq`, `.garrison(buildingId:)`, `.hold(at:)`, `.knockedOut(ticksLeft:)`); the Barracks queue is `loop.state.base.training`. Training only progresses while the Barracks is staffed, so the panel should say so.
- **Goal:** the player chooses how many survivors work each building, and the Barracks trains defenders who garrison towers or hold a spot.
- **Needs:** 1B only, because builders and workers share the same idle survivors.
- **Scope (Core only):**
  - **Jobs:** `Command.setWorkers(id, n)`. This replaces auto-staffing from D-011 (add a DECISIONS entry). New buildings still auto-fill from idle survivors, so it keeps "just working". Survivors split into working, building, away and idle.
  - **Defenders:** Barracks training uses `units.json training` (cost, `trainSeconds` × `trainTimeMultiplier`), `trainingQueueLength` and `maxDefenders`, and each defender uses up one survivor. **Garrison:** `garrison.allowedIn`, counts as the tower's worker, damage × `towerDamageMultiplier`. **Hold a spot:** shoots zombies in `range` with its own `damage`/`fireRate`. At 0 HP a defender is knocked out for `knockedOutSeconds`, then reappears at the HQ; it never dies.
  - Save migration.
- **Do NOT build:** permanent death (open balance question), App UI.
- **Exit check:** `swift test` passes, with tests for: worker limits, survivors never double-booked, staffing scaling production, training queue/cost/time, garrison counting as a worker with the boost, hold-spot combat, knock-out and return, and migration.
- **Start prompt:** "Implement chunk 2B: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/economy.md and combat.md, and the 2B section of docs/BUILD-QUEUE.md only."

### 2C — Core: scavenging runs + research stub [Done 2026-11-01]
- **Result:** `Command.startRun`, `.collectRun`, `.startResearch` (`Systems/Scavenging/`, `Systems/Research/`, notes `docs/features/scavenging-research.md`, D-035). Runs: `loop.state.base.runs` (timer + survivors), reward waits in `Building.heldReward`; research: `loop.state.base.research`, results in `loop.state.group.knowledge`. Effects live: metal wall unlock, tower range +1 (`loop.towerRange(id:)` is the number the range ring should draw), farms × 1.25 (also in the HUD rates). `runProblem(buildingId:runId:)`, `researchProblem(_:)` give the reason a button is greyed. Save v5. **Note for 4B:** training, runs and research all tick inside `GameLoop.step`, so catch-up by stepping advances them with no extra code.
- **Goal:** send survivors on timed runs for loot, and research the 3 stub items at the Workshop.
- **Needs:** 1B only, because both use idle survivors and the same save. It can run in parallel with 2B.
- **Scope (Core only):**
  - **Runs:** one active run per post (`scavenger.runs.types`, `runsUnlocked` per level). Survivors are away (not working, not at risk) for `durationSeconds`. Rewards wait at the post and are multiplied by `runRewardMultiplier`; collecting clamps to caps and the remainder stays at the post.
  - **Research:** `research.json` items. Needs a finished, staffed Workshop; one at a time; `researchSeconds` ÷ `researchSpeedMultiplier`. Results go in `Group.knowledge` (they carry to future bases). Effects: unlock `wall_metal` (placement already checks for it), tower range +1, farm production × 1.25 (the Agriculture multiplier left out in milestone 1A).
  - Save migration.
- **Do NOT build:** risk of losses on runs (not in Phase 1), more research items.
- **Exit check:** `swift test` passes, with tests for: run timer/absence/reward/clamped collect, levels unlocking runs, research gate/time/effects, and Knowledge surviving a save round-trip.
- **Start prompt:** "Implement chunk 2C: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/economy.md, and the 2C section of docs/BUILD-QUEUE.md only."

### 3B — App: 1C panels + 1C exit check [Done 2026-11-01]
- **Playtest result (agent-played at 2x, fresh town, ~38 game-min):** HQ L2 reached (~game-min 28), hordes 1–4 all held (day 3–4 hordes are configured with a guaranteed brute), 1 wall lost, Scavenger run + Collect, Barracks train + garrison + hold-spot, Workshop research start/progress, Storage (cap 1000→1500) all worked on screen. HQ L3 not reached (needs 1200 scrap; see balance notes). Findings and knobs: `docs/features/balance.md` → "Playtest 3B".
- **Result so far:** everything in Scope below is on screen and was driven in the iPhone 18 Pro simulator: selecting a building shows a panel with the level badge (tinted), Upgrade (cost; cream when Core says no and tapping shows the reason, progress bar while upgrading, Cancel job in the bar), Workers −/+, build-queue strip under the HUD, Barracks (Train, queue with cancel, defender cards with a Post… menu: wait at HQ / hold a spot by tapping the map / man a tower), tower panel (assign or release a defender), Scavenger Post (runs, Send, timer, Collect) and Workshop (research list). Defenders are drawn as labeled boxes (not directional until 3M). Range ring includes Marksmanship. Not done: the 30-minute playthrough that reaches HQ 2–3 and faces brutes, plus its balance notes for 6B; Workshop research and Collect were only verified in Core tests (the simulator town had no staffed Workshop). Notes: `docs/features/hud-ui.md`.
- **Goal:** everything from 1B/2B/2C can be used on screen, and a 30-minute session feels like progress.
- **Needs:** 1B, 2B, 2C (not the A art track). All three are done; the Core calls to use are listed in the Results of 1B, 2B and 2C above and in `docs/features/core-api.md`. `PlacementMessages` already has text for every new Core error.
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
- **Scope (App only):** `SettingsView` (Time factor, Horde Alerts); `WelcomeBackView` (when away ≥ `welcomeBackMinAwaySeconds`); `NotificationScheduler` (one alert in the random window, honoring `quietHours` and `minAwayMinutes`, and asking notification permission only when the toggle is first turned on); `AppLifecycle` (saves the wall-clock time, runs catch-up on launch, checks whether the alert fired); an Engage button while a bonus horde waits; a DEBUG "pretend I was away N hours" option.
- **Exit check (milestone 1D):** queue work, close the app for 4 hours (or use the debug option), reopen. The summary feels good, and ignoring the alert costs nothing.
- **Start prompt:** "Implement chunk 5B: read AGENTS.md, docs/STATUS.md, docs/MAP.md, the 1D App section of docs/PHASE1-TASKS.md, and the 5B section of docs/BUILD-QUEUE.md only."

### 6B — Art swap, balance, TestFlight (owner-led)
- **Goal:** Phase 1 is done: a 30-minute playtest leaves you wanting more, and coming back after 4 hours feels rewarding.
- **Needs:** 5B (A art track optional).
- **Scope:** final art import and anchor fixes in `presentation.json`; a balance pass with the `docs/features/balance.md` knobs; answering the STATUS balance questions and tuning `docs/GAME-RULES.md` (food upkeep is decided: yes, built in 1W). Also: sound hooks, an app icon check, the two art-import questions in STATUS, and TestFlight (the owner signs in Xcode; the agent prepares the archive command and checklist).
- **Exit check:** the Phase 1 "done when" line in `PHASE1-PLAN.md`.
- **Start prompt:** "Start chunk 6B: read AGENTS.md, docs/STATUS.md, docs/features/balance.md, and the 6B section of docs/BUILD-QUEUE.md; walk me through the balance questions first."


### 1W — Core: food & water survival basics [Specced 2026-11-01]
- **Goal:** survivors eat and drink, a new town starts with a little to live on, and the player grows food and water. Running short hurts but never wipes the town. Rules and proposed numbers: `docs/GAME-RULES.md` §4 (owner design, D-042).
- **Needs:** 3B (done). Can run beside 4B or 1L; coordinate the save version (see "Save versions").
- **Scope (Core only):**
  - **Water** resource (starting 60, cap like food). Turn on `foodUpkeepPerSurvivorPerMin` (0.5) and add `survival.waterUpkeepPerSurvivorPerMin` (0.5); remove the loader's "must be 0" check. Fractions carry like production.
  - **Shortages:** Hungry / Thirsty output multipliers, no arrivals, leaving after `leaveAfterSeconds` (idle first, defenders last, never below `minSurvivors`, paused during hordes). Seeded order only. Owner confirmed: they leave, nobody dies.
  - **Town appeal:** arrival interval = `intervalSeconds ÷ appeal`; appeal from food/water going up and the held-horde streak, capped, halved after an HQ fall; 1–2 bonus newcomers after a held horde (seeded). Appeal goes in the HUD snapshot with its reasons. Save the streak.
  - **New buildings in `buildings.json`:** Garden (1 worker, food), Well (1 worker, water), Rain Catcher (0 workers, fills only during seeded rain showers from `survival.rain`, small tank). `waterUsePerMin` on Garden/Farm.
  - **Starting layout:** a working Well and a broken Garden (starts as rubble, fixed with the rubble rules), plus one broken Well on the map. Needs a map position for each (`Content/maps/phase1_exit.json`); add `startsBroken`.
  - Agriculture research also boosts gardens. HUD snapshot gets water and net food/water per minute.
  - Save: bump the version; old saves get starting water and no new buildings (no free well).
  - If 4B is done: catch-up runs upkeep (stops at 0, nobody leaves while away) and the summary reports "ran out". If not, 4B does it.
- **Do NOT build:** canned goods, Cannery, hunting, foraging, coop (2W); spotters (1L); any App UI (3W); weather visuals (rain is a seeded number only); permanent death.
- **Exit check:** `swift test` passes with tests for: upkeep math over 10 min, Hungry/Thirsty multipliers, leaving order and the minimum, no leaving during a horde, rain catcher only filling in showers (seeded, same result twice), appeal math and its cap, faster arrivals with appeal 2.0, streak reset on HQ fall, bonus newcomers after a held horde (only with free housing), fixing the broken garden, save migration from v5 (or the current version), and `ContentFilesTests`.
- **Start prompt:** "Implement chunk 1W: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/GAME-RULES.md §4, docs/features/economy.md, and the 1W section of docs/BUILD-QUEUE.md only."

### 2W — Core: more food (canning, hunting, foraging) [Specced 2026-11-01]
- **Goal:** more ways to feed the town, and a reason to can food. Rules: `docs/GAME-RULES.md` §4.
- **Needs:** 1W.
- **Scope (Core only):** **Canned goods** resource with its own pantry cap (Cannery `storageAdded`), eaten after fresh food, not lost when the HQ falls (`economy.json hqFall.affects` stays food+scrap); starting food becomes 50 fresh + 100 canned. **Cannery** (workers convert food → canned per min). **Foraging** run at the HQ (reuse the scavenging-run system, available from day 1). **Hunting Lodge** with Short/Long Hunt runs (same system; long hunts cost canned rations). **Chicken Coop** (steady food, uses water). **Water Filtration** research (+50% wells). `survival.freshSpoilPctPerHour` knob, default 0. Save bump.
- **Do NOT build:** run risk/losses (IDEAS §2), fishing (Phase 2), App UI.
- **Exit check:** `swift test` passes with tests for canning conversion and pantry cap, eat order, HQ fall sparing canned goods, foraging/hunt rewards through the run system, coop water use, spoilage at a non-zero test value, migration.
- **Start prompt:** "Implement chunk 2W: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/GAME-RULES.md §4, docs/features/scavenging-research.md, and the 2W section of docs/BUILD-QUEUE.md only."

### 1L — Core: spotters [Specced 2026-11-01]
- **Goal:** survivors posted as spotters call out hordes; higher lookouts and better optics give earlier, richer warnings. Rules and numbers: `docs/GAME-RULES.md` §6 (owner design, D-042).
- **Needs:** 3B (done). Can run beside 1W or 4B; coordinate the save version.
- **Scope (Core only):**
  - **Lookout Post** building (1×1, 1 worker, levels = height: `sightTiles`, `warningSeconds`, `intel`). HQ roof and staffed Watchtowers act as small lookouts.
  - **Watched edges:** an edge is watched if a staffed lookout sees its spawn point. Warning time per spawning edge = best watching lookout, else `spotting.unwatchedWarningSeconds`. This replaces the fixed `schedule.warningSeconds` (keep the horde clock itself unchanged).
  - **Spotted report** in the snapshot: edge, seconds left, and (by level) rough size or zombie types; a "spotted" event for the App's callout. Before spotting, the snapshot only offers a rough minutes-to-horde number.
  - **Research:** Binoculars (+warning), Radio (HQ 3, +warning; scavengers on runs also spot).
  - The bonus horde (4B) always counts as spotted.
  - Save bump if anything new is saved (likely only the new building).
- **Do NOT build:** sound, banner or any UI (3W); spotters getting hurt; per-zombie fog of war.
- **Exit check:** `swift test` passes with tests for: watched vs unwatched warning time, best lookout wins, unstaffed lookout sees nothing, intel by level, research bonuses, rough clock rounding, same seed = same result.
- **Start prompt:** "Implement chunk 1L: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/GAME-RULES.md §6, docs/features/hordes.md, and the 1L section of docs/BUILD-QUEUE.md only."

### 3W — App: survival + spotter screens [Specced 2026-11-01]
- **Goal:** the player can see and use everything from 1W, 2W and 1L.
- **Needs:** 1W, 2W, 1L.
- **Scope (App only):** HUD water and canned goods with net per minute, a red Hungry/Thirsty banner, and town appeal with its reasons; build-menu cards for the new buildings (labeled boxes until models exist); Cannery, Hunting Lodge and HQ Foraging panels (reuse the scavenging panel); Lookout panel (sight, warning, upgrade); a sight ring when a lookout is selected and a marker on watched edges; the "Horde spotted — east off-ramp, 75 s · about 15 · 2 brutes" banner with a siren sound hook; the rough "next horde in ~6 min" clock until spotted. Ask whether to add new art ids to `docs/graphics-spec-phase1.md` for a later model chunk.
- **Do NOT build:** new 3D models (separate art chunk), weather visuals, town-life walking (3M-3).
- **Exit check:** in the simulator, a fresh town: fix the garden, watch water and food tick, let water run out and see the banner and output drop, build a lookout by the east road and get an early callout for an east horde but a late one for an unwatched edge.
- **Start prompt:** "Implement chunk 3W: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/GAME-RULES.md §4 and §6, docs/features/hud-ui.md, and the 3W section of docs/BUILD-QUEUE.md only."

## Chunk 1D — Realistic static walker [Done]
- **Goal:** demonstrate one realistic zombie end to end in the current game.
- **Needs:** none; owner-authorized art pilot, independent of milestone 1C.
- **Scope:** front/back transparent cutouts, base fallback, existing mirrored directions, matching canvas, importer, app build and simulator review. Sources deleted with the 2D cleanup (git history).
- **What NOT to build:** limb animation, extra zombie types, top-down replacement, new gameplay or 3D rig.
- **Exit check:** build succeeds; all four directions render with clean transparency in the real app. Passed; `in-game-four-facings.png` uses a paused review fixture. Pre-test save restored byte-for-byte.
- **Start prompt (review only):** “Review chunk 1D realistic walker: open its README, preview and simulator capture; do not regenerate art.”

## Chunk 2A — Realistic walker limb animation [Retired — D-030]
- **Retired 2026-11-01:** the game no longer draws 2D sprites, so 2D walker frames aren't needed. The Mixamo walker's next life is the animated 3D zombie in chunk 3M. Text below kept for history.
- **Goal:** the walker visibly steps and swings its arms while moving; owner approved a Mixamo stock replacement in D-026.
- **Needs:** chunk 1A static walker only (also recorded as 1D by the static-art chat); no gameplay chunk dependency.
- **Scope:** six poses in each of two source facings, mirrored west, stable canvas/feet, distance-driven cached textures, static fallback, presentation JSON and simulator checks. First prototype is implemented; see `docs/features/zombie-walk-animation.md`.
- **What NOT to build:** runner/brute art, attack swings, top-down replacement, gameplay or save changes.
- **Exit check:** smooth alternating steps without scale/anchor jitter, clean four-facing movement, pause/attack stop, missing-frame fallback, build and Core tests pass; day-40 performance matches baseline. Initial build/tests and day-7 horde passed; full visual exit check remains.
- **Current route / dependency:** ZWALK-1M steps 0–3 implemented (Yaku J Ignite / Zombie Walk); fixture-based checks and builds pass. Prototype `c12e557`. Normal-horde hands-on gait/foot-sliding acceptance remains; native simulator clicks failed. See `docs/features/zombie-walk-mixamo.md`.
- **Start prompt:** “Continue ZWALK-1M / chunk 2A: read docs/features/zombie-walk-mixamo.md. Implementation is in and D-026 approved. Review walker-mixamo/README.md and preview.gif, then check a normal horde in the simulator for smoothness, all four directions, foot sliding and the Horde now menu path. Close 2A only when those pass. Walker only; do not regenerate or start runner/brute.”

## Chunk 1R — 3D go/no-go spike [Done — GO, D-028]
- **Goal:** see our own models in real 3D on an iPhone, with numbers, before committing to the 3D switch.
- **Needs:** nothing (owner approved starting it outside Phase 1, D-027).
- **Scope:** a DEBUG-only RealityKit screen, not wired to the game: ground plane, HQ + ~5 Blender study models exported by hand to USDZ, a low sun with shadows, orbit camera (pan, pinch, twist, limited tilt), then 35 and 100 Mixamo walkers walking in circles. Measure fps (simulator, and a real phone if one is available). Confirm: iOS 17 vs 18 (`RealityView` virtual camera), frame-rate capping, particles/billboards availability.
- **Do NOT build:** game hookup, `GameStore` changes, the export script, other models, any Core change, raising the deployment target (that's an owner decision after 1R).
- **Exit check:** screenshots/video beside the current 2D view, an fps table, a one-page "gaps found" note in `docs/plans/3d-spike-1R-results.md`; app still builds and 2D game is unchanged; owner decides go/no-go.
- **Start prompt:** "Implement chunk 1R: read AGENTS.md, docs/STATUS.md, the 1R section of docs/BUILD-QUEUE.md and docs/plans/3d-rendering-plan.md only. Build the DEBUG RealityKit spike and report fps and screenshots."
- **Result (2026-11-01):** `docs/plans/3d-spike-1R-results.md` + screenshots in `docs/plans/spike-1R/`. Spike in `App/Spike3D/` (Debug menu → "3D spike (1R)"); one-off export `tools/blender/spike_export_usdz.py`. Simulator: 60 fps with 100 walkers + shadows on both RealityView (iOS 18) and ARView non-AR (iOS 17). RealityView, particles, billboards, opacity fades are iOS 18+; no public frame-rate cap. Real iPhone 18 Pro: 60 fps at 0/35/100 walkers, shadows on or off, both routes. Recommendation: GO with minimum iOS 18. **Owner: GO, minimum iOS 18 (D-028).** An older-phone check and a heat check stay with 5R.

## Chunk 2R — Game in 3D [Done 2026-11-01]
- **Goal:** the real game playable in 3D with labeled boxes.
- **Result:** RealityView world (virtual camera): one merged ground mesh, labeled placeholder boxes, buildings/zombies synced to Core, dusk sun with shadows. `ModelRegistry` loads `<artId>.usdz` in the background, so the 1R spike's six models already show. Shared `GameTicker` (display link) runs the clock, which pauses behind the DEBUG spike. Snapped 4-angle camera (one 90° step per two-finger twist, eased), pan, pinch toward the fingers, tilt, minimum camera height, zoom-out clamped to the map; numbers in `presentation.json reality3d`. Core: tested `WorldMapping3D` and `OrbitCamera3D`. 129 Core tests; simulator build clean; checked on the simulator with the owner's save (horde ran, zombies walked to the breach). The 2D/3D switch was built and checked, then removed when the owner retired 2D (6R, D-030). Notes: `docs/features/rendering-art.md`, D-031.

## Chunk 3R — Placement, selection and walls in 3D [Done 2026-11-01, D-032]
- **Goal:** building feels as good as the D-022 isometric placement did, now in 3D. Until this lands the player can't build (2D is gone, D-030).
- **Needs:** 2R (done). Independent of 2M/3M: works with boxes or models.
- **Scope:** switch the Build button back on (`GameRootView.canBuildIn3D`); taps turn into a ray from the finger: ground tile via `OrbitCamera3D.groundPoint`, buildings via collision boxes (tall roofs win, like the old iso rule); select a building (outline + range ring on the ground for towers/HQ, the existing selection bar); placement ghost = see-through model or box, tile grid around it, green/red footprint, reason in the existing bar; a drag that starts on the ghost moves it (lifted above the finger), any other one-finger drag pans; Move/Cancel/Confirm through the existing `PlacementController`; wall tool: one finger drags a line (count + cost, skipped tiles red), two fingers pan; buildings between the camera and the ghost fade (`OpacityComponent`), from any of the 4 angles. Tunables (grid radius, lift, fade) as named look constants or JSON if they're tuning.
- **Do NOT build:** effects, health/progress bars, turret aiming (4R), real models (2M), animated zombies (3M), new placement rules (Core is unchanged).
- **Exit check:** repeat the D-022 simulator checks in 3D at two camera angles: place a 1×1 (wall line at the map edge), a 2×2 inside the walls, move the HQ then Cancel (no change), invalid spots blocked with reasons, tap a roof to select, demolish with refund; `cd Core && swift test` and the simulator build pass.
- **Start prompt:** "Implement chunk 3R: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/input.md, docs/features/rendering-art.md and the 3R section of docs/BUILD-QUEUE.md only."
- **Result:** exit check passed in the iPhone 18 Pro simulator at two camera angles: HQ roof tap selects (outline + range ring), Move HQ + drag onto the highway (red, reason, Confirm off) + Cancel = unchanged, farm (2×2) blocked on a wall then placed inside the walls (−50 scrap; HQ and watchtower faded in front of the ghost), demolish refunded 25 scrap; second angle: two-finger pan in the wall tool, 9 wood walls along the map edge (−90 scrap), a line across the farm showed red skipped tiles and the wall limit, watchtower roof tap selects with its ring. 134 Core tests pass; build has no warnings. Simulator save restored byte-for-byte.

## Chunk 3M — Animated zombies (+ survivors/defenders) in 3D [Done 2026-11-01, D-038]
- **Goal:** zombies (and survivors/defenders) are real animated 3D characters instead of green boxes: they walk without foot sliding, turn smoothly and attack.
- **Needs:** 2R and 2M (both done).
- **Scope:** export the Mixamo walker (`HighwayHoldout_3D_Sources/mixamo-walker/`, D-026; the 1R spike already exports it with `tools/blender/spike_export_usdz.py`) as `zmb_walker.usdz` with walk + attack (+ idle if available) at the game scale (0.41 tiles per metre, like D-037); `ZombieLayer3D` plays walk at a speed matched to movement (stride 0.6149 tiles, as measured), turns smoothly, holds attack while bashing; runner and brute: a Mixamo variant or the walker re-tinted/re-scaled at first; survivors/defenders: one simple Mixamo character if quick, else keep boxes; decide how the Mixamo-derived USDZ is kept (today it is git-ignored, D-026 terms) and record it in DECISIONS.
- **Do NOT build:** effects, health bars, turret aiming (4R); new zombie types or gameplay; building models (2M, done).
- **Exit check:** a normal horde in the simulator: no visible foot sliding from all 4 camera angles, turning looks smooth, attack plays while bashing a wall; removing a character USDZ shows the labeled box; a day-40 horde stays smooth (fps readout); `cd Core && swift test` and the simulator build pass.
- **Start prompt:** "Implement chunk 3M: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/zombie-walk-mixamo.md, docs/features/rendering-art.md, docs/features/models-3d.md and the 3M section of docs/BUILD-QUEUE.md only."
- **Progress (2026-11-01):** built: `tools/blender/export_characters.py` (walker → `App/Models/zmb_walker.usdz` + `.anim.json`, stride 0.6095 tiles, 2.4 MB), `CharacterMotion3D` in Core (glide between ticks, capped turning, walk rate = speed ÷ stride; 6 tests, 204 Core tests pass), `CharacterAnimator3D`, runner/brute = walker scaled/tinted (`presentation.json reality3d.characters`), defenders play idle once a model exists. Checked in the iPhone 18 Pro simulator: zombies are animated models facing their way of travel; removing the USDZ shows labeled boxes; build clean; save restored byte-for-byte. Mixamo files git-ignored (public repo, D-038).
- **Result (2026-11-01):** owner signed in to Mixamo; downloaded Zombie Attack + Zombie Idle for Yaku J Ignite (FBX Binary, With Skin, 30 fps) into `HighwayHoldout_3D_Sources/mixamo-walker/`; exporter now writes walk (0–4.0 s), attack (4.03–8.63 s), idle (8.67–14.73 s), 3.0 MB. In the simulator a temporary log confirmed walkers, runners and brutes switch to attack while bashing and idle when standing (probe removed). 204 Core tests pass; build clean; save restored byte-for-byte.
- **Not checked / left:** close visual foot-sliding check from all 4 camera angles (stills + maths only); day-40 fps (no in-game readout until 5R); defenders stay boxes (no defender model downloaded; drop `mixamo-defender/defender_idle.fbx` in and rerun the exporter).

## Chunk 4R — Effects, overlays and health bars in 3D [Done 2026-11-01, D-039]
- **Goal:** watching a horde reads as well as it did in 2D: you can see who shoots whom, what is hurt, what broke, and where the next horde comes from.
- **Needs:** 3R (done) and 3M (animated zombies; 3M needs 2M). Effects can be prototyped on boxes, but the exit check needs 3M's zombies.
- **Scope:** draw Core's `SimEvent`s (today `World3D.update` drains and drops them): tracers and muzzle flash from towers, hit/goo decals on the ground, dust when a wall breaks, short building shake on damage, trap flash; floating health bars over damaged buildings/walls and progress bars over buildings under construction (billboards); turret tops that turn toward their target (2M did not split them: add a separate turret model for the watchtower and MG nest here); horde warning arrows at the map edges during the warning time. Same caps as the old 2D `EventPlayer` (git history before c7a8e9c) so a day-40 horde can't flood the scene; any new caps or timings are look constants, or JSON if they're tuning.
- **Do NOT build:** new kinds of effects beyond the 2D set, sound, particles that need iOS 26, the performance pass and fps readout (5R), new gameplay or Core rules.
- **Exit check:** the 1B on-screen defense check in 3D: horde from the debug menu walks to a weakened wall, breaks through (dust + rubble), pours in, towers aim and fire with visible tracers, damaged walls show health bars, "Held!" banner; a day-40 horde (debug) stays smooth in the simulator; `cd Core && swift test` and the simulator build pass.
- **Start prompt:** "Implement chunk 4R: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md, docs/features/hordes.md and the 4R section of docs/BUILD-QUEUE.md only."
- **Result (2026-11-01):** new App layers `EffectsLayer3D` (+ `EffectMeshes3D`), `TurretLayer3D`, `BarsLayer3D`, `HordeWarning3D`; new turret models `def_watchtower_gunner`, `def_mg_nest_gun` (with `muzzle` empties); the watchtower is now an open platform so its gun shows; `check_models.py` counts turrets (21/21). No Core change (204 Core tests pass); build has no warnings. Exit check in the iPhone 18 Pro simulator with test saves: warning arrows + red edge tiles at the warned edges; horde walked to weakened walls (red health bars), broke through (dust cloud caught in a frame, rubble), poured in, the watchtower gun turned and fired yellow tracers, goo where zombies died; with a full-health HQ the horde ended with "Held! +49 scrap · +45 food" (HQ bar back to green); earlier runs with a near-dead HQ ended "HQ fell". Day-40 horde (up to 47 zombies): 58.6–59.6 fps from a temporary display-link probe (removed). Simulator save restored byte-for-byte.
- **Not checked:** the MG nest gun in the game (the test town has none; model exported and reviewed only); defender tracers (no defender holding a spot in the test town); trap flash (no spikes in the test town); real-phone fps (5R).

## Chunk 5R — Performance pass, fps readout, Battery saver [Ready]
- **Goal:** the 3D game stays smooth and cool on real phones, and the player can see/limit it.
- **Needs:** 4R (done).
- **Scope:** a DEBUG fps + entity-count readout in the game (like the old 2D one; 4R used a temporary display-link probe); stress tests: day-40 horde and ~100 zombies (debug), on the simulator and on the oldest supported real iPhone available; tune what costs most (shadow distance, zombie model detail, effect caps) with numbers in `presentation.json` where they are tuning; a **Battery saver** setting (e.g. 30 fps cap via the display link, shadows off) saved with the player's settings; an app-size report (`App/Models` is ~20 MB + characters); a 30-minute play session heat check on a real phone.
- **Do NOT build:** new effects or models, gameplay changes, the 1D settings screen beyond the one Battery saver switch (5B owns the settings screen; put the switch where 5B can move it).
- **Exit check:** 60 fps at day 40 and ≥45 fps at 100 zombies on the oldest phone tried (table in `docs/plans/`), Battery saver visibly lowers fps/shadows and survives a relaunch, a 30-minute session without the phone getting hot, size report; `cd Core && swift test` and the simulator build pass.
- **Start prompt:** "Implement chunk 5R: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md and the 5R section of docs/BUILD-QUEUE.md only. Start with the fps readout and a stress test."

## Chunk 6R — Retire 2D [Done 2026-11-01, D-030]
- Owner asked to move to full 3D right after 2R. Removed the SpriteKit renderer, iso/top-down sprites and Core 2D projection math; kept menus, `PlacementController` logic, the DEBUG spike, tools and source art folders. Building stays off until 3R.

## Chunk 2M — 3D models for buildings, defenses and decorations [Done 2026-11-01, D-036, D-037]
- **Goal:** every building, defense, construction/rubble state and decoration has a 3D model the game loads.
- **Scope (as rewritten after D-036):** realistic CC0 models: buildings assembled from Quaternius Downtown City MegaKit modular pieces, props from Poly Haven, simple barricades/stakes/wire modelled with Poly Haven textures; pipeline `tools/blender/export_usdz.py` + `model_kit.py` + `recipes_{buildings,defenses}.py` → `App/Models/<artId>.usdz`; missing-model checker `tools/check_models.py`; 4-angle review sheets.
- **Result:** 19 models (7 buildings, 6 defenses, 2 construction sites, 2 rubble, car wreck, dead tree), ~20 MB in all (512 px textures, no normal maps, props ≤ ~1,500 triangles). `check_models.py`: 19/19. Review sheets `docs/plans/models-2m/`; in the game on the iPhone 18 Pro simulator they replace the boxes (`docs/plans/models-2m/in-game.jpg`); the 1R spike's study scene loads them too (old study USDZ removed). 198 Core tests pass; build clean; simulator save restored byte-for-byte. Notes: `docs/features/models-3d.md`.
- **Not done (moved on):** separate turret tops that can aim (now in 4R); a different look per building level (L2/L3); measuring on a real phone (5R).

## Chunk 3M-2MH — MakeHuman script + blacksmith profile [Done 2026-11-01]
- **Goal:** give the owner a reproducible body/FBX script and a precise age-45 medieval blacksmith brief.
- **Needs:** owner request only; no wave dependency. Running it needs MakeHuman with scripting/FBX plugins enabled.
- **Scope:** `tools/makehuman/` script and instructions, measured-height report, `docs/plans/blacksmith-profile.md` with face/build/posture/costume targets. D-041.
- **Do NOT build:** full cast, custom garment assets, rigging/animation, game hookup, new gameplay or a medieval game setting.
- **Exit check:** script syntax and mocked plugin-style execution pass (exact values, output isolation, safeguards, invalid-FBX rejection); profile and instructions delivered. Live generation and Blender import are explicitly pending, outside this preparation chunk.
- **Start prompt / next:** "Continue the MakeHuman trial for chunk 3M-2; follow tools/makehuman/README.md and verify one real FBX in Blender."

## Chunk 3M-2MH-I — Install MakeHuman [Done 2026-11-01]
- **Goal:** owner can open MakeHuman on this Apple Silicon Mac without setup work.
- **Needs:** owner installation request; no wave dependency.
- **Scope:** official pinned source, official CC0 asset pack, private Python environment, user Mac launcher, enabled scripting/FBX, link to existing script.
- **Do NOT build:** game changes, sculpted character, rigging or animation.
- **Exit check:** modeling window observed; logs confirm both plugins and startup complete; `pip check` passes. Source reports 1.3.0 alpha. Install details in `tools/makehuman/README.md`.
- **Start prompt / next:** "Continue the MakeHuman trial for chunk 3M-2: open the installed app and verify one real FBX using tools/makehuman/README.md."

## Chunk 3M-2MH-V — Live MakeHuman export and Blender check [Done 2026-11-01]
- **Goal:** produce a real source body and prove the generated FBX imports correctly.
- **Needs:** 3M-2MH + 3M-2MH-I only, not wave dependencies.
- **Scope:** run existing script in MakeHuman, verify FBX height/finite geometry/image paths in Blender, save imported source and preview. Checker `tools/blender/check_makehuman_fbx.py`; exact output folder in `tools/makehuman/README.md`.
- **Do NOT build:** finished blacksmith sculpt/garments, mobile optimization, rig/animation or game integration.
- **Exit check:** passed real export/import; exact sliders, height agrees within <0.001 mm, two finite meshes, no missing image paths, reviewed clean preview with imported custom normals disabled. FBX 831,468 bytes; 28,796 triangles exceeds mobile target; requested maximum height = 2.44386 m. No source body rescale.
- **Next / start prompt:** "Continue chunk 3M-2 from the verified MakeHuman base: read tools/makehuman/README.md and blacksmith-profile.md, apply the intended look and optimize the body/garments to the phone budget before rigging. Keep the original source and its exact slider values."

## Chunk 3M-2MH-L — Clothed blacksmith review model [Done 2026-11-01]
- **Goal:** move beyond the bare source to a clothed, portable draft under the mesh budget.
- **Needs:** 3M-2MH-V only; no wave dependency.
- **Scope:** fitted CC0 source clothes/hair/skin and head modifiers, apron/beard, one atlas, ≤10k triangles, saved blend/FBX/GLB, four-angle review and clean FBX reimport. Bundle/results in `tools/makehuman/README.md`.
- **Do NOT build:** full cast/game hookup, new gameplay, final historical likeness or custom animation systems.
- **Exit check:** 9,209 finite triangles; one material/atlas; ~1.22 MB static FBX/GLB; actual FBX reimport preserves count/height/images; four final views reviewed. Fine skin/scar/period-clothes details and deformation/rig/animation explicitly remain.
- **Next / start prompt:** use the updated 3M-2 continuation below for the rig/motion trial before extending the cast.

## Chunk 3M-2MH-F — Farmer and portable review assets [Done 2026-11-01]
- **Goal:** one additional model type from the town-life spec, finished through exported/reviewed files and local commit.
- **Needs:** installed MakeHuman pipeline only; independent of the wave rule.
- **Scope:** adult woman farmer (40, faded overalls/grey shirt/boots/short hair), source recipe, ≤10k mesh, single atlas, FBX/GLB/packed blend, four views; include both farmer and blacksmith portable CC0 model packages in repo.
- **Do NOT build:** remaining cast, Core/gameplay changes, task animations or full 3M-2 integration.
- **Exit check:** actual MakeHuman source generation; farmer 9,196 triangles, one atlas/material, ~1.41 MB FBX; four angles reviewed. Both models pass standalone blend / isolated FBX / GLB counts/height/texture checks; syntax + whitespace pass. Owner-requested commit on `chunk-3m-2-humans`, no merge/push.
- **Next / start prompt:** "Continue chunk 3M-2 from the committed farmer: read the asset README and reports, test rig/deformation and walk/carry/dig clips on this normal-height character before expanding the cast."

## Chunk 3M-2 — Human characters: defender + survivor looks [Specced 2026-11-01, draft]
**First look in game (2026-11-01):** the owner's MakeHuman farmer, rigged/animated in Mixamo (walk, run, shooting rifle), is exported as `sv_farmer` and used for **every** human for now: defenders (rifle clip during hordes) and up to 40 survivors strolling at random around the HQ (`SurvivorLayer3D`, hidden during hordes). Still to do in 3M-2: an idle clip (humans stand frozen in a walk pose), a rifle prop, more looks (blacksmith + others) and task clips (carry, hammer, dig, talk); 3M-3 then gives them real jobs. Notes: `docs/features/characters-3d.md`.

**Farmer model now ready as the next rig trial source (3M-2MH-F).** Use the committed
`HighwayHoldout_3D_Sources/makehuman/farmer/` package; normal height, no apron, 9,196 triangles.
First verify rig/deformation, then idle/walk/run/carry/dig/pick-up/talk clips, 512 px atlas and
full ≤3 MB animated size. Owner handles Mixamo uploads/downloads per 1X; integration stays on
the human branch and merges only with owner approval. This task does not remove 3M-3's dependency.
Local `makehuman/sv-farmer_{walking,running,rifle}.fbx` downloads appeared during staging;
Mixamo metadata confirmed in walking file, all preserved/ignored under D-038. Inspect their
character/rig compatibility first; not used or validated in this static model delivery.

**Clothed review model delivered (3M-2MH-L):** portable `blacksmith_review_bundle.zip` in the
folder documented by `tools/makehuman/README.md`; 9,209 triangles, one atlas/material, ~1.22 MB
static FBX/GLB, four reviewed views, clean FBX reimport. Next big step in this chunk is a
rig/deformation + motion trial on this model (owner Mixamo actions/downloads under 1X), with
apron clearance, hand/joint preservation and full ≤3 MB animated budget checked before duplicating the cast.
Art refinement must address the README's explicit costume/face-detail deviations; no game hookup yet.
Start prompt: "Continue chunk 3M-2 from the clothed blacksmith draft: read the MakeHuman README
and reports, test rigging/deformation and task motions on this one character before expanding the cast."

**Real base now exists (3M-2MH-V, 2026-11-01):** live export and Blender import passed. Output
folder and reports in `tools/makehuman/README.md`; clean clay preview reviewed. Next: chosen
face/weathering/hair/clothes, reduce the 28,796-triangle base plus garments to ≤ ~10,000, atlas,
rig/clips, then the full integration below. Preserve original body and exact requested sliders.
Import this FBX with `use_custom_normals=False`; default imported normals render badly.
Earlier preparation/installation notes below describe the state before this successful test.

**Installation ready (3M-2MH-I, 2026-11-01):** open `/Users/rick/Applications/MakeHuman.app`.
Official source + CC0 system assets installed; private Python environment; scripting/FBX enabled and
startup verified. Reports 1.3.0 alpha. Follow `tools/makehuman/README.md` for the real export check;
no blacksmith FBX was generated during installation. No change to the full chunk's remaining scope.

**MakeHuman continuation (2026-11-01, D-041):** 3M-2MH preparation is done. Next, run
`tools/makehuman/generate_blacksmith.py` in MakeHuman (instructions beside it), compare the FBX
height/textures in Blender with its report, and apply the chosen survivor look. Rig in Mixamo and
download the clips before the game integration below. Script syntax/mocked checks passed; no real
FBX was generated this session. Start prompt: "Continue the MakeHuman trial for chunk 3M-2:
read tools/makehuman/README.md and docs/plans/blacksmith-profile.md; verify one real FBX in
Blender before expanding to the full cast."

_The humans are split in two so each fits a fresh chat: **3M-2** makes the people (models + animations), **3M-3** makes them live in the town. Full design for both: `docs/plans/town-life-plan.md`._
- **Why:** 3M shipped only the zombie. Defenders are still labeled boxes and survivors are not drawn at all.
- **Work on its own git branch** (`chunk-3m-2-humans`), merged only when the owner approves.
- **Goal:** a defender and a varied cast of survivors exist as animated 3D humans the game can load, and defenders use theirs in play.
- **Needs:** 3M (done). Owner downloads from Mixamo (FBX Binary, With Skin, 30 fps, In Place where offered) into `HighwayHoldout_3D_Sources/mixamo-humans/<artId>/` — exact list in the plan doc §3: 1 defender (rifle idle, rifle walk, rifle run, aim/fire, hit) and 4 survivor characters (each: idle, walk, run/panic, carry-walk, plus task clips hammer, dig/plant, pick up, talk). Files stay git-ignored (D-038).
- **Scope:** generalize `tools/blender/export_characters.py` to a character list (one config file in `tools/blender/`, not hard-coded per character) → `App/Models/unit_defender.usdz` and `civ_a…civ_d.usdz` + `.anim.json`; same scale/feet/front rules as the walker; survivor look variety = 4 models × tints in `presentation.json reality3d.characters.variants` (~8–12 looks); `DefenderLayer3D` plays walk when moving to a post, aim/fire when its tower/spot fires (4R already draws defender tracers), idle otherwise; garrisoned defenders stand visible on their tower's platform if the 4R tower model has room (else stay hidden as today); file-size report (target ≤ 3 MB per character, 512 px textures).
- **Do NOT build:** walking townspeople / routines (3M-3); names, moods, needs or any new Core state; new gameplay; sounds.
- **Exit check:** in the simulator: defenders are animated humans (walk to a held spot, idle, aim and shoot during a horde), all survivor looks load in the 1R study scene / a DEBUG lineup, removing any human USDZ shows the labeled box; size table in `docs/features/characters-3d.md`; `cd Core && swift test` and the simulator build pass.
- **Start prompt:** "Implement chunk 3M-2: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/characters-3d.md, docs/plans/town-life-plan.md §1–3 and the 3M-2 section of docs/BUILD-QUEUE.md only. Work on branch chunk-3m-2-humans."

## Chunk 3M-3 — Town life: survivors at work (Tropico feel) [Specced 2026-11-01, draft]
- **Goal:** the town feels alive like Tropico: you can see your survivors walk from home to their workplace, do the job (farm, haul scrap, hammer at the Workshop, build), carry goods to storage, chat when idle, leave on scavenging runs, and run for shelter when a horde is coming.
- **Needs:** 3M-2 (the human models). Same branch or a new one (`chunk-3m-3-town-life`), owner approves the merge.
- **Key rule:** **looks only.** Core stays the truth for *how many* people do what (`Roster` / `PopulationSnapshot`, per-building `assignedWorkers`, construction jobs, runs). The walking people are a picture of those numbers and never change game state, saves or results. Their planning (who goes where, which task, paths) is pure, seeded math in `Core/Sources/HoldoutCore/Presentation/` so it is unit-tested, like `CharacterMotion3D` (D-031).
- **Scope:** **first, the crowd budget (plan doc §7b):** a DEBUG crowd stress scene, 15-minute sustained runs on the minimum phone, and a table that sets how many survivors/zombies we can show (`docs/plans/crowd-budget.md`); skip if 5R already did it. Then plan doc §4–7: one visible person per survivor up to a cap; role from the roster; daily loop (home → work → task loop → carry to storage → break → back); per-building task table in JSON; builders walk to construction sites; run teams walk out to the map edge and come back with sacks; horde warning → everyone runs to HQ/Shelters and disappears inside, comes back out after "Held!"; tap a person → small label (role + workplace); performance caps and distance culling; all numbers in `Content/presentation.json → townLife`.
- **Do NOT build:** names/personalities/needs/happiness (Tropico's deeper sim — logged in `docs/IDEAS.md`), survivors being attacked by zombies, any Core rule or save change, new buildings or props beyond a few small task props (crate, sack, hoe) if missing.
- **Exit check:** in the simulator with a mid-game town: counts on screen match the HUD population (working/building/away/idle) within the visible cap; each workplace shows its workers doing that building's task; changing Workers −/+ sends someone walking there/away within a few seconds; a run team visibly leaves and returns; horde warning empties the streets, "Held!" refills them; no one walks through walls or buildings; crowd-budget table exists and the caps come from it; a 15-minute busy-town + horde run on the minimum phone holds 60 fps without passing "fair" heat; `cd Core && swift test` (new `TownLifePlannerTests`) and the simulator build pass.
- **Start prompt:** "Implement chunk 3M-3: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/characters-3d.md, docs/features/jobs-defenders.md, docs/plans/town-life-plan.md and the 3M-3 section of docs/BUILD-QUEUE.md only."

## Chunk 1X — Owner downloads [Ready — you, not an agent]
- **Goal:** all the downloaded art the agents need is in `HighwayHoldout_3D_Sources/`, so no agent spends effort driving a browser.
- **Who:** the owner. No agent opens Chrome for downloads. Details, search terms, formats and folders: `docs/OWNER-DOWNLOADS.md`.
- **Parts:** A terrain textures (for 1T), B foliage/scatter models (for 2T), C Mixamo humans (for 3M-2), D optional task props (for 3M-3). Parts are independent; do A first.
- **Agent's only job:** when told "1X part N done", check the files exist and are the right format, note licences in the folder's `NOTES.txt`, then say which chunk is unblocked.
- **Exit check:** every ticked part has its files in the listed folder; Mixamo and terrain files are git-ignored (`git status` doesn't list them).

## Chunk 1T — Ground textures + map edge [Specced 2026-11-01]
- **Goal:** the ground looks like real grass, dirt, asphalt and concrete instead of flat colors, and the map no longer ends in a hard flat edge.
- **Needs:** 2R (done); 1X part A (texture files).
- **Scope:** import the textures as small tileable 512 px (1024 px only for the main grass) USDZ-friendly images in `App/` (size budget: ≤ 4 MB total, note it); extend `GroundMesh3D` / `ModelRegistry.material` so each tile art id maps to a texture through `presentation.json reality3d` (texture name, tiling scale, tint); UVs from world position so tiles join without seams; soften the checker (D-016 style grid look) and add per-tile variation (seeded, look-only) so a field of grass isn't visibly tiled; blend where two tile types meet if cheap (else a 1-tile dark soft edge); the road gets its centre line from the `tile_asphalt_line` art id; map edge: a dressed border (dirt/grass strip, a few fences/barriers from existing models, fade to the outside colour) instead of a flat cut-off; missing texture falls back to today's flat color (never crash).
- **Do NOT build:** foliage or props (2T), new tile types in Core, map layout changes, terrain height/hills, water.
- **Exit check:** simulator screenshots at two zoom levels and two camera angles beside today's flat ground; texture size table; 60 fps unchanged at a day-40 horde (simulator); removing a texture shows the flat colour; `cd Core && swift test` and the simulator build pass.
- **Model:** Sonnet is fine (material and UV work, JSON-driven), with the edge dressing reviewed by the owner.
- **Start prompt:** "Implement chunk 1T: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md, docs/OWNER-DOWNLOADS.md Part A and the 1T section of docs/BUILD-QUEUE.md only."

## Chunk 2T — Foliage and scatter [Specced 2026-11-01]
- **Goal:** the town sits in a believable overgrown landscape: live and dead trees, bushes, grass tufts, rocks and roadside junk placed around the map, with no gameplay effect.
- **Needs:** 1T; 1X part B (models). Run after 5R's fps readout exists, or add a quick readout first, because scatter is the likeliest thing to cost frame rate.
- **Scope:** extend `tools/blender/export_usdz.py` (recipes) to export the new models as `dec_*` / `fol_*` USDZ at game scale (512 px textures, ≤ ~2,000 triangles each, total new size ≤ 12 MB, record it); a scatter pass in the App (not Core) that places foliage from a seeded random generator and a density mask (none on building footprints, roads or the placement grid area; thicker toward the map edge); drawn as repeated instances of a few models (shared meshes), capped by a count in `presentation.json`; trees may be tall roofs for the placement fade rule (D-032) so they must not hide the ghost (fade or keep clear of the base area); decorations already in the map file (`dec_tree_dead`, car wreck, rubble) stay and are not duplicated; Battery saver (5R) can lower the count (leave a hook).
- **Do NOT build:** swaying/wind animation (later), destructible or harvestable trees, weather, seasons, new Core rules or saves.
- **Exit check:** screenshots at two angles with a mid-game town: foliage visible but never over placement ghosts, selected buildings or the tiles you tap; same layout after relaunch (seeded); fps table before/after (day-40 horde, simulator, plus the minimum phone if available, D-040); `check_models.py` reports all new art ids; `cd Core && swift test` and the simulator build pass.
- **Model:** Sonnet for the export recipes; Opus (or careful review) for the scatter/instancing and the frame-rate budget.
- **Start prompt:** "Implement chunk 2T: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md, docs/features/models-3d.md, docs/OWNER-DOWNLOADS.md Part B and the 2T section of docs/BUILD-QUEUE.md only."

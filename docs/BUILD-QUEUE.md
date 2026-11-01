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
| 2B | Core: jobs (manual workers) + defenders | 1B only | Ready |
| 2C | Core: scavenging runs + research stub | 1B only | Ready |
| 3B | App: all 1C panels + 1C exit check | 1B, 2B, 2C (not the A art track) | Blocked by 2B, 2C |
| 4B | Core: offline catch-up, tamper guard, bonus horde, settings in save | 3B (not the A art track) | Blocked by 3B |
| 5B | App: settings, welcome back, Horde Alerts, Engage + 1D exit check | 4B | Blocked by 4B |
| 6B | Art swap, balance pass, TestFlight (owner-led) | 5B (A art track optional) | Blocked by 5B |
| 1R | 3D: go/no-go spike on a real phone (DEBUG only) | — | Done 2026-11-01 — GO (D-028); iPhone 18 Pro 60 fps at 100 walkers with shadows |
| 2R | 3D: game playable in 3D, labeled boxes | 1R | Done 2026-11-01 — 3D view, ticker, camera, ModelRegistry (switch then removed by 6R) |
| 2M | 3D art: Blender → USDZ pipeline + buildings/props | 1R | Ready |
| 3R | 3D: placement, selection, walls | 2R | Done 2026-11-01 — ray picking, ghost/grid/footprint, wall line, outline + range ring, fading (D-032) |
| 3M | 3D art: animated zombies (+ survivors/defenders) | 2R, 2M | Blocked by 2M |
| 4R | 3D: combat effects, overlays, health bars | 3R, 3M | Blocked by 3R, 3M |
| 5R | 3D: performance pass, fps readout, Battery saver (3D is already the only view) | 4R | Blocked by 4R |
| 6R | 3D: retire 2D | owner yes | Done 2026-11-01 early, owner's call (D-030) |

Track A = zombie art (details at the bottom of this file; 2D zombie art is retired, D-030). Track B = 1C–1E gameplay. Track C = small parallel side work.
Track R = 3D renderer code, track M = 3D models (owner picked the 3D option on 2026-11-01, D-027). R/M "Needs" lines override the wave rule: they depend only on each other, not on track B. Full scope, exit checks and start prompts: `docs/plans/3d-rendering-plan.md` §6. The 2D living-world plan (`docs/plans/living-world-plan.md`, chunks 1K 1N 1F 1U 1S 2F 2S) is parked, not queued.

**Save versions:** the save is v3 now. Each Core chunk that changes saved data bumps the version by one, adds a migration, and adds a test that decodes a sample from the previous version. If 2B and 2C run at the same time, whichever merges second rebases onto the other's version (2B → v4, 2C → v5, or the other way round).

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
- **Scope (App only):** `SettingsView` (Time factor, Horde Alerts); `WelcomeBackView` (when away ≥ `welcomeBackMinAwaySeconds`); `NotificationScheduler` (one alert in the random window, honoring `quietHours` and `minAwayMinutes`, and asking notification permission only when the toggle is first turned on); `AppLifecycle` (saves the wall-clock time, runs catch-up on launch, checks whether the alert fired); an Engage button while a bonus horde waits; a DEBUG "pretend I was away N hours" option.
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

## Chunk 4R — Effects, overlays and health bars in 3D [Blocked by 3M]
- **Goal:** watching a horde reads as well as it did in 2D: you can see who shoots whom, what is hurt, what broke, and where the next horde comes from.
- **Needs:** 3R (done) and 3M (animated zombies; 3M needs 2M). Effects can be prototyped on boxes, but the exit check needs 3M's zombies.
- **Scope:** draw Core's `SimEvent`s (today `World3D.update` drains and drops them): tracers and muzzle flash from towers, hit/goo decals on the ground, dust when a wall breaks, short building shake on damage, trap flash; floating health bars over damaged buildings/walls and progress bars over buildings under construction (billboards); turret tops that turn toward their target (2M models the turret as a separate part); horde warning arrows at the map edges during the warning time. Same caps as the old 2D `EventPlayer` (git history before c7a8e9c) so a day-40 horde can't flood the scene; any new caps or timings are look constants, or JSON if they're tuning.
- **Do NOT build:** new kinds of effects beyond the 2D set, sound, particles that need iOS 26, the performance pass and fps readout (5R), new gameplay or Core rules.
- **Exit check:** the 1B on-screen defense check in 3D: horde from the debug menu walks to a weakened wall, breaks through (dust + rubble), pours in, towers aim and fire with visible tracers, damaged walls show health bars, "Held!" banner; a day-40 horde (debug) stays smooth in the simulator; `cd Core && swift test` and the simulator build pass.
- **Start prompt:** "Implement chunk 4R: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md, docs/features/hordes.md and the 4R section of docs/BUILD-QUEUE.md only."

## Chunk 6R — Retire 2D [Done 2026-11-01, D-030]
- Owner asked to move to full 3D right after 2R. Removed the SpriteKit renderer, iso/top-down sprites and Core 2D projection math; kept menus, `PlacementController` logic, the DEBUG spike, tools and source art folders. Building stays off until 3R.

## Chunk 2M — 3D model pipeline + buildings/props [Ready]
- **Goal:** every building, defense and decoration has a 3D model the 3D view can load.
- **Needs:** 1R (done). Can run alongside 2R: 2M touches `tools/blender/` and a model folder, 2R touches App code.
- **Scope:** `tools/blender/export_usdz.py` built from the spike's one-off script, keeping the 1R rules (1 tile = 1 m, origin at footprint ground centre, Z-up→Y-up with `convert_orientation`, curves converted to mesh, bevels applied); one USDZ per art id named like today (`bld_hq.usdz`…); a model folder in `App/` that both Debug and Release use; a missing-model checker listing art ids with no USDZ; export the study models; finish backs/roofs that were only modelled for one angle; model the missing assets in the same style; tower base and turret as separate parts so the turret can aim.
- **Do NOT build:** characters/zombies (3M), renderer code (2R), materials/lighting polish beyond "reads clearly" (5R).
- **Exit check:** the checker reports zero missing buildings/props; a review sheet shows each model from the 4 camera angles (D-029); models load in the 1R spike screen without errors.
- **Start prompt:** "Implement chunk 2M: read AGENTS.md, HighwayHoldout_Blender_Study/CLAUDE_HANDOFF.md, docs/plans/3d-spike-1R-results.md and the 2M sections of docs/BUILD-QUEUE.md and docs/plans/3d-rendering-plan.md only."


# BUILD-QUEUE — tickets, links, status

_Every piece of work is a **ticket** with an ID: `PREFIX-NNN`. The **Blocked by** column is the rule: **never start a ticket until every ticket in its Blocked by list is Done.** The **Related** column lists tickets that touch the same area or save version but do not block it (coordinate, don't wait). Mirror status changes into the Craft board._

**Prefixes**

| Prefix | Meaning |
|---|---|
| `CORE-` | Core engine: simulation rules, Content JSON, saves (Swift package, no drawing) |
| `APP-` | App UI: HUD, panels, menus, input, settings screens |
| `RND-` | 3D renderer: RealityKit scene, camera, effects, performance, character behaviour on screen |
| `MOD-` | 3D models and characters (buildings, defenses, zombies, humans, foliage) |
| `TXT-` | Textures, materials, lighting, trim sheets |
| `MAP-` | Map layouts |
| `ART-` | 2D art (zombie walker; retired with 2D, D-030) |
| `OWN-` | Owner tasks (you, not an agent) |
| `REL-` | Release: art swap, balance, TestFlight |

Numbers are just the next free number in that prefix (not a priority or a wave). Add a new ticket by taking the next number. Old names (1B, 3M-2, …) are kept in the **Old name** column so old notes and code comments still resolve. Older "milestone 1A–1E" names in `PHASE1-PLAN.md` / `PHASE1-TASKS.md` are a separate, earlier scheme and are unchanged.

_Seeded 2026-10-31 from `PHASE1-TASKS.md` 1C–1E and STATUS open questions. Renamed to ticket IDs 2026-11-01. Milestones done in the older scheme: 1A, 1V, 1B, isometric placement (D-022), wall-line tool (D-024)._

## MVP path (owner goal, 2026-11-01)

**Goal:** a playable first pass — enough to build that the town feels real, and supplies you can see coming in and going out on real screens, so it feels like a living place. The owner plays it, then picks the next phase.
**Sacrificed for MVP:** looks (new buildings borrow an existing model or a labeled box with their name), and most extra activities (one food chain is enough; no chickens, canning, hunting, spotters, offline catch-up yet).

Work these **in this order, one at a time** (each ticket's start prompt is in its section below). **Model** = which Claude to pick for that chat: Opus for rules, saves and judgment; Sonnet for screens on top of finished rules. If a Sonnet ticket fails its exit check twice, rerun it on Opus.

| # | Ticket | Model | Why it is in the MVP |
|---|---|---|---|
| 1 | CORE-010 | Opus | Room to build: smaller footprints, rotation, bigger fence. Goes first because it changes the starting layout CORE-005 adds to. |
| 2 | APP-006 | Sonnet | Placing a building takes one or two touches — building has to feel good. |
| 3 | CORE-005 | Opus | Food and water: survivors eat and drink; Garden, Well, Rain Catcher. The heart of "supplies". |
| 4 | APP-005 | Sonnet | Survival on screen: water in the HUD, Hungry/Thirsty banner, appeal, new build cards. **First playable checkpoint.** |
| 5 | CORE-008 | Opus | Guns and bullets: a second supply chain (scrap → bullets at the Ammo Bench) tied to defense. |
| 6 | CORE-009 | Sonnet | Three traps: more things to build outside the fence. |
| 7 | APP-004 | Sonnet | Guns, bullets and traps on screen. |
| 8 | CORE-012 | Opus | Town ledger: rates in/out per supply, survivor roster data, a "what happened" log. |
| 9 | APP-008 | Sonnet | Supplies and Town screens: the inventory page, survivor roster, town log. |
| 10 | REL-002 | Opus | MVP playtest: an agent plays 45 minutes, fixes blockers, writes the owner's one-page play guide. **MVP done.** |

**Parked until after the MVP playtest:** CORE-004/APP-003 (time away, alerts), CORE-006/CORE-007/APP-009 (more food, spotters), CORE-011/APP-007 (take over houses), RND-005 (performance; pull it in early if the owner plays on a real phone and it runs hot), and the whole looks track (MOD-003, MOD-009, MOD-010, TXT-001–003, MAP-001, RND-007, RND-008). OWN-001 downloads can continue any time.

## Tickets

| Ticket | Old name | Goal | Blocked by | Related | Status |
|---|---|---|---|---|---|
| CORE-001 | 1B | Core: upgrades + build queue + builders | — | CORE-002, CORE-003 | Done 2026-11-01 (D-033); 152 Core tests, save v3 |
| CORE-002 | 2B | Core: jobs (manual workers) + defenders | CORE-001 | CORE-003 | Done 2026-11-01 (D-034); save v4 |
| CORE-003 | 2C | Core: scavenging runs + research stub | CORE-001 | CORE-002 | Done 2026-11-01 (D-035); save v5; 198 Core tests |
| CORE-004 | 4B | Core: offline catch-up, tamper guard, bonus horde, settings in save | APP-002 (done) | APP-003, CORE-005, CORE-007 (save version) | **Ready** — matches Craft Next |
| CORE-005 | 1W | Core: food & water survival basics — water, upkeep, shortages, starter supplies, Garden, Well, Rain Catcher | APP-002 (done) | CORE-006, CORE-004 (save version), CORE-010 (both change the starting layout on both maps), APP-005 | **Ready** (owner design, D-042) |
| CORE-006 | 2W | Core: more food — canned goods + Cannery, Foraging, Hunting Lodge, Chicken Coop, Water Filter research | CORE-005 | APP-005, CORE-010 (new buildings use its 2×1 + rotation) | Blocked by CORE-005 |
| CORE-007 | 1L | Core: spotters — Lookout Post, watched edges, warning time, Binoculars/Radio research | APP-002 (done) | APP-005, CORE-004 (save version) | **Ready** (owner design, D-042) |
| CORE-008 | 1G | Core: guns + bullets — gun stock handed out automatically, armed survivors shoot, Ammo Bench | APP-002 (done) | CORE-009, APP-004, CORE-010 (Ammo Bench is 1×1; check the spot finder) | **Ready** (owner design, D-045) |
| CORE-009 | 1P | Core: new traps — Bear Trap, Pit Trap, Noise Maker, auto re-arm | APP-002 (done) | CORE-008, APP-004 | **Ready** (owner design, D-045) |
| CORE-010 | 1H | Core: smaller footprints (5 buildings 2×2 → 2×1), rotation, bigger starting fence (13×9), spot finder | APP-002 (done) | APP-006, MOD-010, MAP-001, CORE-005 (starting well + garden must fit the new ring) | **Ready** (owner request, D-046) |
| CORE-012 | 7S-C | Core: town ledger — per-supply rates in/out with sources, survivor roster data, town event log | CORE-005, CORE-008 | APP-008, CORE-009 (save version) | Specced 2026-11-01 — MVP #8 |
| CORE-011 | 5H | Core: take over neighborhood houses (claim a house/garage/shop as a Shelter, Workshop, Storage…) | CORE-010 | APP-007 | Specced 2026-11-01 — blocked by CORE-010 (owner said yes) |
| APP-001 | 1C | App: speed buttons + menu thumbnails | — | APP-002 | Done 2026-11-01 — speed buttons checked in the simulator; all 13 cards already had a picture |
| APP-002 | 3B | App: all panels + 30-minute exit check (milestone 1C) | CORE-001, CORE-002, CORE-003 | APP-001 | Done 2026-11-01 — notes in `docs/features/balance.md` "Playtest 3B" |
| APP-003 | 5B | App: settings, welcome back, Horde Alerts, Engage + milestone 1D exit check | CORE-004 | REL-001 | Blocked by CORE-004 |
| APP-004 | 2G | App: guns + traps screens (HUD guns/bullets, Ammo Bench panel, trap cards, shooting effects) | CORE-008, CORE-009 | REL-001 | Blocked by CORE-008, CORE-009 |
| APP-005 | 3W | App: survival screens (water in HUD, Hungry/Thirsty banner, appeal, Garden/Well/Rain Catcher cards) — narrowed for the MVP | CORE-005 | APP-009, APP-008, REL-001 | Blocked by CORE-005 — MVP #4 (spotter + more-food screens moved to APP-009) |
| APP-008 | 7S | App: Supplies and Town screens — inventory page, survivor roster, town log (UI kit) | CORE-012, APP-004, APP-005 | REL-002 | Specced 2026-11-01 — MVP #9 |
| APP-009 | 3W-2 | App: more-food + spotter screens (Cannery, Hunting, Foraging panels; Lookout panel; "Horde spotted" callout) | CORE-006, CORE-007, APP-005 | REL-001 | Specced 2026-11-01 — after MVP (split out of APP-005) |
| APP-006 | 2H | App: easier placing — ghost opens on a spot that fits, Rotate button, models scaled to fill their footprint | CORE-010 | MOD-010 | Blocked by CORE-010 |
| APP-007 | 6H | App + art: "Take over" button on houses, fortified house looks | CORE-011, APP-006, MOD-010 | CORE-011 | Specced 2026-11-01 — blocked by CORE-011, APP-006, MOD-010 |
| RND-001 | 1R | 3D: go/no-go spike on a real phone (DEBUG only) | — | RND-002 | Done 2026-11-01 — GO (D-028); iPhone 18 Pro 60 fps at 100 walkers |
| RND-002 | 2R | 3D: game playable in 3D, labeled boxes | RND-001 | MOD-001 | Done 2026-11-01 — 3D view, ticker, camera, ModelRegistry |
| RND-003 | 3R | 3D: placement, selection, walls | RND-002 | APP-006 | Done 2026-11-01 (D-032) |
| RND-004 | 4R | 3D: combat effects, overlays, health bars | RND-003, MOD-002 | RND-005 | Done 2026-11-01 (D-039) — day-40 ~60 fps (simulator) |
| RND-005 | 5R | 3D: performance pass, fps readout, Battery saver | RND-004 | APP-003 (settings screen) | **Ready** |
| RND-006 | 6R | 3D: retire 2D | owner yes | — | Done 2026-11-01 early, owner's call (D-030) |
| RND-007 | 3M-3 | 3D: town life — survivors walk between home and work and do their jobs (Tropico feel) | MOD-003 | RND-008, CORE-002 | Specced 2026-11-01 (draft) — blocked by MOD-003 |
| RND-008 | 4H | 3D: builders at work, Tropico-style (walk to site, carry, hammer; building rises in stages) | MOD-010, APP-006, OWN-001 (part C clips) | RND-007, CORE-001 | Specced 2026-11-01 — blocked by MOD-010, APP-006, clips |
| MOD-001 | 2M | 3D art: models for buildings, defenses, decorations (CC0, D-036) | RND-001 | MOD-010 | Done 2026-11-01 — 19 models, checker 19/19 (D-037) |
| MOD-002 | 3M | 3D art: animated zombies (+ survivors/defenders) | RND-002, MOD-001 | MOD-003 | Done 2026-11-01 (D-038) — Mixamo files local only |
| MOD-003 | 3M-2 | 3D art: human characters — defender + 4 survivor looks, task animations | MOD-002 | MOD-004…MOD-008, RND-007 | **Doing** — farmer drawn for defenders + strolling survivors; more looks/clips still to come |
| MOD-004 | 3M-2MH | MakeHuman trial: body-to-FBX script + medieval blacksmith profile | — (owner request) | MOD-003 | Done 2026-11-01 — does not complete MOD-003 |
| MOD-005 | 3M-2MH-I | Install MakeHuman on the owner's Mac | — (owner request) | MOD-004 | Done 2026-11-01 |
| MOD-006 | 3M-2MH-V | Generate the real MakeHuman body and verify FBX in Blender | MOD-004, MOD-005 | MOD-007 | Done 2026-11-01 — 28,796 triangles |
| MOD-007 | 3M-2MH-L | Clothed blacksmith draft within mesh budget | MOD-006 | MOD-008 | Done — 9,209 triangles |
| MOD-008 | 3M-2MH-F | Farmer survivor model + committed portable review assets | MOD-005 | MOD-003 | Done — 9,196 triangles; delivery on chunk-3m-2-humans |
| MOD-009 | 2T | 3D: foliage and scatter (trees, bushes, grass, rocks) | TXT-001, OWN-001 (part B) | MAP-001 | Blocked by TXT-001 and the rest of OWN-001 part B (have: grass clumps, dandelions, dry branches; missing: trees, bushes, rocks) |
| MOD-010 | 3H | 3D art: player buildings in the Chicago style (L1/L2/L3 looks, construction stages, rubble), on the trim sheet | CORE-010, TXT-003 | APP-006, MOD-001 | Specced 2026-11-01 — blocked by CORE-010, TXT-003 |
| TXT-001 | 1T | 3D: ground textures + map edge/road dressing | RND-002, OWN-001 (part A) | MOD-009 | **Ready, partly done** (D-043/D-044): photo textures per tile and road lines are in. Left: variation, soft edges, map border, fps/size checks. Asphalt texture still missing |
| TXT-002 | 1Q | 3D: lighting & materials spike — HDRI sky light, normal/roughness maps back, grounding shadows, fps + size table | OWN-001 (part E: HDRI + 3 texture sets) | TXT-003 | Specced 2026-11-01 — blocked by owner downloads Part E |
| TXT-003 | 2Q | 3D art: Chicago trim sheet, restyled neighborhood houses (back porches, cornices), alley poles/wires, curbs, decals | TXT-002 | MOD-010, MAP-001 | Specced 2026-11-01 — blocked by TXT-002 |
| MAP-001 | 3Q | Core + art: Roscoe Village map (`phase1_roscoe`, ~64×48), new-game map | TXT-003, CORE-010, MOD-009 | — | Specced 2026-11-01 — blocked by TXT-003, CORE-010, MOD-009 |
| ART-001 | 1A | Art: realistic walker static cutouts (Codex) | — | ART-003 | Done |
| ART-002 | 1D | Art: realistic static walker pilot | — | ART-001 | Done 2026-10-31 |
| ART-003 | 2A | Art: ZWALK-1 realistic walker limb animation | ART-001 | — | Retired 2026-11-01 — 2D walker frames no longer used (D-030); animated 3D zombie = MOD-002 |
| OWN-001 | 1X | **Owner:** download assets (terrain textures, foliage, Mixamo humans, props, HDRI) into the working folder | — | TXT-001, TXT-002, MOD-009, RND-008 | **Ready — you, not an agent**; checklist in `docs/OWNER-DOWNLOADS.md` (parts A–E). Mirrored in the Craft doc "Owner Downloads" and board card |
| REL-001 | 6B | Art swap, balance pass, TestFlight (owner-led) | APP-003, APP-005, APP-004, APP-009, REL-002 | — | Blocked by APP-003, APP-004, APP-005, APP-009, REL-002 |
| REL-002 | MVP | MVP playtest: agent plays 45 min, fixes blockers, tunes obvious numbers, owner play guide | APP-008 | REL-001 | Specced 2026-11-01 — MVP #10 (last) |

**Reading the board:** Done = finished. Ready = every Blocked-by ticket is Done, safe to start. Blocked = at least one Blocked-by ticket is not Done: do not start it. When a ticket finishes, update its row and flip any ticket it unblocks to Ready. Tickets with an old "Needs" line in their detail section below use that text as extra context; the **Blocked by** column wins if they disagree.

**Save versions:** the save is v5 now (CORE-002 → v4, CORE-003 → v5). CORE-004, CORE-005, CORE-006, CORE-007, CORE-008 and CORE-009 each add one; whichever merges first takes v6, the next v7, and so on (rebase onto the other's migration). Each Core ticket that changes saved data bumps the version by one, adds a migration, and adds a test that decodes a sample from the previous version.

Context: plan for CORE-010 / MOD-010 / TXT-002… is `docs/plans/buildings-and-look-plan.md` (D-046); 3D renderer plan `docs/plans/3d-rendering-plan.md` §6 (its R/M labels are the RND-/MOD- tickets above). The 2D living-world plan (`docs/plans/living-world-plan.md`) is parked, not queued.

## details

### CORE-001 — Core: upgrades + build queue + builders [Done 2026-11-01]
- **Result:** `BuildQueue`, `UpgradeSystem`, `ConstructionJob` in Core; `Command.upgrade` / `.cancelJob`; `PlacementProblem.queueFull`; `rules.cancelRefundPct` (75) added; save v3 with migration. Tests in `BuildQueueTests.swift` cover every exit-check item. Decision D-033 (replaces D-012). **Notes for CORE-002/APP-002:** until CORE-002, workers are auto-assigned, so builders come out of the whole survivor pool; APP-002 shows `loop.buildQueue`, `upgradeProblem(id:)`, `upgradeCost(id:)`. Repair of a damaged building is still instant (D-020).
- **Goal:** buildings level up 1→3, and construction is limited by build slots and free builders, the way `buildings.json rules` describes.
- **Needs:** nothing.
- **Scope (Core only):**
  - **Upgrades:** `Command.upgrade(id)`. Pays the next level's `cost`, checks `requiredHq`, takes `buildSeconds`. The building keeps working during its upgrade at its old level, and new-level effects (including HQ caps/housing) apply when it's done. `invested` grows so demolish refunds stay right.
  - **Build queue:** `rules.constructionSlotsByHq` active jobs, up to `constructionQueueLength` queued. The cost is paid when a job *starts*, not when it's queued. A queued job starts by itself when a slot, a free builder and the resources are all available. Each active job borrows `buildersPerJob` idle survivors until it's done. Commands: cancel a queued job (no charge) and cancel an active one (refund per a new JSON field, if you need one).
  - This replaces the timer-only build from D-012. Add a DECISIONS entry saying which entry it replaces.
  - Placement checks (`checkPlacement`, wall-line `planLine`/`placeLine`) still answer "is the spot valid?". Queue-full becomes a new `PlacementProblem` case.
  - Save: bump the version, and migrate in-progress builds into active jobs.
- **Do NOT build:** manual job assignment (CORE-002), App UI (APP-002), offline catch-up (CORE-004).
- **Exit check:** `cd Core && swift test` passes, with new tests for: upgrade cost/time/HQ gate, effects applying only when done, slot limit per HQ level, queue auto-start, pay-on-start, builders borrowed and returned, cancel refunds, and migration of a v2 save that has a half-built building.
- **Start prompt:** "Implement ticket CORE-001: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/construction.md, and the CORE-001 section of docs/BUILD-QUEUE.md only."

### APP-001 — App: speed buttons + menu thumbnails [Done 2026-11-01]
- **Result:** `SpeedButtonsView` in the HUD, built from `speedOptions`, current speed highlighted, remembered by the save. Simulator (iPhone 18 Pro): pause froze the horde clock and production, 2x ran twice as fast, 2x survived a relaunch. Menu thumbnails: no card is a placeholder any more (13 of 13 resolve); five use kit art, eight use the old isometric renders from `Art/Menu`. Replacing those with kit-style 3/4 art is an art job for ChatGPT (`tools/import_art.py --view ui`), not code.
- **Goal:** pause / 1x / 2x in the HUD, and real pictures on the build menu cards that still use placeholders.
- **Needs:** nothing. Core already has `Command.setSpeed` and `economy.json speedOptions`.
- **Scope (App only):** three HUD buttons built from `speedOptions` (no hardcoded speeds), with the current speed highlighted and remembered through the save. Finish the menu thumbnails listed in `docs/reviews/2026-10-31-art-and-build-review.md` / the UI kit handoff.
- **Do NOT build:** settings screen (APP-003), pause menu or inventory screens (suggest them in STATUS instead).
- **Exit check:** in the simulator, pause stops the horde clock and production, 2x doubles them, the speed survives a relaunch, and every build card shows a picture.
- **Start prompt:** "Implement ticket APP-001: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/hud-ui.md, and the APP-001 section of docs/BUILD-QUEUE.md only."

### CORE-002 — Core: jobs + defenders [Done 2026-11-01]
- **Result:** `Command.setWorkers`, `.trainDefender`, `.cancelTraining`, `.garrison`, `.holdSpot`, `.recallDefender` in Core (`Systems/Jobs/`, notes `docs/features/jobs-defenders.md`, D-034). `GameLoop.population` (working / building / away / defenders / training / idle, adds up to survivors), `trainingProblem()`. New events `defenderShot`, `defenderKnockedOut`, `defenderReady`. Save v4 (a v3 town keeps its full staffing). 46 new tests across CORE-002 and CORE-003. **Notes for APP-002:** `Building.assignedWorkers == nil` means full; defenders are `loop.state.base.defenders` (post `.hq`, `.garrison(buildingId:)`, `.hold(at:)`, `.knockedOut(ticksLeft:)`); the Barracks queue is `loop.state.base.training`. Training only progresses while the Barracks is staffed, so the panel should say so.
- **Goal:** the player chooses how many survivors work each building, and the Barracks trains defenders who garrison towers or hold a spot.
- **Needs:** CORE-001 only, because builders and workers share the same idle survivors.
- **Scope (Core only):**
  - **Jobs:** `Command.setWorkers(id, n)`. This replaces auto-staffing from D-011 (add a DECISIONS entry). New buildings still auto-fill from idle survivors, so it keeps "just working". Survivors split into working, building, away and idle.
  - **Defenders:** Barracks training uses `units.json training` (cost, `trainSeconds` × `trainTimeMultiplier`), `trainingQueueLength` and `maxDefenders`, and each defender uses up one survivor. **Garrison:** `garrison.allowedIn`, counts as the tower's worker, damage × `towerDamageMultiplier`. **Hold a spot:** shoots zombies in `range` with its own `damage`/`fireRate`. At 0 HP a defender is knocked out for `knockedOutSeconds`, then reappears at the HQ; it never dies.
  - Save migration.
- **Do NOT build:** permanent death (open balance question), App UI.
- **Exit check:** `swift test` passes, with tests for: worker limits, survivors never double-booked, staffing scaling production, training queue/cost/time, garrison counting as a worker with the boost, hold-spot combat, knock-out and return, and migration.
- **Start prompt:** "Implement ticket CORE-002: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/economy.md and combat.md, and the CORE-002 section of docs/BUILD-QUEUE.md only."

### CORE-003 — Core: scavenging runs + research stub [Done 2026-11-01]
- **Result:** `Command.startRun`, `.collectRun`, `.startResearch` (`Systems/Scavenging/`, `Systems/Research/`, notes `docs/features/scavenging-research.md`, D-035). Runs: `loop.state.base.runs` (timer + survivors), reward waits in `Building.heldReward`; research: `loop.state.base.research`, results in `loop.state.group.knowledge`. Effects live: metal wall unlock, tower range +1 (`loop.towerRange(id:)` is the number the range ring should draw), farms × 1.25 (also in the HUD rates). `runProblem(buildingId:runId:)`, `researchProblem(_:)` give the reason a button is greyed. Save v5. **Note for CORE-004:** training, runs and research all tick inside `GameLoop.step`, so catch-up by stepping advances them with no extra code.
- **Goal:** send survivors on timed runs for loot, and research the 3 stub items at the Workshop.
- **Needs:** CORE-001 only, because both use idle survivors and the same save. It can run in parallel with CORE-002.
- **Scope (Core only):**
  - **Runs:** one active run per post (`scavenger.runs.types`, `runsUnlocked` per level). Survivors are away (not working, not at risk) for `durationSeconds`. Rewards wait at the post and are multiplied by `runRewardMultiplier`; collecting clamps to caps and the remainder stays at the post.
  - **Research:** `research.json` items. Needs a finished, staffed Workshop; one at a time; `researchSeconds` ÷ `researchSpeedMultiplier`. Results go in `Group.knowledge` (they carry to future bases). Effects: unlock `wall_metal` (placement already checks for it), tower range +1, farm production × 1.25 (the Agriculture multiplier left out in milestone 1A).
  - Save migration.
- **Do NOT build:** risk of losses on runs (not in Phase 1), more research items.
- **Exit check:** `swift test` passes, with tests for: run timer/absence/reward/clamped collect, levels unlocking runs, research gate/time/effects, and Knowledge surviving a save round-trip.
- **Start prompt:** "Implement ticket CORE-003: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/economy.md, and the CORE-003 section of docs/BUILD-QUEUE.md only."

### APP-002 — App: all panels + the 30-minute exit check (milestone 1C) [Done 2026-11-01]
- **Playtest result (agent-played at 2x, fresh town, ~38 game-min):** HQ L2 reached (~game-min 28), hordes 1–4 all held (day 3–4 hordes are configured with a guaranteed brute), 1 wall lost, Scavenger run + Collect, Barracks train + garrison + hold-spot, Workshop research start/progress, Storage (cap 1000→1500) all worked on screen. HQ L3 not reached (needs 1200 scrap; see balance notes). Findings and knobs: `docs/features/balance.md` → "Playtest APP-002".
- **Result so far:** everything in Scope below is on screen and was driven in the iPhone 18 Pro simulator: selecting a building shows a panel with the level badge (tinted), Upgrade (cost; cream when Core says no and tapping shows the reason, progress bar while upgrading, Cancel job in the bar), Workers −/+, build-queue strip under the HUD, Barracks (Train, queue with cancel, defender cards with a Post… menu: wait at HQ / hold a spot by tapping the map / man a tower), tower panel (assign or release a defender), Scavenger Post (runs, Send, timer, Collect) and Workshop (research list). Defenders are drawn as labeled boxes (not directional until MOD-002). Range ring includes Marksmanship. Not done: the 30-minute playthrough that reaches HQ 2–3 and faces brutes, plus its balance notes for REL-001; Workshop research and Collect were only verified in Core tests (the simulator town had no staffed Workshop). Notes: `docs/features/hud-ui.md`.
- **Goal:** everything from CORE-001/CORE-002/CORE-003 can be used on screen, and a 30-minute session feels like progress.
- **Needs:** CORE-001, CORE-002, CORE-003 (not the A art track). All three are done; the Core calls to use are listed in the Results of CORE-001, CORE-002 and CORE-003 above and in `docs/features/core-api.md`. `PlacementMessages` already has text for every new Core error.
- **Scope (App only):** upgrade button (cost, `ui_level_badge` + tint per level), build-queue strip, worker −/+ on the building panel, Barracks panel (training queue), assigning a defender to a tower, defender units (directional) with a hold-spot command, Scavenger Post panel (start run, timer, collect), Workshop research panel. Optional, only if cheap: cosmetic survivors walking between the HQ and workplaces.
- **Do NOT build:** settings / welcome back / notifications (APP-003).
- **Exit check (milestone 1C):** a 30-minute session from a fresh start reaches HQ level 2–3 and faces brutes. Write down any balance knobs that feel off for REL-001.
- **Start prompt:** "Implement ticket APP-002: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/hud-ui.md and input.md, and the APP-002 section of docs/BUILD-QUEUE.md only."

### CORE-004 — Core: time & alerts
- **Goal:** time away counts (when the setting is on), and a Horde Alert leaves a frozen bonus horde waiting.
- **Needs:** APP-002 (so every queue that catch-up has to advance already exists). Not the A art track.
- **Scope (Core only):**
  - **Catch-up:** `OfflineCatchUp.run(state, awaySeconds)`. The App passes the wall-clock gap; Core still reads no clock. Capped at `maxOfflineCreditHours`, run in `catchUpStepSeconds` steps, output × `productionEfficiency`. It advances everything in `queuesThatProgress`, with **no combat**, and **the horde clock doesn't move**. It returns a summary (resource changes, things finished).
  - **Tamper guard:** a negative gap grants nothing; forward jumps are capped.
  - **Bonus horde:** `spawnBonusHorde` / `engageBonusHorde`, using `hordes.json bonusHorde` (size ×, loot ×, `maxWaiting`, frozen until Engage).
  - **Settings in `GameState`:** time factor (default OFF), Horde Alerts (default from `offline.json`). Save migration.
- **Do NOT build:** notifications or UI.
- **Exit check:** `swift test` passes, with tests for: the cap, no combat while away, the tamper guard, catch-up giving the same result as live ticking with no horde, the bonus horde never moving on its own, and migration.
- **Start prompt:** "Implement ticket CORE-004: read AGENTS.md, docs/STATUS.md, docs/MAP.md, the 1D section of docs/PHASE1-TASKS.md, and the CORE-004 section of docs/BUILD-QUEUE.md only."

### APP-003 — App: time & alerts
- **Goal:** the player can turn on the time factor and alerts, comes back to a summary, and can fight the bonus horde whenever they choose.
- **Needs:** CORE-004.
- **Scope (App only):** `SettingsView` (Time factor, Horde Alerts); `WelcomeBackView` (when away ≥ `welcomeBackMinAwaySeconds`); `NotificationScheduler` (one alert in the random window, honoring `quietHours` and `minAwayMinutes`, and asking notification permission only when the toggle is first turned on); `AppLifecycle` (saves the wall-clock time, runs catch-up on launch, checks whether the alert fired); an Engage button while a bonus horde waits; a DEBUG "pretend I was away N hours" option.
- **Exit check (milestone 1D):** queue work, close the app for 4 hours (or use the debug option), reopen. The summary feels good, and ignoring the alert costs nothing.
- **Start prompt:** "Implement ticket APP-003: read AGENTS.md, docs/STATUS.md, docs/MAP.md, the 1D App section of docs/PHASE1-TASKS.md, and the APP-003 section of docs/BUILD-QUEUE.md only."

### REL-001 — Art swap, balance, TestFlight (owner-led)
- **Goal:** Phase 1 is done: a 30-minute playtest leaves you wanting more, and coming back after 4 hours feels rewarding.
- **Needs:** APP-003 (A art track optional).
- **Scope:** final art import and anchor fixes in `presentation.json`; a balance pass with the `docs/features/balance.md` knobs; answering the STATUS balance questions and tuning `docs/GAME-RULES.md` (food upkeep is decided: yes, built in CORE-005). Also: sound hooks, an app icon check, the two art-import questions in STATUS, and TestFlight (the owner signs in Xcode; the agent prepares the archive command and checklist).
- **Exit check:** the Phase 1 "done when" line in `PHASE1-PLAN.md`.
- **Start prompt:** "Start ticket REL-001: read AGENTS.md, docs/STATUS.md, docs/features/balance.md, and the REL-001 section of docs/BUILD-QUEUE.md; walk me through the balance questions first."


### CORE-005 — Core: food & water survival basics [Specced 2026-11-01]
- **Goal:** survivors eat and drink, a new town starts with a little to live on, and the player grows food and water. Running short hurts but never wipes the town. Rules and proposed numbers: `docs/GAME-RULES.md` §4 (owner design, D-042).
- **Needs:** APP-002 (done). Can run beside CORE-004 or CORE-007; coordinate the save version (see "Save versions").
- **Scope (Core only):**
  - **Water** resource (starting 60, cap like food). Turn on `foodUpkeepPerSurvivorPerMin` (0.5) and add `survival.waterUpkeepPerSurvivorPerMin` (0.5); remove the loader's "must be 0" check. Fractions carry like production.
  - **Shortages:** Hungry / Thirsty output multipliers, no arrivals, leaving after `leaveAfterSeconds` (idle first, defenders last, never below `minSurvivors`, paused during hordes). Seeded order only. Owner confirmed: they leave, nobody dies.
  - **Town appeal:** arrival interval = `intervalSeconds ÷ appeal`; appeal from food/water going up and the held-horde streak, capped, halved after an HQ fall; 1–2 bonus newcomers after a held horde (seeded). Appeal goes in the HUD snapshot with its reasons. Save the streak.
  - **New buildings in `buildings.json`:** Garden (1 worker, food), Well (1 worker, water), Rain Catcher (0 workers, fills only during seeded rain showers from `survival.rain`, small tank). `waterUsePerMin` on Garden/Farm.
  - **Starting layout (coordinate with CORE-010, which grows the fence ring to 13 × 9 on both maps):** put the Well inside the ring and the broken Garden inside it too if it fits, else just outside the fence by the community garden; whichever of the two tickets lands second re-checks the positions. A working Well and a broken Garden (starts as rubble, fixed with the rubble rules), plus one broken Well on the map. Needs a map position for each on **both** maps (`Content/maps/phase1_chicago.json`, the new-game map, and `phase1_exit.json`; the validator wants every map to match the starting layout, D-044); add `startsBroken`. On the Chicago map, the broken Garden can sit by the community garden.
  - Agriculture research also boosts gardens. HUD snapshot gets water and net food/water per minute.
  - Save: bump the version; old saves get starting water and no new buildings (no free well).
  - If CORE-004 is done: catch-up runs upkeep (stops at 0, nobody leaves while away) and the summary reports "ran out". If not, CORE-004 does it.
- **Do NOT build:** canned goods, Cannery, hunting, foraging, coop (CORE-006); spotters (CORE-007); any App UI (APP-005); weather visuals (rain is a seeded number only); permanent death.
- **Exit check:** `swift test` passes with tests for: upkeep math over 10 min, Hungry/Thirsty multipliers, leaving order and the minimum, no leaving during a horde, rain catcher only filling in showers (seeded, same result twice), appeal math and its cap, faster arrivals with appeal 2.0, streak reset on HQ fall, bonus newcomers after a held horde (only with free housing), fixing the broken garden, save migration from v5 (or the current version), and `ContentFilesTests`.
- **Start prompt:** "Implement ticket CORE-005: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/GAME-RULES.md §4, docs/features/economy.md, and the CORE-005 section of docs/BUILD-QUEUE.md only."

### CORE-006 — Core: more food (canning, hunting, foraging) [Specced 2026-11-01]
- **Goal:** more ways to feed the town, and a reason to can food. Rules: `docs/GAME-RULES.md` §4.
- **Needs:** CORE-005.
- **Scope (Core only):** **Canned goods** resource with its own pantry cap (Cannery `storageAdded`), eaten after fresh food, not lost when the HQ falls (`economy.json hqFall.affects` stays food+scrap); starting food becomes 50 fresh + 100 canned. **Cannery** (workers convert food → canned per min). **Foraging** run at the HQ (reuse the scavenging-run system, available from day 1). **Hunting Lodge** with Short/Long Hunt runs (same system; long hunts cost canned rations). **Chicken Coop** (steady food, uses water). **Water Filtration** research (+50% wells). `survival.freshSpoilPctPerHour` knob, default 0. Save bump.
- **Do NOT build:** run risk/losses (IDEAS §2), fishing (Phase 2), App UI.
- **Exit check:** `swift test` passes with tests for canning conversion and pantry cap, eat order, HQ fall sparing canned goods, foraging/hunt rewards through the run system, coop water use, spoilage at a non-zero test value, migration.
- **Start prompt:** "Implement ticket CORE-006: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/GAME-RULES.md §4, docs/features/scavenging-research.md, and the CORE-006 section of docs/BUILD-QUEUE.md only."

### CORE-007 — Core: spotters [Specced 2026-11-01]
- **Goal:** survivors posted as spotters call out hordes; higher lookouts and better optics give earlier, richer warnings. Rules and numbers: `docs/GAME-RULES.md` §6 (owner design, D-042).
- **Needs:** APP-002 (done). Can run beside CORE-005 or CORE-004; coordinate the save version.
- **Scope (Core only):**
  - **Lookout Post** building (1×1, 1 worker, levels = height: `sightTiles`, `warningSeconds`, `intel`). HQ roof and staffed Watchtowers act as small lookouts.
  - **Watched edges:** an edge is watched if a staffed lookout sees its spawn point. Warning time per spawning edge = best watching lookout, else `spotting.unwatchedWarningSeconds`. This replaces the fixed `schedule.warningSeconds` (keep the horde clock itself unchanged).
  - **Spotted report** in the snapshot: edge, seconds left, and (by level) rough size or zombie types; a "spotted" event for the App's callout. Before spotting, the snapshot only offers a rough minutes-to-horde number.
  - **Research:** Binoculars (+warning), Radio (HQ 3, +warning; scavengers on runs also spot).
  - The bonus horde (CORE-004) always counts as spotted.
  - Save bump if anything new is saved (likely only the new building).
- **Do NOT build:** sound, banner or any UI (APP-005); spotters getting hurt; per-zombie fog of war.
- **Exit check:** `swift test` passes with tests for: watched vs unwatched warning time, best lookout wins, unstaffed lookout sees nothing, intel by level, research bonuses, rough clock rounding, same seed = same result.
- **Start prompt:** "Implement ticket CORE-007: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/GAME-RULES.md §6, docs/features/hordes.md, and the CORE-007 section of docs/BUILD-QUEUE.md only."

### CORE-008 — Core: guns + bullets [Specced 2026-11-01]
- **Goal:** the town keeps a stock of guns that hand themselves out; everyone holding one shoots during a horde, so small hordes can be held by your people alone. Bullets are made from scrap. Rules and numbers: `docs/GAME-RULES.md` §7 "Guns and bullets" (owner design, D-045).
- **Needs:** APP-002 (done). Can run beside CORE-005, CORE-007, CORE-009 or CORE-004; coordinate the save version.
- **Scope (Core only):**
  - **Guns** and **Bullets** resources (start 3 / 300; bullets capped, guns not).
  - **Automatic handout:** a pure, seeded function from the roster (defenders → idle → workers, oldest building first) that keeps the same people armed when counts don't change. No command to assign guns. Snapshot: armed count per building and at the HQ.
  - **Armed survivors shoot** from their building (idle ones from the HQ) using `units.json armedSurvivor` stats; reuse the tower targeting/firing code (a building with armed people acts as a small tower; damage adds up per person). They can't be hurt.
  - **Bullets (owner: towers too):** every shot takes bullets — armed survivors, defenders, the HQ gun and towers (tower `bulletsPerShot`, MG Nest 0.5); keep `guns.towersUseBullets` as a flag (true). One shared stock, fractions carried. Out of bullets: towers/HQ/survivors stop, defenders melee, traps unaffected.
  - Defender training takes a free gun (`needsGun`); refusal reason if none.
  - **Ammo Bench** building: scrap → bullets per minute while staffed; L2/L3 also make a gun on a timer while guns < survivors. If CORE-006's Cannery is built first, reuse its "convert input to output" effect; otherwise build that effect here generically so the Cannery can reuse it.
  - Gun sources: Long/Overnight run rewards, Brute gun drop chance (seeded). HQ fall takes `hqFall` % of bullets.
  - Save bump: gun and bullet stocks (assignments are recomputed, not saved).
- **Do NOT build:** UI, shooting visuals (APP-004), gun types/quality, per-tower ammo stores, survivors getting hurt.
- **Exit check:** `swift test` passes with tests for: handout order and stability, a 5-walker horde held by armed survivors alone with no towers staffed, 1 bullet per shot (towers and HQ included, MG Nest half), towers stop and defenders melee at 0 bullets, the first 5-walker horde still held with the starting bullets, training refused without a gun, Ammo Bench conversion and gun timer, run/brute gun rewards (seeded), HQ fall bullet loss, migration.
- **Start prompt:** "Implement ticket CORE-008: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/GAME-RULES.md §7, docs/features/combat.md, docs/features/jobs-defenders.md, and the CORE-008 section of docs/BUILD-QUEUE.md only."

### CORE-009 — Core: new traps [Specced 2026-11-01]
- **Goal:** more ways to set traps: a Bear Trap that holds a zombie, a Pit Trap that swallows one, and a Noise Maker that pulls zombies into a kill zone. One-shot traps re-arm themselves after each horde. Rules: `docs/GAME-RULES.md` §7 "Traps" (D-045).
- **Needs:** APP-002 (done). Can run beside CORE-008, CORE-005, CORE-007.
- **Scope (Core only):** three new trap entries in `buildings.json` (1×1, outside walls, not blocking); trap state "armed / sprung" per trap; Bear Trap hold (zombie stops moving for `holdSeconds`, shorter for Brutes); Pit Trap removes a walker/runner (counts as a kill, pays loot) or damages a Brute; Noise Maker adds a temporary attraction to the flow field toward itself (radius, seconds) when the horde arrives; after a horde ends, sprung traps re-arm automatically for `rules.trapRearmPct` of their cost if scrap allows (oldest first), else stay sprung until scrap is there. Logic lives next to spikes/wire in `ZombieMovement` / `pathing.md`; split files to stay under ~250 lines. Save bump (trap armed state).
- **Do NOT build:** UI (APP-004), fire traps, player-triggered traps.
- **Exit check:** `swift test` passes with tests for: bear trap hold time (normal vs Brute), one use per horde, pit removes a walker but not a Brute, noise maker changes paths only for its time and radius, re-arm after the horde with and without enough scrap, same seed = same result, migration.
- **Start prompt:** "Implement ticket CORE-009: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/GAME-RULES.md §7, docs/features/pathing.md, and the CORE-009 section of docs/BUILD-QUEUE.md only."

### APP-004 — App: guns + traps screens [Specced 2026-11-01]
- **Goal:** the player can see and use CORE-008 and CORE-009.
- **Needs:** CORE-008, CORE-009.
- **Scope (App only):** HUD "Guns 5/12 armed · Bullets 140" with a low-bullets warning and an "Out of ammo" banner; Ammo Bench panel (output, gun timer, workers, upgrade); "needs a free gun" reason on Barracks Train; build-menu cards for the three traps (labeled boxes until models exist) and a "sprung / re-arming" look; tracers from buildings with armed people (reuse RND-004's `EffectsLayer3D`); bear-trap hold and pit "fall" effects; noise-maker pulse ring.
- **Do NOT build:** new 3D models (separate art chunk), survivors visibly standing at windows (RND-007).
- **Exit check:** in the simulator, a fresh town holds the first horde with tracers coming from the HQ and workplaces; bullets go down; an Ammo Bench refills them; a bear trap holds a zombie and re-arms after the horde.
- **Start prompt:** "Implement ticket APP-004: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/GAME-RULES.md §7, docs/features/hud-ui.md, docs/features/rendering-art.md, and the APP-004 section of docs/BUILD-QUEUE.md only."

### APP-005 — App: survival screens [Specced 2026-11-01; narrowed for the MVP]
- **Goal:** the player can see and use everything from CORE-005. (Spotter and more-food screens moved to APP-009 so the MVP doesn't wait on CORE-006/CORE-007.)
- **Needs:** CORE-005.
- **Scope (App only):** HUD water with net per minute (food already there; add net per minute too), a red Hungry/Thirsty banner, and town appeal with its reasons; build-menu cards for Garden, Well and Rain Catcher. **Stand-in looks:** each new building borrows an existing model in `ModelRegistry` (e.g. Garden → farm, Well/Rain Catcher → storage) with its name label, or a labeled box; list the borrowed ids in `docs/features/models-3d.md` so a later art ticket can replace them.
- **Do NOT build:** new 3D models, weather visuals, town-life walking (RND-007), spotter or Cannery/Hunting screens (APP-009).
- **Exit check:** in the simulator, a fresh town: fix the garden, build a Well, watch water and food tick, let water run out and see the banner and output drop, then recover.
- **Start prompt:** "Implement ticket APP-005: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/GAME-RULES.md §4, docs/features/hud-ui.md, and the APP-005 section of docs/BUILD-QUEUE.md only."

### APP-009 — App: more-food + spotter screens [Specced 2026-11-01 — after the MVP]
- **Goal:** the player can see and use CORE-006 and CORE-007 (split out of APP-005).
- **Needs:** CORE-006, CORE-007, APP-005.
- **Scope (App only):** HUD canned goods; Cannery, Hunting Lodge and HQ Foraging panels (reuse the scavenging panel); Lookout panel (sight, warning, upgrade); a sight ring when a lookout is selected and a marker on watched edges; the "Horde spotted — east off-ramp, 75 s · about 15 · 2 brutes" banner with a siren sound hook; the rough "next horde in ~6 min" clock until spotted. Stand-in looks as in APP-005.
- **Do NOT build:** new 3D models, weather visuals.
- **Exit check:** in the simulator: run a Cannery, build a lookout by the east road and get an early callout for an east horde but a late one for an unwatched edge.
- **Start prompt:** "Implement ticket APP-009: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/GAME-RULES.md §4 and §6, docs/features/hud-ui.md, and the APP-009 section of docs/BUILD-QUEUE.md only."

## ART-002 — Realistic static walker [Done]
- **Goal:** demonstrate one realistic zombie end to end in the current game.
- **Needs:** none; owner-authorized art pilot, independent of milestone 1C.
- **Scope:** front/back transparent cutouts, base fallback, existing mirrored directions, matching canvas, importer, app build and simulator review. Sources deleted with the 2D cleanup (git history).
- **What NOT to build:** limb animation, extra zombie types, top-down replacement, new gameplay or 3D rig.
- **Exit check:** build succeeds; all four directions render with clean transparency in the real app. Passed; `in-game-four-facings.png` uses a paused review fixture. Pre-test save restored byte-for-byte.
- **Start prompt (review only):** “Review chunk ART-002 realistic walker: open its README, preview and simulator capture; do not regenerate art.”

## ART-003 — Realistic walker limb animation [Retired — D-030]
- **Retired 2026-11-01:** the game no longer draws 2D sprites, so 2D walker frames aren't needed. The Mixamo walker's next life is the animated 3D zombie in chunk MOD-002. Text below kept for history.
- **Goal:** the walker visibly steps and swings its arms while moving; owner approved a Mixamo stock replacement in D-026.
- **Needs:** chunk ART-001 static walker only (also recorded as ART-002 by the static-art chat); no gameplay chunk dependency.
- **Scope:** six poses in each of two source facings, mirrored west, stable canvas/feet, distance-driven cached textures, static fallback, presentation JSON and simulator checks. First prototype is implemented; see `docs/features/zombie-walk-animation.md`.
- **What NOT to build:** runner/brute art, attack swings, top-down replacement, gameplay or save changes.
- **Exit check:** smooth alternating steps without scale/anchor jitter, clean four-facing movement, pause/attack stop, missing-frame fallback, build and Core tests pass; day-40 performance matches baseline. Initial build/tests and day-7 horde passed; full visual exit check remains.
- **Current route / dependency:** ZWALK-1M steps 0–3 implemented (Yaku J Ignite / Zombie Walk); fixture-based checks and builds pass. Prototype `c12e557`. Normal-horde hands-on gait/foot-sliding acceptance remains; native simulator clicks failed. See `docs/features/zombie-walk-mixamo.md`.
- **Start prompt:** “Continue ZWALK-1M / chunk ART-003: read docs/features/zombie-walk-mixamo.md. Implementation is in and D-026 approved. Review walker-mixamo/README.md and preview.gif, then check a normal horde in the simulator for smoothness, all four directions, foot sliding and the Horde now menu path. Close ART-003 only when those pass. Walker only; do not regenerate or start runner/brute.”

## RND-001 — 3D go/no-go spike [Done — GO, D-028]
- **Goal:** see our own models in real 3D on an iPhone, with numbers, before committing to the 3D switch.
- **Needs:** nothing (owner approved starting it outside Phase 1, D-027).
- **Scope:** a DEBUG-only RealityKit screen, not wired to the game: ground plane, HQ + ~5 Blender study models exported by hand to USDZ, a low sun with shadows, orbit camera (pan, pinch, twist, limited tilt), then 35 and 100 Mixamo walkers walking in circles. Measure fps (simulator, and a real phone if one is available). Confirm: iOS 17 vs 18 (`RealityView` virtual camera), frame-rate capping, particles/billboards availability.
- **Do NOT build:** game hookup, `GameStore` changes, the export script, other models, any Core change, raising the deployment target (that's an owner decision after RND-001).
- **Exit check:** screenshots/video beside the current 2D view, an fps table, a one-page "gaps found" note in `docs/plans/3d-spike-1R-results.md`; app still builds and 2D game is unchanged; owner decides go/no-go.
- **Start prompt:** "Implement ticket RND-001: read AGENTS.md, docs/STATUS.md, the RND-001 section of docs/BUILD-QUEUE.md and docs/plans/3d-rendering-plan.md only. Build the DEBUG RealityKit spike and report fps and screenshots."
- **Result (2026-11-01):** `docs/plans/3d-spike-1R-results.md` + screenshots in `docs/plans/spike-1R/`. Spike in `App/Spike3D/` (Debug menu → "3D spike (RND-001)"); one-off export `tools/blender/spike_export_usdz.py`. Simulator: 60 fps with 100 walkers + shadows on both RealityView (iOS 18) and ARView non-AR (iOS 17). RealityView, particles, billboards, opacity fades are iOS 18+; no public frame-rate cap. Real iPhone 18 Pro: 60 fps at 0/35/100 walkers, shadows on or off, both routes. Recommendation: GO with minimum iOS 18. **Owner: GO, minimum iOS 18 (D-028).** An older-phone check and a heat check stay with RND-005.

## RND-002 — Game in 3D [Done 2026-11-01]
- **Goal:** the real game playable in 3D with labeled boxes.
- **Result:** RealityView world (virtual camera): one merged ground mesh, labeled placeholder boxes, buildings/zombies synced to Core, dusk sun with shadows. `ModelRegistry` loads `<artId>.usdz` in the background, so the RND-001 spike's six models already show. Shared `GameTicker` (display link) runs the clock, which pauses behind the DEBUG spike. Snapped 4-angle camera (one 90° step per two-finger twist, eased), pan, pinch toward the fingers, tilt, minimum camera height, zoom-out clamped to the map; numbers in `presentation.json reality3d`. Core: tested `WorldMapping3D` and `OrbitCamera3D`. 129 Core tests; simulator build clean; checked on the simulator with the owner's save (horde ran, zombies walked to the breach). The 2D/3D switch was built and checked, then removed when the owner retired 2D (RND-006, D-030). Notes: `docs/features/rendering-art.md`, D-031.

## RND-003 — Placement, selection and walls in 3D [Done 2026-11-01, D-032]
- **Goal:** building feels as good as the D-022 isometric placement did, now in 3D. Until this lands the player can't build (2D is gone, D-030).
- **Needs:** RND-002 (done). Independent of MOD-001/MOD-002: works with boxes or models.
- **Scope:** switch the Build button back on (`GameRootView.canBuildIn3D`); taps turn into a ray from the finger: ground tile via `OrbitCamera3D.groundPoint`, buildings via collision boxes (tall roofs win, like the old iso rule); select a building (outline + range ring on the ground for towers/HQ, the existing selection bar); placement ghost = see-through model or box, tile grid around it, green/red footprint, reason in the existing bar; a drag that starts on the ghost moves it (lifted above the finger), any other one-finger drag pans; Move/Cancel/Confirm through the existing `PlacementController`; wall tool: one finger drags a line (count + cost, skipped tiles red), two fingers pan; buildings between the camera and the ghost fade (`OpacityComponent`), from any of the 4 angles. Tunables (grid radius, lift, fade) as named look constants or JSON if they're tuning.
- **Do NOT build:** effects, health/progress bars, turret aiming (RND-004), real models (MOD-001), animated zombies (MOD-002), new placement rules (Core is unchanged).
- **Exit check:** repeat the D-022 simulator checks in 3D at two camera angles: place a 1×1 (wall line at the map edge), a 2×2 inside the walls, move the HQ then Cancel (no change), invalid spots blocked with reasons, tap a roof to select, demolish with refund; `cd Core && swift test` and the simulator build pass.
- **Start prompt:** "Implement ticket RND-003: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/input.md, docs/features/rendering-art.md and the RND-003 section of docs/BUILD-QUEUE.md only."
- **Result:** exit check passed in the iPhone 18 Pro simulator at two camera angles: HQ roof tap selects (outline + range ring), Move HQ + drag onto the highway (red, reason, Confirm off) + Cancel = unchanged, farm (2×2) blocked on a wall then placed inside the walls (−50 scrap; HQ and watchtower faded in front of the ghost), demolish refunded 25 scrap; second angle: two-finger pan in the wall tool, 9 wood walls along the map edge (−90 scrap), a line across the farm showed red skipped tiles and the wall limit, watchtower roof tap selects with its ring. 134 Core tests pass; build has no warnings. Simulator save restored byte-for-byte.

## MOD-002 — Animated zombies (+ survivors/defenders) in 3D [Done 2026-11-01, D-038]
- **Goal:** zombies (and survivors/defenders) are real animated 3D characters instead of green boxes: they walk without foot sliding, turn smoothly and attack.
- **Needs:** RND-002 and MOD-001 (both done).
- **Scope:** export the Mixamo walker (`HighwayHoldout_3D_Sources/mixamo-walker/`, D-026; the RND-001 spike already exports it with `tools/blender/spike_export_usdz.py`) as `zmb_walker.usdz` with walk + attack (+ idle if available) at the game scale (0.41 tiles per metre, like D-037); `ZombieLayer3D` plays walk at a speed matched to movement (stride 0.6149 tiles, as measured), turns smoothly, holds attack while bashing; runner and brute: a Mixamo variant or the walker re-tinted/re-scaled at first; survivors/defenders: one simple Mixamo character if quick, else keep boxes; decide how the Mixamo-derived USDZ is kept (today it is git-ignored, D-026 terms) and record it in DECISIONS.
- **Do NOT build:** effects, health bars, turret aiming (RND-004); new zombie types or gameplay; building models (MOD-001, done).
- **Exit check:** a normal horde in the simulator: no visible foot sliding from all 4 camera angles, turning looks smooth, attack plays while bashing a wall; removing a character USDZ shows the labeled box; a day-40 horde stays smooth (fps readout); `cd Core && swift test` and the simulator build pass.
- **Start prompt:** "Implement ticket MOD-002: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/zombie-walk-mixamo.md, docs/features/rendering-art.md, docs/features/models-3d.md and the MOD-002 section of docs/BUILD-QUEUE.md only."
- **Progress (2026-11-01):** built: `tools/blender/export_characters.py` (walker → `App/Models/zmb_walker.usdz` + `.anim.json`, stride 0.6095 tiles, 2.4 MB), `CharacterMotion3D` in Core (glide between ticks, capped turning, walk rate = speed ÷ stride; 6 tests, 204 Core tests pass), `CharacterAnimator3D`, runner/brute = walker scaled/tinted (`presentation.json reality3d.characters`), defenders play idle once a model exists. Checked in the iPhone 18 Pro simulator: zombies are animated models facing their way of travel; removing the USDZ shows labeled boxes; build clean; save restored byte-for-byte. Mixamo files git-ignored (public repo, D-038).
- **Result (2026-11-01):** owner signed in to Mixamo; downloaded Zombie Attack + Zombie Idle for Yaku J Ignite (FBX Binary, With Skin, 30 fps) into `HighwayHoldout_3D_Sources/mixamo-walker/`; exporter now writes walk (0–4.0 s), attack (4.03–8.63 s), idle (8.67–14.73 s), 3.0 MB. In the simulator a temporary log confirmed walkers, runners and brutes switch to attack while bashing and idle when standing (probe removed). 204 Core tests pass; build clean; save restored byte-for-byte.
- **Not checked / left:** close visual foot-sliding check from all 4 camera angles (stills + maths only); day-40 fps (no in-game readout until RND-005); defenders stay boxes (no defender model downloaded; drop `mixamo-defender/defender_idle.fbx` in and rerun the exporter).

## RND-004 — Effects, overlays and health bars in 3D [Done 2026-11-01, D-039]
- **Goal:** watching a horde reads as well as it did in 2D: you can see who shoots whom, what is hurt, what broke, and where the next horde comes from.
- **Needs:** RND-003 (done) and MOD-002 (animated zombies; MOD-002 needs MOD-001). Effects can be prototyped on boxes, but the exit check needs MOD-002's zombies.
- **Scope:** draw Core's `SimEvent`s (today `World3D.update` drains and drops them): tracers and muzzle flash from towers, hit/goo decals on the ground, dust when a wall breaks, short building shake on damage, trap flash; floating health bars over damaged buildings/walls and progress bars over buildings under construction (billboards); turret tops that turn toward their target (MOD-001 did not split them: add a separate turret model for the watchtower and MG nest here); horde warning arrows at the map edges during the warning time. Same caps as the old 2D `EventPlayer` (git history before c7a8e9c) so a day-40 horde can't flood the scene; any new caps or timings are look constants, or JSON if they're tuning.
- **Do NOT build:** new kinds of effects beyond the 2D set, sound, particles that need iOS 26, the performance pass and fps readout (RND-005), new gameplay or Core rules.
- **Exit check:** the milestone 1B on-screen defense check in 3D: horde from the debug menu walks to a weakened wall, breaks through (dust + rubble), pours in, towers aim and fire with visible tracers, damaged walls show health bars, "Held!" banner; a day-40 horde (debug) stays smooth in the simulator; `cd Core && swift test` and the simulator build pass.
- **Start prompt:** "Implement ticket RND-004: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md, docs/features/hordes.md and the RND-004 section of docs/BUILD-QUEUE.md only."
- **Result (2026-11-01):** new App layers `EffectsLayer3D` (+ `EffectMeshes3D`), `TurretLayer3D`, `BarsLayer3D`, `HordeWarning3D`; new turret models `def_watchtower_gunner`, `def_mg_nest_gun` (with `muzzle` empties); the watchtower is now an open platform so its gun shows; `check_models.py` counts turrets (21/21). No Core change (204 Core tests pass); build has no warnings. Exit check in the iPhone 18 Pro simulator with test saves: warning arrows + red edge tiles at the warned edges; horde walked to weakened walls (red health bars), broke through (dust cloud caught in a frame, rubble), poured in, the watchtower gun turned and fired yellow tracers, goo where zombies died; with a full-health HQ the horde ended with "Held! +49 scrap · +45 food" (HQ bar back to green); earlier runs with a near-dead HQ ended "HQ fell". Day-40 horde (up to 47 zombies): 58.6–59.6 fps from a temporary display-link probe (removed). Simulator save restored byte-for-byte.
- **Not checked:** the MG nest gun in the game (the test town has none; model exported and reviewed only); defender tracers (no defender holding a spot in the test town); trap flash (no spikes in the test town); real-phone fps (RND-005).

## RND-005 — Performance pass, fps readout, Battery saver [Ready]
- **Goal:** the 3D game stays smooth and cool on real phones, and the player can see/limit it.
- **Needs:** RND-004 (done).
- **Scope:** a DEBUG fps + entity-count readout in the game (like the old 2D one; RND-004 used a temporary display-link probe); stress tests: day-40 horde and ~100 zombies (debug), on the simulator and on the oldest supported real iPhone available; tune what costs most (shadow distance, zombie model detail, effect caps) with numbers in `presentation.json` where they are tuning; a **Battery saver** setting (e.g. 30 fps cap via the display link, shadows off) saved with the player's settings; an app-size report (`App/Models` is ~20 MB + characters); a 30-minute play session heat check on a real phone.
- **Do NOT build:** new effects or models, gameplay changes, the milestone 1D settings screen beyond the one Battery saver switch (APP-003 owns the settings screen; put the switch where APP-003 can move it).
- **Exit check:** 60 fps at day 40 and ≥45 fps at 100 zombies on the oldest phone tried (table in `docs/plans/`), Battery saver visibly lowers fps/shadows and survives a relaunch, a 30-minute session without the phone getting hot, size report; `cd Core && swift test` and the simulator build pass.
- **Start prompt:** "Implement ticket RND-005: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md and the RND-005 section of docs/BUILD-QUEUE.md only. Start with the fps readout and a stress test."

## RND-006 — Retire 2D [Done 2026-11-01, D-030]
- Owner asked to move to full 3D right after RND-002. Removed the SpriteKit renderer, iso/top-down sprites and Core 2D projection math; kept menus, `PlacementController` logic, the DEBUG spike, tools and source art folders. Building stays off until RND-003.

## MOD-001 — 3D models for buildings, defenses and decorations [Done 2026-11-01, D-036, D-037]
- **Goal:** every building, defense, construction/rubble state and decoration has a 3D model the game loads.
- **Scope (as rewritten after D-036):** realistic CC0 models: buildings assembled from Quaternius Downtown City MegaKit modular pieces, props from Poly Haven, simple barricades/stakes/wire modelled with Poly Haven textures; pipeline `tools/blender/export_usdz.py` + `model_kit.py` + `recipes_{buildings,defenses}.py` → `App/Models/<artId>.usdz`; missing-model checker `tools/check_models.py`; 4-angle review sheets.
- **Result:** 19 models (7 buildings, 6 defenses, 2 construction sites, 2 rubble, car wreck, dead tree), ~20 MB in all (512 px textures, no normal maps, props ≤ ~1,500 triangles). `check_models.py`: 19/19. Review sheets `docs/plans/models-2m/`; in the game on the iPhone 18 Pro simulator they replace the boxes (`docs/plans/models-2m/in-game.jpg`); the RND-001 spike's study scene loads them too (old study USDZ removed). 198 Core tests pass; build clean; simulator save restored byte-for-byte. Notes: `docs/features/models-3d.md`.
- **Not done (moved on):** separate turret tops that can aim (now in RND-004); a different look per building level (L2/L3); measuring on a real phone (RND-005).

## MOD-004 — MakeHuman script + blacksmith profile [Done 2026-11-01]
- **Goal:** give the owner a reproducible body/FBX script and a precise age-45 medieval blacksmith brief.
- **Needs:** owner request only; no wave dependency. Running it needs MakeHuman with scripting/FBX plugins enabled.
- **Scope:** `tools/makehuman/` script and instructions, measured-height report, `docs/plans/blacksmith-profile.md` with face/build/posture/costume targets. D-041.
- **Do NOT build:** full cast, custom garment assets, rigging/animation, game hookup, new gameplay or a medieval game setting.
- **Exit check:** script syntax and mocked plugin-style execution pass (exact values, output isolation, safeguards, invalid-FBX rejection); profile and instructions delivered. Live generation and Blender import are explicitly pending, outside this preparation chunk.
- **Start prompt / next:** "Continue the MakeHuman trial for chunk MOD-003; follow tools/makehuman/README.md and verify one real FBX in Blender."

## MOD-005 — Install MakeHuman [Done 2026-11-01]
- **Goal:** owner can open MakeHuman on this Apple Silicon Mac without setup work.
- **Needs:** owner installation request; no wave dependency.
- **Scope:** official pinned source, official CC0 asset pack, private Python environment, user Mac launcher, enabled scripting/FBX, link to existing script.
- **Do NOT build:** game changes, sculpted character, rigging or animation.
- **Exit check:** modeling window observed; logs confirm both plugins and startup complete; `pip check` passes. Source reports 1.3.0 alpha. Install details in `tools/makehuman/README.md`.
- **Start prompt / next:** "Continue the MakeHuman trial for chunk MOD-003: open the installed app and verify one real FBX using tools/makehuman/README.md."

## MOD-006 — Live MakeHuman export and Blender check [Done 2026-11-01]
- **Goal:** produce a real source body and prove the generated FBX imports correctly.
- **Needs:** MOD-004 + MOD-005 only, not wave dependencies.
- **Scope:** run existing script in MakeHuman, verify FBX height/finite geometry/image paths in Blender, save imported source and preview. Checker `tools/blender/check_makehuman_fbx.py`; exact output folder in `tools/makehuman/README.md`.
- **Do NOT build:** finished blacksmith sculpt/garments, mobile optimization, rig/animation or game integration.
- **Exit check:** passed real export/import; exact sliders, height agrees within <0.001 mm, two finite meshes, no missing image paths, reviewed clean preview with imported custom normals disabled. FBX 831,468 bytes; 28,796 triangles exceeds mobile target; requested maximum height = 2.44386 m. No source body rescale.
- **Next / start prompt:** "Continue chunk MOD-003 from the verified MakeHuman base: read tools/makehuman/README.md and blacksmith-profile.md, apply the intended look and optimize the body/garments to the phone budget before rigging. Keep the original source and its exact slider values."

## MOD-007 — Clothed blacksmith review model [Done 2026-11-01]
- **Goal:** move beyond the bare source to a clothed, portable draft under the mesh budget.
- **Needs:** MOD-006 only; no wave dependency.
- **Scope:** fitted CC0 source clothes/hair/skin and head modifiers, apron/beard, one atlas, ≤10k triangles, saved blend/FBX/GLB, four-angle review and clean FBX reimport. Bundle/results in `tools/makehuman/README.md`.
- **Do NOT build:** full cast/game hookup, new gameplay, final historical likeness or custom animation systems.
- **Exit check:** 9,209 finite triangles; one material/atlas; ~1.22 MB static FBX/GLB; actual FBX reimport preserves count/height/images; four final views reviewed. Fine skin/scar/period-clothes details and deformation/rig/animation explicitly remain.
- **Next / start prompt:** use the updated MOD-003 continuation below for the rig/motion trial before extending the cast.

## MOD-008 — Farmer and portable review assets [Done 2026-11-01]
- **Goal:** one additional model type from the town-life spec, finished through exported/reviewed files and local commit.
- **Needs:** installed MakeHuman pipeline only; independent of the wave rule.
- **Scope:** adult woman farmer (40, faded overalls/grey shirt/boots/short hair), source recipe, ≤10k mesh, single atlas, FBX/GLB/packed blend, four views; include both farmer and blacksmith portable CC0 model packages in repo.
- **Do NOT build:** remaining cast, Core/gameplay changes, task animations or full MOD-003 integration.
- **Exit check:** actual MakeHuman source generation; farmer 9,196 triangles, one atlas/material, ~1.41 MB FBX; four angles reviewed. Both models pass standalone blend / isolated FBX / GLB counts/height/texture checks; syntax + whitespace pass. Owner-requested commit on `chunk-3m-2-humans`, no merge/push.
- **Next / start prompt:** "Continue chunk MOD-003 from the committed farmer: read the asset README and reports, test rig/deformation and walk/carry/dig clips on this normal-height character before expanding the cast."

## MOD-003 — Human characters: defender + survivor looks [Specced 2026-11-01, draft]
**First look in game (2026-11-01):** the owner's MakeHuman farmer, rigged/animated in Mixamo (walk, run, shooting rifle), is exported as `sv_farmer` and used for **every** human for now: defenders (rifle clip during hordes) and up to 40 survivors strolling at random around the HQ (`SurvivorLayer3D`, hidden during hordes). Still to do in MOD-003: an idle clip (humans stand frozen in a walk pose), a rifle prop, more looks (blacksmith + others) and task clips (carry, hammer, dig, talk); RND-007 then gives them real jobs. Notes: `docs/features/characters-3d.md`.

**Farmer model now ready as the next rig trial source (MOD-008).** Use the committed
`HighwayHoldout_3D_Sources/makehuman/farmer/` package; normal height, no apron, 9,196 triangles.
First verify rig/deformation, then idle/walk/run/carry/dig/pick-up/talk clips, 512 px atlas and
full ≤3 MB animated size. Owner handles Mixamo uploads/downloads per OWN-001; integration stays on
the human branch and merges only with owner approval. This task does not remove RND-007's dependency.
Local `makehuman/sv-farmer_{walking,running,rifle}.fbx` downloads appeared during staging;
Mixamo metadata confirmed in walking file, all preserved/ignored under D-038. Inspect their
character/rig compatibility first; not used or validated in this static model delivery.

**Clothed review model delivered (MOD-007):** portable `blacksmith_review_bundle.zip` in the
folder documented by `tools/makehuman/README.md`; 9,209 triangles, one atlas/material, ~1.22 MB
static FBX/GLB, four reviewed views, clean FBX reimport. Next big step in this chunk is a
rig/deformation + motion trial on this model (owner Mixamo actions/downloads under OWN-001), with
apron clearance, hand/joint preservation and full ≤3 MB animated budget checked before duplicating the cast.
Art refinement must address the README's explicit costume/face-detail deviations; no game hookup yet.
Start prompt: "Continue chunk MOD-003 from the clothed blacksmith draft: read the MakeHuman README
and reports, test rigging/deformation and task motions on this one character before expanding the cast."

**Real base now exists (MOD-006, 2026-11-01):** live export and Blender import passed. Output
folder and reports in `tools/makehuman/README.md`; clean clay preview reviewed. Next: chosen
face/weathering/hair/clothes, reduce the 28,796-triangle base plus garments to ≤ ~10,000, atlas,
rig/clips, then the full integration below. Preserve original body and exact requested sliders.
Import this FBX with `use_custom_normals=False`; default imported normals render badly.
Earlier preparation/installation notes below describe the state before this successful test.

**Installation ready (MOD-005, 2026-11-01):** open `/Users/rick/Applications/MakeHuman.app`.
Official source + CC0 system assets installed; private Python environment; scripting/FBX enabled and
startup verified. Reports 1.3.0 alpha. Follow `tools/makehuman/README.md` for the real export check;
no blacksmith FBX was generated during installation. No change to the full chunk's remaining scope.

**MakeHuman continuation (2026-11-01, D-041):** MOD-004 preparation is done. Next, run
`tools/makehuman/generate_blacksmith.py` in MakeHuman (instructions beside it), compare the FBX
height/textures in Blender with its report, and apply the chosen survivor look. Rig in Mixamo and
download the clips before the game integration below. Script syntax/mocked checks passed; no real
FBX was generated this session. Start prompt: "Continue the MakeHuman trial for chunk MOD-003:
read tools/makehuman/README.md and docs/plans/blacksmith-profile.md; verify one real FBX in
Blender before expanding to the full cast."

_The humans are split in two so each fits a fresh chat: **MOD-003** makes the people (models + animations), **RND-007** makes them live in the town. Full design for both: `docs/plans/town-life-plan.md`._
- **Why:** MOD-002 shipped only the zombie. Defenders are still labeled boxes and survivors are not drawn at all.
- **Work on its own git branch** (`chunk-3m-2-humans`), merged only when the owner approves.
- **Goal:** a defender and a varied cast of survivors exist as animated 3D humans the game can load, and defenders use theirs in play.
- **Needs:** MOD-002 (done). Owner downloads from Mixamo (FBX Binary, With Skin, 30 fps, In Place where offered) into `HighwayHoldout_3D_Sources/mixamo-humans/<artId>/` — exact list in the plan doc §3: 1 defender (rifle idle, rifle walk, rifle run, aim/fire, hit) and 4 survivor characters (each: idle, walk, run/panic, carry-walk, plus task clips hammer, dig/plant, pick up, talk). Files stay git-ignored (D-038).
- **Scope:** generalize `tools/blender/export_characters.py` to a character list (one config file in `tools/blender/`, not hard-coded per character) → `App/Models/unit_defender.usdz` and `civ_a…civ_d.usdz` + `.anim.json`; same scale/feet/front rules as the walker; survivor look variety = 4 models × tints in `presentation.json reality3d.characters.variants` (~8–12 looks); `DefenderLayer3D` plays walk when moving to a post, aim/fire when its tower/spot fires (RND-004 already draws defender tracers), idle otherwise; garrisoned defenders stand visible on their tower's platform if the RND-004 tower model has room (else stay hidden as today); file-size report (target ≤ 3 MB per character, 512 px textures).
- **Do NOT build:** walking townspeople / routines (RND-007); names, moods, needs or any new Core state; new gameplay; sounds.
- **Exit check:** in the simulator: defenders are animated humans (walk to a held spot, idle, aim and shoot during a horde), all survivor looks load in the RND-001 study scene / a DEBUG lineup, removing any human USDZ shows the labeled box; size table in `docs/features/characters-3d.md`; `cd Core && swift test` and the simulator build pass.
- **Start prompt:** "Implement ticket MOD-003: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/characters-3d.md, docs/plans/town-life-plan.md §1–3 and the MOD-003 section of docs/BUILD-QUEUE.md only. Work on branch chunk-3m-2-humans."

## RND-007 — Town life: survivors at work (Tropico feel) [Specced 2026-11-01, draft]
- **Goal:** the town feels alive like Tropico: you can see your survivors walk from home to their workplace, do the job (farm, haul scrap, hammer at the Workshop, build), carry goods to storage, chat when idle, leave on scavenging runs, and run for shelter when a horde is coming.
- **Needs:** MOD-003 (the human models). Same branch or a new one (`chunk-3m-3-town-life`), owner approves the merge.
- **Key rule:** **looks only.** Core stays the truth for *how many* people do what (`Roster` / `PopulationSnapshot`, per-building `assignedWorkers`, construction jobs, runs). The walking people are a picture of those numbers and never change game state, saves or results. Their planning (who goes where, which task, paths) is pure, seeded math in `Core/Sources/HoldoutCore/Presentation/` so it is unit-tested, like `CharacterMotion3D` (D-031).
- **Scope:** **first, the crowd budget (plan doc §7b):** a DEBUG crowd stress scene, 15-minute sustained runs on the minimum phone, and a table that sets how many survivors/zombies we can show (`docs/plans/crowd-budget.md`); skip if RND-005 already did it. Then plan doc §4–7: one visible person per survivor up to a cap; role from the roster; daily loop (home → work → task loop → carry to storage → break → back); per-building task table in JSON (builders at construction sites moved to chunk RND-008); run teams walk out to the map edge and come back with sacks; horde warning → everyone runs to HQ/Shelters and disappears inside, comes back out after "Held!"; tap a person → small label (role + workplace); performance caps and distance culling; all numbers in `Content/presentation.json → townLife`.
- **Do NOT build:** names/personalities/needs/happiness (Tropico's deeper sim — logged in `docs/IDEAS.md`), survivors being attacked by zombies, any Core rule or save change, new buildings or props beyond a few small task props (crate, sack, hoe) if missing.
- **Exit check:** in the simulator with a mid-game town: counts on screen match the HUD population (working/building/away/idle) within the visible cap; each workplace shows its workers doing that building's task; changing Workers −/+ sends someone walking there/away within a few seconds; a run team visibly leaves and returns; horde warning empties the streets, "Held!" refills them; no one walks through walls or buildings; crowd-budget table exists and the caps come from it; a 15-minute busy-town + horde run on the minimum phone holds 60 fps without passing "fair" heat; `cd Core && swift test` (new `TownLifePlannerTests`) and the simulator build pass.
- **Start prompt:** "Implement ticket RND-007: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/characters-3d.md, docs/features/jobs-defenders.md, docs/plans/town-life-plan.md and the RND-007 section of docs/BUILD-QUEUE.md only."

## OWN-001 — Owner downloads [Ready — you, not an agent]
- **Goal:** all the downloaded art the agents need is in `HighwayHoldout_3D_Sources/`, so no agent spends effort driving a browser.
- **Who:** the owner. No agent opens Chrome for downloads. Details, search terms, formats and folders: `docs/OWNER-DOWNLOADS.md`.
- **Parts:** A terrain textures (for TXT-001), B foliage/scatter models (for MOD-009), C Mixamo humans (for MOD-003), D optional task props (for RND-007). Parts are independent; do A first.
- **Agent's only job:** when told "OWN-001 part N done", check the files exist and are the right format, note licences in the folder's `NOTES.txt`, then say which chunk is unblocked.
- **Exit check:** every ticked part has its files in the listed folder; Mixamo and terrain files are git-ignored (`git status` doesn't list them).

## TXT-001 — Ground textures + map edge [Ready, partly done 2026-11-01]
- **Also done (D-044):** road centre lines and lane lines as tile textures (`tile_road_lane_ew`, `tile_road_center_ew/_ns`, generated placeholders), new tile slots for lots, gravel alleys, sidewalks and garden soil on the Chicago map.
- **Already done (D-043, owner request):** `presentation.json reality3d.groundTextures` (file, repeatTiles, tint per tile id), `App/Rendering/GroundTextures3D.swift`, UVs in tiles on the merged ground mesh, flat-colour fallback, 4 × 1024 px JPGs in `App/Textures/Ground/` (≈1.5 MB): grass_ground, muddy_tracks (dirt), cracked_concrete_02, concrete_rock_path (darkened, standing in for asphalt). Remaining scope below is unchanged except those parts.
- **Goal:** the ground looks like real grass, dirt, asphalt and concrete instead of flat colors, and the map no longer ends in a hard flat edge.
- **Needs:** RND-002 (done); OWN-001 part A (texture files).
- **Scope:** import the textures as small tileable 512 px (1024 px only for the main grass) USDZ-friendly images in `App/` (size budget: ≤ 4 MB total, note it); extend `GroundMesh3D` / `ModelRegistry.material` so each tile art id maps to a texture through `presentation.json reality3d` (texture name, tiling scale, tint); UVs from world position so tiles join without seams; soften the checker (D-016 style grid look) and add per-tile variation (seeded, look-only) so a field of grass isn't visibly tiled; blend where two tile types meet if cheap (else a 1-tile dark soft edge); the road gets its centre line from the `tile_asphalt_line` art id; map edge: a dressed border (dirt/grass strip, a few fences/barriers from existing models, fade to the outside colour) instead of a flat cut-off; missing texture falls back to today's flat color (never crash).
- **Do NOT build:** foliage or props (MOD-009), new tile types in Core, map layout changes, terrain height/hills, water.
- **Exit check:** simulator screenshots at two zoom levels and two camera angles beside today's flat ground; texture size table; 60 fps unchanged at a day-40 horde (simulator); removing a texture shows the flat colour; `cd Core && swift test` and the simulator build pass.
- **Model:** Sonnet is fine (material and UV work, JSON-driven), with the edge dressing reviewed by the owner.
- **Start prompt:** "Implement ticket TXT-001: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md, docs/OWNER-DOWNLOADS.md Part A and the TXT-001 section of docs/BUILD-QUEUE.md only."

## MOD-009 — Foliage and scatter [Specced 2026-11-01]
- **Goal:** the town sits in a believable overgrown landscape: live and dead trees, bushes, grass tufts, rocks and roadside junk placed around the map, with no gameplay effect.
- **Needs:** TXT-001; OWN-001 part B (models). Run after RND-005's fps readout exists, or add a quick readout first, because scatter is the likeliest thing to cost frame rate.
- **Scope:** extend `tools/blender/export_usdz.py` (recipes) to export the new models as `dec_*` / `fol_*` USDZ at game scale (512 px textures, ≤ ~2,000 triangles each, total new size ≤ 12 MB, record it); a scatter pass in the App (not Core) that places foliage from a seeded random generator and a density mask (none on building footprints, roads or the placement grid area; thicker toward the map edge); drawn as repeated instances of a few models (shared meshes), capped by a count in `presentation.json`; trees may be tall roofs for the placement fade rule (D-032) so they must not hide the ghost (fade or keep clear of the base area); decorations already in the map file (`dec_tree_dead`, car wreck, rubble) stay and are not duplicated; Battery saver (RND-005) can lower the count (leave a hook).
- **Do NOT build:** swaying/wind animation (later), destructible or harvestable trees, weather, seasons, new Core rules or saves.
- **Exit check:** screenshots at two angles with a mid-game town: foliage visible but never over placement ghosts, selected buildings or the tiles you tap; same layout after relaunch (seeded); fps table before/after (day-40 horde, simulator, plus the minimum phone if available, D-040); `check_models.py` reports all new art ids; `cd Core && swift test` and the simulator build pass.
- **Model:** Sonnet for the export recipes; Opus (or careful review) for the scatter/instancing and the frame-rate budget.
- **Start prompt:** "Implement ticket MOD-009: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md, docs/features/models-3d.md, docs/OWNER-DOWNLOADS.md Part B and the MOD-009 section of docs/BUILD-QUEUE.md only."

## Building overhaul (track H) and look quality (track Q) — owner request 2026-11-01, D-046
_Full design, numbers and the "why it looks flat" diagnosis: `docs/plans/buildings-and-look-plan.md`. Order: CORE-010 → APP-006; TXT-002 → TXT-003 → MOD-010 → RND-008; CORE-010 → CORE-011 → APP-007; MAP-001 last._

### CORE-010 — Core: smaller footprints, rotation, bigger compound, spot finder [Specced 2026-11-01 — Ready]
- **Goal:** buildings take the room they look like they need, and a new town has space to build.
- **Needs:** APP-002 (done). Takes the next free save version (see "Save versions" above).
- **Scope:** `buildings.json` footprints per plan §2 (Shelter, Scavenger, Workshop, Barracks, Storage → 2×1; HQ, Farm unchanged) and `rotatable`; `Building.facing` + `Command.placeBuilding`/`moveBuilding` take a facing; footprint turned by facing in `PlacementRules`, wall/path/occupancy checks; save migration (old 2×2 keeps its origin, shrinks to 2×1 facing south) + previous-version decode test; starting fence ring 13×9 in `startingLayout` with both maps' decorations moved so it fits (validator + `ChicagoMapTests` stay green; every spawn edge still reaches the HQ); `GameLoop.suggestSpot(defId:facing:near:)` = nearest valid origin (search radius in JSON); a short balance check that day 1–5 hordes still damage the fence (note in `balance.md`).
- **Do NOT build:** a finer grid (logged as not chosen in plan §2), App buttons (APP-006), new models (MOD-010), clearing decorations.
- **Exit check:** tests for rotated footprints, migration, `suggestSpot`, compound layout; `cd Core && swift test` passes; GAME-RULES footprint lines updated.
- **Start prompt:** "Implement ticket CORE-010: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/construction.md, docs/plans/buildings-and-look-plan.md §1–2 and the CORE-010 section of docs/BUILD-QUEUE.md only."

### APP-006 — App: easier placing [Specced 2026-11-01 — blocked by CORE-010]
- **Goal:** picking a building and putting it down takes one or two touches.
- **Needs:** CORE-010.
- **Scope:** ghost opens at `suggestSpot` near the screen centre (bar says "No room — expand your fence" if none); **Rotate** button in the placement bar for rotatable buildings (also in Move); ghost/footprint/outline/pick boxes drawn turned; interim `presentation.json reality3d.fitToFootprint` (margin in tiles) scales today's models to fill their footprint; placement grid shows free spots that fit the chosen building in light green.
- **Do NOT build:** new models (MOD-010), Core rule changes, drag-to-rotate gestures.
- **Exit check:** in the simulator: place each building type in the starting compound in ≤ 2 touches + Confirm, rotate a Storage, move a Shelter and rotate it; screenshots before/after in `docs/plans/`; Core tests and simulator build pass.
- **Start prompt:** "Implement ticket APP-006: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/input.md, docs/plans/buildings-and-look-plan.md §2 and the APP-006 section of docs/BUILD-QUEUE.md only."

### TXT-002 — Lighting & materials spike [Specced 2026-11-01 — blocked by owner downloads Part E]
- **Goal:** prove what makes the map stop looking flat on a phone, with numbers, before re-texturing everything.
- **Needs:** `OWNER-DOWNLOADS.md` Part E (at least the HDRI and three texture sets: asphalt, red brick, sidewalk).
- **Scope:** HDRI sky lighting (`ImageBasedLightComponent` + receivers on ground, buildings, characters; file + intensity in `presentation.json reality3d.light`); ground tiles with normal + roughness maps; one neighborhood house re-textured with colour + normal + roughness + baked AO as a test; `GroundingShadowComponent` (check iOS 18 availability); check what post effects RealityKit allows with the virtual camera (tone/fog) and report, don't build; before/after screenshots at the same camera spot; fps (day-40 horde, simulator) and app-size table. Update D-037 (texture budget) with the result.
- **Do NOT build:** the trim sheet or new models (TXT-003/MOD-010), map changes, foliage.
- **Exit check:** side-by-side screenshots the owner approves; fps ≥ 55 at day 40 (simulator) or a clear cost table; missing HDRI/texture falls back to today's look; Core tests and simulator build pass.
- **Start prompt:** "Implement ticket TXT-002: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md, docs/plans/buildings-and-look-plan.md §5 and the TXT-002 section of docs/BUILD-QUEUE.md only."

### TXT-003 — Chicago trim sheet + neighborhood dressing [Specced 2026-11-01 — blocked by TXT-002]
- **Goal:** the neighborhood houses look like real Chicago two-flats and greystones, and streets have curbs, porches, poles and grime.
- **Needs:** TXT-002 (its approved material settings).
- **Scope:** one 2048 px trim sheet (colour/normal/roughness/AO) built in Blender from Part E textures (`tools/blender/make_trim_sheet.py`); re-texture the 15 `dec_bld_*`/garage models onto it with cornices, limestone lintels, back porches, gangways; new `dec_` props: wooden power pole + wires (alley), curb pieces, crosswalk, manhole, chain-link gate; decal meshes (oil stains, cracks, puddles, leaves) placed look-only; baked AO on every model; size table (target: all neighborhood models + trim sheet ≤ the size they use today).
- **Do NOT build:** player buildings (MOD-010), trees (MOD-009), the new map (MAP-001).
- **Exit check:** review sheets per model; in-game screenshots at two angles; size + fps table; `check_models.py` passes; Core tests and simulator build pass.
- **Start prompt:** "Implement ticket TXT-003: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/models-3d.md, docs/features/map-chicago.md, docs/plans/buildings-and-look-plan.md §5 and the TXT-003 section of docs/BUILD-QUEUE.md only."

### MOD-010 — Player buildings in the Chicago style [Specced 2026-11-01 — blocked by CORE-010, TXT-003]
- **Goal:** every player building looks like a fortified, taken-over Chicago structure, changes look with each level, and fills its footprint.
- **Needs:** CORE-010 (final footprints), TXT-003 (trim sheet).
- **Scope:** recipes for all 7 buildings at the CORE-010 footprints, front facing south; L1/L2/L3 looks (art id per level in `buildings.json`, Core decode + content test); construction stages `_stage1…3` per building; rubble for 2×1, 2×2, 3×3; ≤ 3,000 triangles each; baked AO; **do HQ + Shelter first and stop for the owner's style OK**; remove `fitToFootprint` scaling for buildings that now fit.
- **Do NOT build:** builder animations (RND-008), new building types, defenses (later chunk if the owner wants).
- **Exit check:** review sheets next to a neighborhood house; in-game screenshot of a mid-game town with every building at L1 and one at L3; size table; missing model → labeled box; Core tests and simulator build pass.
- **Start prompt:** "Implement ticket MOD-010: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/models-3d.md, docs/plans/buildings-and-look-plan.md §4 and the MOD-010 section of docs/BUILD-QUEUE.md only. Do HQ and Shelter first and show them to me."

### RND-008 — Builders at work (Tropico-style construction) [Specced 2026-11-01 — blocked by MOD-010, APP-006, clips]
- **Goal:** you watch survivors walk to a site, carry materials, hammer, and the building rise in stages.
- **Needs:** MOD-010 (stage models), APP-006; hammer + carry clips on the farmer (`OWNER-DOWNLOADS.md` Part C). Can run before RND-007; RND-007 no longer covers builders.
- **Scope:** plan §3: stage by job progress (thresholds in `presentation.json townLife.construction`); per running job `buildersPerJob` humans walk from HQ/Storage, first trip carrying a plank/sack, then loop hammer/saw/carry at work spots around the footprint; repairs, rebuilds and upgrades (scaffold around the old model) the same way; "waiting for builder" icon on queued jobs; dust puff on finish; builders run inside on horde warning; planner in `Core/Sources/HoldoutCore/Presentation/` with tests; look only, no Core rule or save change.
- **Do NOT build:** names/needs, builder speed affecting build time, new props beyond plank/sack/hammer.
- **Exit check:** in the simulator: place a Shelter, see the builder walk there and hammer, the model goes through all stages, builder walks back; two jobs at once show two builders; horde warning sends them in; Core tests (new planner tests) and simulator build pass.
- **Start prompt:** "Implement ticket RND-008: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/characters-3d.md, docs/features/construction.md, docs/plans/buildings-and-look-plan.md §3 and the RND-008 section of docs/BUILD-QUEUE.md only."

### MAP-001 — Roscoe Village map [Specced 2026-11-01 — blocked by TXT-003, CORE-010, MOD-009]
- **Goal:** new games start in a neighborhood that looks like Roscoe Village (owner's screenshot): two-flats and greystones on narrow lots under big parkway trees, an alley with garages, a shop street, a brick loft landmark, the Metra embankment as the east edge.
- **Needs:** TXT-003 (houses/porches/poles), CORE-010 (compound size), MOD-009 (live trees).
- **Scope:** plan §6: `Content/maps/phase1_roscoe.json` (~64×48 tiles, numbers in the JSON) as the new-game map (old saves keep theirs); Wolcott/Newport/alley/Roscoe layout, loft building model, embankment edge (blocks zombies); spawn edges + `hordes.json` checked for the longer walks; camera zoom-out limit for the bigger map; `RoscoeMapTests` (starts, every spawn edge reaches the HQ, zombies break in); generic business names, no logos.
- **Do NOT build:** more maps, map choice screen, real street-name signs unless the owner asks.
- **Exit check:** overview + street-level screenshots next to the owner's map screenshot; day-1–10 hordes still reach the fence in a sensible time (balance note); fps at day 40; Core tests and simulator build pass.
- **Start prompt:** "Implement ticket MAP-001: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/map-chicago.md, docs/plans/buildings-and-look-plan.md §6 and the MAP-001 section of docs/BUILD-QUEUE.md only."

### CORE-011 — Core: take over neighborhood houses [Specced 2026-11-01 — blocked by CORE-010]
- **Goal:** survivors can claim a house, garage or shop already on the map and turn it into one of their buildings, so the town grows into the neighborhood instead of only onto empty lots.
- **Needs:** CORE-010 (rotation/footprint code it builds on). Takes the next free save version.
- **Scope:** plan §8: `claimable` + allowed uses per decoration in the map JSON (Chicago map houses, garages, storefronts, taverns); `buildings.json rules.claim` (`costPct` 60, `buildSecondsPct` 75, `hpMultiplier` 1.5, `maxDistanceTiles`, `housingPerTile`, storage per tile — first guesses); `Command.claim(decoration:as:)` → normal build job (slot, builder, pay on start) with problems (notClaimable, useNotAllowed, tooFar, queue/cost/HQ-level like placement); the building takes the house's footprint and remembers `claimedFrom`; the map stops counting the claimed decoration as a blocker; HP/housing/storage scale as above; demolish → cleared buildable lot; rubble rebuild as normal; pathing treats claimed houses as attackable buildings; save + migration + previous-version decode test; validator checks claimable uses are real building ids.
- **Do NOT build:** App buttons or art (APP-007), searching houses for loot, claiming defenses, interiors.
- **Exit check:** tests: claim a garage as Workshop (cost, time, footprint, HP), refused when too far / wrong use / queue full, zombies attack a claimed house and it becomes rubble, demolish leaves a buildable lot, save round-trip + migration; `ChicagoMapTests` still green; `cd Core && swift test` passes; GAME-RULES §5 updated.
- **Start prompt:** "Implement ticket CORE-011: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/construction.md, docs/features/map-chicago.md, docs/plans/buildings-and-look-plan.md §8 and the CORE-011 section of docs/BUILD-QUEUE.md only."

### APP-007 — App + art: "Take over" button and fortified house looks [Specced 2026-11-01 — blocked by CORE-011, APP-006, MOD-010]
- **Goal:** tapping a house shows what it could become; taking it over is two taps, and the house visibly turns into a fortified survivor building.
- **Needs:** CORE-011 (Core), APP-006 (placement UI it reuses), MOD-010 (the fortified dressing style).
- **Scope:** tap a claimable house → outline + small panel ("Two-flat — take over as: Shelter / Barracks", cost, time, or why not: too far / need HQ level); claimed house draws its own model plus a fortified dressing layer (boarded windows, sandbags, tarp, string lights) per use and level — dressing recipes in `tools/blender/` reusing MOD-010 pieces; construction shown with scaffold on the house (RND-008's builders apply if done); claimable houses near your town get a faint marker so players notice the option; DEBUG lineup of every claimable house × use.
- **Do NOT build:** new Core rules, new house models (TXT-003 owns the houses), interiors.
- **Exit check:** in the simulator: take over a garage next to the fence as a Workshop, watch it build, see the fortified look, demolish it to a lot; a far house says "too far"; screenshots in `docs/plans/`; Core tests and simulator build pass.
- **Start prompt:** "Implement ticket APP-007: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/input.md, docs/features/models-3d.md, docs/plans/buildings-and-look-plan.md §8 and the APP-007 section of docs/BUILD-QUEUE.md only."

## MVP tickets (owner goal 2026-11-01) — see "MVP path" at the top

### CORE-012 — Core: town ledger [Specced 2026-11-01 — MVP #8]
- **Goal:** Core can answer "where does each supply come from and go to?", "who lives here and what are they doing?" and "what just happened?", so the App can draw a living town without doing any game math.
- **Needs:** CORE-005, CORE-008 (water, bullets and guns must exist to be in the ledger). Takes the next free save version if the log is saved.
- **Scope (Core only):** a read-only `TownLedger` snapshot: for every resource, amount / cap, made per minute and used per minute broken down by source (each building type, upkeep, Ammo Bench, repairs, runs), and minutes until empty or full; a survivor roster (name, job or building, defender/builder/idle, hungry/thirsty, knocked out timer) — add seeded first names from a new `Content/names.json` if survivors have none; a capped town event log (`log.maxEntries` in JSON) of plain events: building finished/upgraded, survivor arrived/left, run returned with loot, horde held/broke through, shortage started/ended, research done. Game-time stamps only (no wall clock). Save migration if the log is saved.
- **Do NOT build:** UI (APP-008), new rules, notifications.
- **Exit check:** `swift test` passes with tests for: rates match what actually happens over 60 ticked seconds, minutes-until-empty, roster counts match jobs, each event type logs once, the log cap, same seed = same names, migration.
- **Start prompt:** "Implement ticket CORE-012: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/core-api.md, docs/GAME-RULES.md §4 and §7, and the CORE-012 section of docs/BUILD-QUEUE.md only."

### APP-008 — App: Supplies and Town screens [Specced 2026-11-01 — MVP #9]
- **Goal:** one tap from the HUD opens a screen that shows the whole town's supplies and people, so the place feels alive and the player knows what to build next.
- **Needs:** CORE-012, APP-004, APP-005.
- **Scope (App only, using the delivered UI kit in `HighwayHoldout_UI_Kit/` — see `docs/reviews/2026-10-31-art-and-build-review.md` item 2):** a **Supplies** tab (every resource: amount / cap bar, + and − per minute, tap for the breakdown by source, "runs out in 12 min" warning in red, empty/locked rows for things not built yet); a **People** tab (roster from the ledger: name, job, status; tap to jump the camera to their building); a **Log** tab (latest events, newest first); a HUD button to open it and tapping a HUD resource opens its Supplies row. Pausing the game while it is open follows the existing speed buttons (pause if the speed buttons allow it).
- **Do NOT build:** Core math (read only from the ledger), new art beyond the UI kit, settings screen (APP-003), portraits.
- **Exit check:** in the simulator: open Supplies on a running town, the numbers match the HUD and change as buildings work; the breakdown shows the Garden and Well; a shortage shows the red "runs out" line; People lists every survivor with the right job; the Log shows a finished building and a held horde; Core tests and simulator build pass.
- **Start prompt:** "Implement ticket APP-008: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/hud-ui.md, docs/reviews/2026-10-31-art-and-build-review.md, and the APP-008 section of docs/BUILD-QUEUE.md only."

### REL-002 — MVP playtest [Specced 2026-11-01 — MVP #10, last]
- **Goal:** the owner can sit down and play the MVP for real, with nothing blocking the first hour.
- **Needs:** APP-008 (and so everything in the MVP path).
- **Scope:** an agent plays a fresh town in the simulator for ~45 game-minutes, using every MVP feature (build, rotate, garden/well, guns/bullets/Ammo Bench, traps, Supplies screen); fixes only blockers (crashes, stuck states, buttons that do nothing) with tests where Core is involved; tunes obvious numbers in `Content/*.json` (town starves in 5 minutes, first horde unbeatable, nothing to do for 10 minutes) and records them in `docs/features/balance.md`; writes `docs/MVP-PLAY-GUIDE.md` (one page: how to start, what to try, what is placeholder, known issues, what feedback is useful).
- **Do NOT build:** new features, art, anything parked in the MVP path.
- **Exit check:** the playtest notes and play guide exist; Core tests and simulator build pass; STATUS says "MVP ready to play".
- **Start prompt:** "Start ticket REL-002: read AGENTS.md, docs/STATUS.md, docs/features/balance.md, and the REL-002 section of docs/BUILD-QUEUE.md only."

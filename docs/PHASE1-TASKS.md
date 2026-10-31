# Phase 1 — Task Plan for What's Left (1V → 1E)

_Status: **1V done** (2026-10-31). Next: 1B. Written 2026-10-31 after 1A passed its exit check._
_Milestone goals and exit checks come from `docs/PHASE1-PLAN.md`; this file breaks them into tasks an agent can run in order._
_Every task follows AGENTS.md: Core logic gets Swift Testing tests, numbers go in `Content/*.json`, and the feature note, MAP, and STATUS are updated._

## Approved update — isometric placement first (2026-10-31, D-022)

**Owner approved; implementation pending.** This supersedes the earlier requirement to switch automatically to top-down for building. Codex has documented the direction first so Claude can coordinate implementation; this update changes no app code or preferences.

**Goal:** stay in the attractive isometric world while placing and moving buildings. Retain the existing top-down view and manual toggle as a testing fallback until placement feels good on an iPhone. Do not delete its renderer/assets yet or spend time producing a matching top-down art pack for this change.

**Implementation order:**
1. Keep the current behavior working while improving isometric placement. Show a clear ground grid during placement/movement and a distinct footprint outline with valid/invalid feedback and a readable reason when blocked.
2. Support accurate tile-snapped ghost dragging with explicit Confirm/Cancel. Preserve camera pan/pinch, Core placement validation, move/cancel semantics, and repeated 1×1 defense placement. Reuse existing ghost/input behavior where it already works.
3. Temporarily fade buildings that obscure the placement footprint or ghost, so tiles behind tall structures such as HQ remain usable. Restore opacity on movement, Confirm, Cancel and leaving placement. Fading is presentation-only and must not affect collision or simulation.
4. After the checks below pass, disable the automatic top-down switch for normal placement/movement. Review both the presentation default and persisted view preferences so existing installs do not silently retain the old auto-switch behavior. Keep the manual top-down fallback available during testing; removal is a later decision.

**Acceptance checks:** on an iPhone-sized landscape screen, place and move 1×1, 2×2 and 3×3 footprints in open ground, behind HQ, beside walls and at map edges. Confirm invalid spots/costs remain blocked with clear feedback; Cancel makes no change; camera gestures and repeated wall placement still work; occluding buildings restore correctly; and Confirm/Cancel cause no automatic camera-view flip after rollout. Check fresh and existing preferences, manual top-down fallback, and app relaunch. Capture screenshots of the grid, a valid/invalid ghost and placement behind a faded building. Run the app build and relevant tests; add regression tests for changed logic per AGENTS.md.

**Coordination:** finish outstanding 1B defense exit checks before declaring 1B complete. This is an explicitly approved placement improvement, not a new gameplay milestone. Claude should read this section before changing view/placement code and record implementation status in STATUS and input.md. The historical 1V checklist below records what was previously built; its auto-flip behavior is superseded by this update.

## Order
| # | Milestone | What the owner gets | Size |
|---|---|---|---|
| **1V** | **Two views** (new) | The town is shown in full Tropico-style isometric; it flips to a flat top-down grid while you place or move something, then flips back. | 1–2 sessions |
| 1B | Defense | Hordes attack, walls get bashed, towers shoot, and HQ falls are a setback. | 2 sessions (Core, then App) |
| 1C | Depth | Upgrades, build queue + builders, jobs, defenders, scavenging runs, speed buttons, research. | 2 sessions |
| 1D | Time & alerts | Offline catch-up, a "welcome back" summary, Horde Alert notifications, a frozen bonus horde. | 1 session |
| 1E | Art swap & playtest | Final art style dropped in, balance pass, TestFlight. | Owner-led |

**Why 1V comes first:** 1B adds zombies, turrets, bullets, and health bars, which is most of the drawing code. Built top-down only, it would all be rewritten for isometric. Making the drawing code view-independent now costs about one session and saves rewriting 1B–1D. The simulation (`Core/`) doesn't change: the game is still a square grid underneath, and only the drawing changes.

---

## Owner decisions
**Earlier decision (superseded for placement by D-022 above):** two views only. **Isometric ("full Tropico style")** is the normal view. **Top-down** is the building view, for easy placement on a clear grid. The in-between "3/4 top-down" option is dropped.

Still open (agent's recommendation first):
1. **Automatic top-down placement:** superseded by D-022. Improve and verify isometric placement first, then disable auto-flip; retain manual top-down for testing.
2. **Facings for moving things in isometric:** 4 diagonal facings (draw 2, mirror 2) for survivors/zombies/defenders, and 8 for turret guns (draw 5, mirror 3). *Recommended.* In top-down they keep one image rotated by code.
3. **Art import:** no trimming for isometric art (it depends on exact ground points). *Recommended.*
4. **Art for each view:** the top-down view keeps using today's top-down pack (`HighwayHoldoutAssets/`). The isometric view needs its own pack, likely from the new Blender study (`HighwayHoldout_Blender_Study/`, whose samples are still overhead and must be re-rendered from the isometric camera in `docs/graphics-spec-iso.md`). Until then the isometric view uses labeled 3D placeholder blocks. *Recommended.*
5. **Stop between milestones?** *Recommended:* stop after each exit check so you can play it for 5 minutes.

Open balance questions already in STATUS (food upkeep, permanent death, Horde Alert default) don't block anything until 1E.

---

## 1V — Two views ("Tropico to look at, top-down to build") — DONE 2026-10-31

**Goal:** the renderer draws the same town in **isometric** (normal view) or **top-down** (building view). It switches automatically while placing/moving, and by a HUD button. Each view has its own art pack, and missing art is a labeled block (3D-looking in isometric, flat in top-down), so isometric works before its art exists.

### Data
- **New `Content/presentation.json`** (decoded by Core as plain data so `ContentFilesTests` covers it; Core never uses it):
  - `views.isometric` and `views.topDown`, each with:
    - `projection`.
    - `tileWidthPt` / `tileHeightPt`: isometric 64×32, top-down 32×32.
    - `artNamespace`: `Iso` / `TopDown`.
    - `facings`: iso 4 (turrets 8); top-down 1 = rotate in code.
    - `placeholderHeightTiles` per category (hq, housing, production, wall, tower, trap, unit, zombie, decoration; top-down ignores it).
    - `assets.<artId>` optional overrides: `anchor` [x, y] (the ground point inside the image, 0–1), `heightTiles`, `mirrorable`.
  - `defaultView`: `isometric`. `autoTopDownWhilePlacing`: true. `switchFadeSeconds`: 0.3.
  - `camera`: `minScale`, `startScale` per view (moved out of `CameraController.swift`).
- The player's last chosen view and the auto-flip setting are stored in UserDefaults (presentation, not game state).

### Code (App unless marked)
| Task | Files | Notes |
|---|---|---|
| V1 Projection math | **Core** `Presentation/GridProjection.swift` + tests | Pure `Double` math, so it tests on Linux. Tile↔screen, footprint outline polygon, depth key, map bounds, for both views. Isometric: `sx = (x−y)·w/2`, `sy = −(x+y)·h/2`; inverse `x = (a+b)/2`, `y = (b−a)/2`. Tests: round-trip every tile, corners, depth order. Decision entry: why this lives in Core. |
| V2 Art per view | `App/Rendering/ArtStyle.swift` (new), `ArtRegistry.swift` | Lookup `Iso/bld_farm` or `TopDown/bld_farm`; per-asset anchors and heights. Missing art falls back to that view's placeholder, never to the other view's image. |
| V3 Replace `GridGeometry` | `GridGeometry.swift` → wraps the active `GridProjection` | Every factory asks the projection for positions; nothing assumes top-down. |
| V4 Depth sorting | `Rendering/DepthSort.swift` (new), `ZLayer` | `zPosition = layer + depth`. Buildings use their footprint's front-most corner; moving things use their position. Ground, ground-traps, and goo stay flat. Top-down keeps today's fixed layers. |
| V5 Anchors + tall sprites | Building/Terrain/Ghost factories | Isometric sprites stand on their footprint's ground point and rise above it. Progress/health bars and badges go above the sprite's top. |
| V6 Placeholder blocks | `Rendering/PlaceholderArt.swift` (split out of `ArtRegistry`) | Isometric: top diamond + two shaded sides, height from JSON, label on the front. Diamond ground tiles. Top-down: today's flat labeled boxes. |
| V7 Overlays | `GhostNodeFactory.swift` | Footprint tiles as projected polygons (diamonds in iso). Selection outline = footprint polygon. Range rings ready for 1B (ellipses in iso). |
| V8 Touch picking | `GameScene.swift`, `Input/HitTesting.swift` (new) | In iso, a tap hits the front-most building sprite first (tapping a tall roof works), then the ground tile. Placement always happens in top-down when auto-flip is on, so dragging the ghost stays easy. |
| V9 View switching | `Rendering/ViewSwitcher.swift` (new), `GameScene`, `PlacementController` | Rebuilds the world layer in the other projection, cross-fades over `switchFadeSeconds`, and keeps the same world point centered at a matching zoom. Auto: entering placing/moving → top-down; Confirm/Cancel → back to the view you were in. HUD toggle button (icon from the art pack). |
| V10 Camera | `CameraController.swift` | Bounds from the projected map box (the area outside the diamond is filled with a wasteland color). Feel numbers come from JSON, per view. |
| V11 Facing helper | `Rendering/DirectionalSprite.swift` (new) | Top-down: rotate the one image. Iso: pick `id_se`, `id_ne`, … by world angle, mirroring where allowed; a missing frame falls back to the base image. Used from 1B on. |
| V12 Art import | `tools/import_art.py` | `--view iso|topdown` writes to `Art/Iso/` or `Art/TopDown/` (Xcode "provides namespace"). No trimming for iso. Today's art moves to `Art/TopDown/`. |
| V13 Iso art spec | `docs/graphics-spec-iso.md` (new) | For ChatGPT/Blender: true 2:1 isometric camera (Blender: orthographic, 60° tilt, 45° turn); master tile 256×128 diamond; building canvas width = footprint diamond width (2×2 = 512 px), free height; anchor = bottom point of the footprint diamond; light from top-left; facing names (`zmb_walker_se.png` …); a template grid image to draw on. Same filenames as the top-down pack, so the two packs match one-to-one. |

**Tests:** projection round-trips and depth order (Core). The content test decodes `presentation.json`. App: build, then visual checks.

**Exit check (screenshots):** the game opens in isometric showing the starting town (blocks or art). Tap Build → it flips to top-down with the ghost; place → it flips back and the building appears in iso. Move and demolish work. Tapping a roof selects the building. Buildings behind others are drawn behind. The HUD button flips views by hand. The camera can't scroll off the map in either view.

---

## 1B — Defense ("watch it hold")

### Core (session 1)
| Task | Files | Rules / data |
|---|---|---|
| B1 Model + save v2 | `Model/Zombie.swift`, `Model/HordeState.swift`, `Save/SaveMigrations.swift` | Zombie: id, defId, position (Double tiles), hp, slow. HordeState: day, seconds to next horde, active horde (spawn queue, edges, killed), warning flag. Building gets `isRubble`. Migration v1→v2 + a test that decodes a v1 sample. |
| B2 Horde clock | `Systems/Hordes/HordeClock.swift` | `hordes.json schedule`: first/interval/warning; runs only in ticks (app open); frozen during a horde. Survivor arrival pauses during a horde (already in data). |
| B3 Horde budget + mix | `Systems/Hordes/HordeComposer.swift` | budget = (baseBudget + budgetPerDay·day) × min(1 + townValue/divisor, townFactorMax); townValue = invested in standing buildings (D-009). Day-range composition, guaranteed units, weighted picks by `threatCost` with `SeededRandom`, `edgeCount` edges. |
| B4 Flow field | `Systems/Pathing/FlowField.swift` | Dijkstra from HQ tiles. Cost: open 1; wall/building = open + hp·costPerHp (`pathing`), scaled by each zombie's `pathCostWeight` (one field per distinct weight). Rebuilt only when buildings change. Highway tiles are walkable. |
| B5 Movement + bashing | `Systems/Combat/ZombieMovement.swift`, `WallBashing.swift` | Move downhill at `speed`; when blocked, attack that tile's building (`damageVsBuildingsPerSec`, × `wallBashMultiplier` on walls). Barbed wire `slowPct`; spikes `dps` + `durabilityLossPerZombieSecond`. |
| B6 Towers | `Systems/Combat/TargetingSystem.swift`, `TowerFiring.swift` | Fire only when staffed; `fireRate`, `range`, `damage`. `single_nearest_to_hq` = lowest flow distance in range; `single_nearest` = closest. Hitscan; emit events. |
| B7 Deaths, loot, horde end | `Systems/Hordes/HordeResolution.swift` | Loot to stock (capped). The horde ends when everything is spawned and dead → `completionBonus`, day + 1. |
| B8 HQ falls | `Systems/Hordes/HordeOutcome.swift` | `economy.json hqFall`: the horde ends, food/scrap lose the set %, HQ restored to its set % HP, other 0-HP buildings → rubble. |
| B9 Repair | `Command.repair(id)`, `ConstructionSystem` | Repair damaged buildings and rebuild rubble using `rules.repair` / `rules.rubble` cost + time (no builder limit until 1C). |
| B10 Events for drawing | `Simulation/SimEvent.swift` | Per-tick list (not saved): shot(from, to), hit, zombieDied(at), buildingDamaged/destroyed, hordeWarning(edges), hordeStarted/ended(result). |
| B11 Debug commands | `Command.debug…` (DEBUG builds only) | "Horde now", "Add resources", "Kill all" for testing. |

**Tests:** the flow field picks the weakest wall; horde budget + mix are deterministic per seed; targeting order; slow/spikes; HQ-fall setback; v1→v2 save migration; same seed + commands → same result.

### App (session 2)
| Task | Files |
|---|---|
| Zombies: directional sprite, walk bob, health bar when hurt, hit flash | `Rendering/Nodes/ZombieNodeFactory.swift` |
| Defenses: base + gun top (rotate in top-down, facing frames in isometric), staffed/unstaffed look, range ring on select | `Rendering/Nodes/DefenseNodeFactory.swift` |
| Effects from `SimEvent`s: tracer, muzzle flash, goo splat, dust puff, building damage shake | `Rendering/Nodes/FXNodeFactory.swift`, `GameScene` event drain |
| Horde HUD: "Day N · next horde 3:12", warning arrows at spawn edges, start/end banner (held / HQ fell −X) | `UI/HordeBannerView.swift`, `HUDView.swift` |
| Build menu tabs (Buildings / Defenses); stay in placement mode after placing 1×1 defenses so walls are quick | `BuildMenuView.swift`, `PlacementController.swift` |
| Building panel: HP bar, Repair / Rebuild with cost | `PlacementBarView.swift` |
| Rubble drawing | `BuildingNodeFactory.swift` |
| Debug menu (DEBUG only) | `UI/DebugMenuView.swift` |

**Exit check:** trigger a horde. Zombies come from the warned edge, pile up at the weakest wall, and break through or not. Towers shoot, goo flies, the HQ-fall setback works, and you can repair afterward. Works in both views. Also smooth (≈60 fps) with ~150 zombies on iPhone 15-class hardware.

---

## 1C — Depth ("a 30-minute session feels like progress")

### Core
| Task | Rules / data |
|---|---|
| C1 Upgrades | `Command.upgrade(id)`: next level's cost, `requiredHq`, `buildSeconds`; the building keeps working during the upgrade, except HQ effects apply when done. |
| C2 Build queue + builders | `rules.constructionSlotsByHq`, `constructionQueueLength`, `buildersPerJob` borrowed from idle survivors. Cost is paid when a job starts, and queued jobs auto-start. Replaces the 1A timer-only build (D-012), with a save migration. |
| C3 Jobs | Manual worker assignment per building (`Command.setWorkers(id, n)`), replacing auto-staffing (D-011). New buildings auto-fill from idle survivors, so it still "just works". |
| C4 Defenders | Barracks training (`units.json training`, queue length, `maxDefenders`), consumes a survivor. Garrison a tower (`garrison`, counts as worker, damage ×). Hold a spot: defenders shoot zombies in range; at 0 HP they're knocked out for `knockedOutSeconds`, never dead. |
| C5 Scavenging runs | One per post; survivors away for `durationSeconds`; rewards wait at the post; collect clamps to caps. |
| C6 Research stub | Workshop L1; 1 at a time; stored on `Group` (carries to future bases); effects: unlock metal wall, tower range +1, farm ×1.25. |
| C7 Save v3 | Migration + tests for every rule above. |

### App
Upgrade button (cost, level badge from `ui_level_badge` + tint); build-queue strip; worker −/+ on the building panel; Barracks panel (train queue); assign a defender to a tower; defender units (directional) with a hold-spot command; Scavenger Post panel (start run, timer, collect); pause/1x/2x in HUD; Workshop research panel; cosmetic survivors walking between HQ and workplaces (optional, cheap if time allows).

**Exit check:** a 30-minute session from a fresh start reaches HQ level 2–3 and faces brutes.

---

## 1D — Time & alerts ("come back to something")

### Core
| Task | Rules / data |
|---|---|
| D1 Offline catch-up | `OfflineCatchUp.run(state, awaySeconds)`: the App passes the wall-clock difference (Core still reads no clock). Capped at `maxOfflineCreditHours`; steps of `catchUpStepSeconds`; economy, construction, upgrade, repair, training, research, runs; **no combat, the horde clock doesn't move**. Returns a summary (resource deltas, things finished). |
| D2 Tamper guard | Negative time → nothing (`clockBackwardsGrantsNothing`); forward jumps capped. |
| D3 Bonus horde | `Command.spawnBonusHorde` when an alert fired while away; waits frozen at an edge (`maxWaiting`, `waitsIndefinitely`); `Command.engageBonusHorde`; size × / loot × from `bonusHorde`. |
| D4 Settings in save | Time factor (default OFF), Horde Alerts (default from `offline.json`), stored in `GameState` so catch-up is deterministic. Save v4. |

**Tests:** cap; no combat while away; tamper; catch-up = the same as ticking live with no hordes; the bonus horde never moves on its own.

### App
- `SettingsView`: Time factor, Horde Alerts, View style.
- `WelcomeBackView`: shown if away ≥ `welcomeBackMinAwaySeconds`.
- `NotificationScheduler`: on background, at most one alert in the random window, honoring `quietHours` and `minAwayMinutes`. Notification permission is asked only when the toggle is first turned on.
- `AppLifecycle`: saves the wall-clock time and, on launch, runs catch-up + checks whether the alert fired.
- Engage button on the HUD while a bonus horde waits.
- DEBUG "pretend I was away N hours".

**Exit check:** queue work, close the app for 4 hours (or the debug equivalent), reopen. The summary feels good, and ignoring the alert costs nothing.

---

## 1E — Art swap & playtest (owner-led)
- Isometric art delivered per `docs/graphics-spec-iso.md` → `python3 tools/import_art.py <folder> --view iso`; top-down pack refreshed with `--view topdown` if its style changed. The agent fixes anchors and heights in `presentation.json` from screenshots (no code changes).
- Balance pass with `docs/features/balance.md` knobs; answer the STATUS balance questions.
- Sound hooks (placeholders), app icon check.
- TestFlight: needs the owner's Apple Developer account + signing team in Xcode (the owner does the signing step; the agent prepares the archive command and checklist).
- **Exit check:** the Phase 1 "done when" line in PHASE1-PLAN.md.

---

## Risks and how the plan handles them
- **Art doubles:** every building needs a top-down and an isometric image. Top-down is already done, and isometric can come from the Blender study renders; the matching filenames keep this mechanical.
- **Isometric draw-order glitches** with big footprints next to moving zombies: sort by the footprint's front corner; footprints are ≤3×3 and never overlap. If a zombie walks "behind" a tall HQ it could be hidden → planned fix: fade a building that covers a selected or moving unit (1B App, small).
- **ChatGPT consistency at exact iso angles:** the spec gives a template diamond grid image to draw on; anchors are tunable in JSON per image, so off-by-a-bit art is fixable without code.
- **Performance:** about 1,200 ground tiles + 150 zombies is fine for SpriteKit; if not, pre-render the ground into a few large textures (planned fallback, not built up front).
- **Save compatibility:** every milestone bumps the save version with a migration + test, so your test town survives each update.
- **Scope creep:** anything not listed here goes to STATUS → Open questions, per AGENTS.md.

## How to start
Say "go" (and answer the decisions above, or accept the recommendations). The agent runs **1V** and shows screenshots of both views and the auto-flip, then stops. Then 1B, 1C, 1D, each ending with its exit check and screenshots.

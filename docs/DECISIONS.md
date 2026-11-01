# DECISIONS — why things are the way they are

_Append-only. Newest at the bottom. Add an entry for any non-obvious choice, so nobody "fixes" it later by accident. To reverse a decision, add a new entry that says which one it replaces; don't delete the old one._

**Format**
```
## D-NNN — Short title (YYYY-MM-DD) [Accepted | Proposed | Replaced by D-NNN]
**Decision:** one sentence.
**Why:** one or two sentences.
```

---

## D-001 — Swift 6 + SwiftUI + SpriteKit (2026-10-31) [Accepted]
**Decision:** Native Swift 6; SwiftUI for menus/HUD, SpriteKit (via `SpriteView`) for the game world, `@Observable` for state.
**Why:** All built into iOS, no engines or licenses, and best supported by AI coding agents. SpriteKit is plenty for a 2D top-down game with a few hundred sprites.

## D-002 — Simulation in its own package (Core/App split) (2026-10-31) [Accepted]
**Decision:** All game rules live in Swift package `HoldoutCore` with no SpriteKit/UIKit imports; the app only draws it and sends commands.
**Why:** Rules can be unit-tested in seconds without a simulator (even on Linux, e.g. Codex cloud), and agents can fix logic bugs without touching UI code.

## D-003 — Fixed-timestep, deterministic simulation (2026-10-31) [Accepted]
**Decision:** Core advances in fixed ticks (rate set in `Content/economy.json`) and uses only seeded random numbers.
**Why:** Same inputs give the same result every time, so bugs are reproducible in a test, and 2x speed / offline catch-up are just "run more ticks."

## D-004 — All tuning in Content/*.json (2026-10-31) [Accepted]
**Decision:** Costs, stats, timers, and caps live in JSON files loaded at runtime; none are hardcoded in Swift.
**Why:** Balance tweaks become one-line data edits the owner can make or review, with no risk of breaking code.

## D-005 — Saves are versioned JSON files, not SwiftData (2026-10-31) [Accepted]
**Decision:** The whole game state is encoded with `Codable` to one JSON file with a `version` number and explicit migrations.
**Why:** Simple, readable, diff-able, testable in Core, and works offline. SwiftData would tie the save format to Apple frameworks Core can't import and makes migrations harder to see.

## D-006 — Flow-field pathing toward the HQ (2026-10-31) [Accepted]
**Decision:** One shared cost grid toward the HQ; every zombie follows it. Walls are passable at high cost (zombies bash through).
**Why:** Cheap for hundreds of zombies (recomputed only when buildings change) and naturally makes zombies pile up at the weakest point, which is the core design hook.

## D-007 — No game over (2026-10-31) [Accepted]
**Decision:** If the HQ falls, the horde ends, the player loses a % of stored resources (in `Content/economy.json`), and destroyed buildings become repairable rubble.
**Why:** The game is meant to be relaxing to come back to; a setback keeps tension without wiping hours of progress.

## D-008 — Placeholder art by default (2026-10-31) [Accepted]
**Decision:** `ArtRegistry` draws a labeled colored shape when an image is missing; a correctly named PNG replaces it with no code change.
**Why:** The game is playable from day one, and art from ChatGPT can arrive in any order.

## D-009 — Horde size scales with built value, not stored resources (2026-10-31) [Proposed]
**Decision:** `townValue` for horde scaling = resources spent on standing buildings; stored food/scrap don't count, and the town factor is capped at 1.5x (`Content/hordes.json`).
**Why:** Hoarding shouldn't make hordes bigger, and the cap keeps growth from feeling punished. Offline rules got their own file (`Content/offline.json`) so time-factor tuning is in one place.

## D-010 — Core tests read the repo's Content/ folder (2026-10-31) [Accepted]
**Decision:** `ContentLoader.load(from:)` takes a folder URL; Core tests pass the repo's `Content/` (found from `#filePath`), and the App will pass its bundled copy.
**Why:** One copy of the JSON, no package-resource syncing, and tests always check the real files the owner edits.

## D-011 — 1A auto-staffs buildings, oldest first (2026-10-31) [Accepted]
**Decision:** Until job assignment arrives in 1C, survivors automatically fill worker slots of finished buildings in build order (`Systems/Economy/Staffing.swift`).
**Why:** Production depends on staffing (`productionPerMin × staffed / workers`), but manual jobs are 1C scope; a fixed order keeps it deterministic and easy to replace.

## D-012 — 1A construction has a build timer but no slots/builders (2026-10-31) [Accepted]
**Decision:** Placing pays the L1 cost and the building finishes after `buildSeconds`; construction slots, the queue, and borrowed builders (`buildings.json rules`) wait for 1C.
**Why:** 1C's plan owns "build queue limited by available builders"; a timer now means saves already hold build progress, so 1C adds limits without a save migration.

## D-013 — Frame-hitch cap in economy.json (2026-10-31) [Accepted]
**Decision:** `GameLoop.advance` simulates at most `economy.json maxFrameSeconds` (0.25 s) of real time per call; longer gaps are dropped.
**Why:** A hitch or a return from background must not jump the game ahead; real time away is handled on purpose by offline catch-up in 1D.


## D-014 — Xcode project created once by an agent, with XcodeGen (2026-10-31) [Accepted]
**Decision:** With the owner's one-time approval, an agent created `HighwayHoldout.xcodeproj` by running XcodeGen 2.46 from a spec kept outside the repo (not checked in). Settings: iOS app target `HighwayHoldout`, Swift 6, iOS/iPadOS 17.0, iPhone + iPad, landscape only, generated Info.plist, bundle id `com.highwayholdout.app`. `App/` is a synced (buildable) folder, the local package `Core` (`HoldoutCore`) is linked, and no app test target (Core tests cover the logic). The repo's `Content/` folder is added as a **folder reference** in Copy Bundle Resources, so the app has `HighwayHoldout.app/Content/` (with `maps/`), and `GameStore` passes `Bundle.main.url(forResource: "Content", withExtension: nil)` to `ContentLoader.load(from:)`.
**Why:** XcodeGen produces the same project Xcode would, with no clicking, and the spec isn't kept, so nobody regenerates or hand-edits the project later. A folder reference keeps `maps/` as a subfolder and picks up new JSON files with no project edit. From now on, agents never edit `project.pbxproj` (AGENTS.md).

## D-015 — Placeholder art is drawn at runtime (2026-10-31) [Accepted]
**Decision:** `ArtRegistry` draws a missing image into a texture once (category color + the art id written on it) and caches it. The same path serves SpriteKit sprites and SwiftUI icons. Sprite sizes always come from footprint × 32 pt, never from the image.
**Why:** Every placeholder, even each of the 1,200 ground tiles, is a labeled, cheap, batched sprite. Real art and placeholders can mix in any combination, and a PNG with the right name replaces its placeholder with no code change.

## D-016 — Two views (isometric + top-down), built in 1V before 1B (2026-10-31) [Accepted]
**Decision:** The normal view is isometric ("full Tropico style"); the game flips to top-down while placing/moving (and by a HUD button). Each view has its own art pack with the same filenames, set up in `Content/presentation.json`, with depth sorting, anchored tall sprites, and 3D placeholder blocks. The in-between 3/4 option was dropped by the owner. The pure projection math lives in Core (`Presentation/GridProjection.swift`, Foundation-only) so it can be unit-tested; Core's simulation never uses it.
**Why:** The owner wants a 3/4 "like Tropico" look and may change art style. 1B–1D add most of the drawing code (zombies, turrets, FX, bars), so doing this first avoids rewriting it. The simulation grid is unchanged. Plan: `docs/PHASE1-TASKS.md`.

## D-017 — Fresh Blender art study; abandon the pixel variant (2026-10-31) [Accepted]
**Decision:** At the owner's request, stop the 8-bit experiment and build a separate original 3D study in Blender, with reusable model collections, a diorama and ten transparent sprite samples. Keep the app's currently imported artwork in place while the new direction is evaluated.
**Why:** The owner rejected a pixelized version of the previous art and requested something completely different using the newly installed Blender. Retaining real 3D models allows later camera changes for D-016; the study does not choose the final projection or implement a gameplay milestone. The importer was run only in dry-run mode because its trim/refit behavior would change sprite pivots.

## D-018 — Art folders per view; unlabeled iso ground placeholders (2026-10-31) [Accepted]
**Decision:** Art lives in namespaced asset-catalog folders: `Art/TopDown/`, `Art/Iso/`, and `Art/UI/` (icons, shared by both views). `tools/import_art.py --view` picks the folder, and isometric art is never trimmed. Isometric ground-tile placeholders are plain colored diamonds without labels; every other placeholder still shows its id.
**Why:** Both views use the same filenames (`bld_farm`), so they need separate folders, and the game shows one view's art without mixing. Iso art depends on an exact ground point, so trimming would move it. 1,200 tile labels made the map unreadable, and tile colors already tell the ground types apart.

## D-019 — Isometric art rendered from the Blender study; UI kit adopted (2026-10-31) [Accepted]
**Decision:** The isometric view's art is rendered by `tools/blender/render_iso_sprites.py` from the Blender study's models, using the camera in `docs/graphics-spec-iso.md`. Buildings the study didn't have (scavenger, workshop, barracks, storage, scaffolds, rubble, ground tiles) got simple stand-in models in the study's style (`tools/blender/extra_models.py`). Menus use ChatGPT's `HighwayHoldout_UI_Kit` via `App/UI/KitStyle.swift`.
**Why:** The owner wanted real art in the 3D view, and no isometric sprites had been delivered. The study's hand-off said to re-render from its 3D source once the game picked a projection. Rendering from 3D gives exact 2:1 angles and anchors and makes facings easy. Any art-team PNG with the same name replaces a rendered one on the next import.

## D-020 — Repairing a damaged building is instant in 1B (2026-10-31) [Accepted]
**Decision:** Repairing a damaged building pays and restores full hp at once, and the building keeps working. Rubble still rebuilds on a construction timer.
**Why:** A repair timer marked the building unfinished, so a Storage under repair dropped the storage cap and the economy deleted stock above it. Timed repairs come back with 1C builders, using a separate repair state.

## D-021 — 1B rule interpretations (hordes and towers) (2026-10-31) [Accepted]
**Decision:** Horde budget = baseBudget + budgetPerDay × (day − 1) (per hordes.json notes). One zombie spawns per active edge every spawnIntervalSeconds. Edges are picked at the warning, and the mix at the start. Seeded picks use plain modulo. Repair cost rounds up, so small damage isn't free. Towers fire when (tick + buildingID) % max(1, round(tps / fireRate)) == 0, with no saved cooldown. Unknown `targeting` values act like `single_nearest`. Nearest-to-HQ uses the weight-1.0 flow field.
**Why:** These keep hordes and towers deterministic with no extra save fields, and match the content notes. Details: docs/features/hordes.md and combat.md.

## D-022 — Isometric placement becomes the normal build experience (2026-10-31) [Accepted; implemented 2026-10-31]
**Decision:** The owner approved improving placement in isometric with a ground grid, clear footprint/validity feedback, drag preview + Confirm, and temporary fading of obstructing buildings. Once verified on iPhone, disable automatic top-down switching. Keep the existing top-down mode manually available during testing; do not remove it yet.
**Why:** A continuous isometric view avoids the visual/style jump and reduces the need to maintain two polished art sets. Top-down remains a fallback until touch placement is proven.
**Scope/status:** Docs-only coordination in this pass; app behavior is unchanged. Supersedes D-016's automatic placement-switch requirement, not its view-independent projection architecture. Build order and acceptance checks: `PHASE1-TASKS.md` → Approved update — isometric placement first.

## D-023 — Starting walls fully enclose the HQ (2026-10-31) [Accepted]
**Decision:** A new game starts with a closed ring of 28 wood walls (x 20–28, y 16–22) around the HQ and watchtower, instead of two 6-wall rows. `buildings.json startingLayout` wall count 12 → 28 (under the HQ-1 cap of 40).
**Why:** The owner wants walls to matter from the first horde. With gaps, zombies walked around the walls. Now day 1 has to break through a wall to reach the HQ. Existing saves keep their own walls; only new games change.

## D-024 — Walls are drawn as lines and built all at once (2026-10-31) [Accepted]
**Decision:** Walls use a wall tool instead of the single-building ghost. You drag a line (straight or one-corner L), the bar shows the count and total cost, and Build places the whole line in one command (`Command.placeLine`). Blocked tiles, tiles past the limit, and existing walls are skipped and not charged. If you can't afford the whole line, nothing is built. Two-finger pan always moves the map, because one finger draws.
**Why:** The owner found wall building awkward and wanted to plan a wall and see its cost before committing. Building all-or-nothing avoids half-built lines when resources run out partway.

## D-025 — Realistic walker uses generated static cutouts (2026-10-31) [Pilot]
**Decision:** Owner requested one realistic zombie end to end. Replace only the isometric walker with two transparent generated views (plus the SE base fallback), using existing mirrored facings and importer. Retain full-resolution sources, prompts, previous art and fitting script.
**Trade-off:** This delivers detailed anatomy/materials without rebuilding gameplay, but is not a rigged 3D model and cannot be animated by posing the old low-poly Blender walker. Camera/pose consistency is approximate, not guaranteed by shared geometry. Limb animation is explicitly reserved for another chat; preserve this visual direction there.

## ZWALK-1 prototype production choice (2026-10-31)
Use reference-conditioned generated pose sheets for the current realistic 2D walker, rather than reverting to the old Blender miniature. Preserve original still assets; slice/resize/pad generated poses without repainting them. Trade-off: generated poses have approximate rather than rig-guaranteed anatomy/camera consistency, so balanced stride and anchor review remain required before chunk 2A closes. Animation timing lives in presentation.json; no gameplay/save changes.

## D-026 — Mixamo stock walker and matching stills (2026-10-31) [Accepted]
**Decision:** Owner chose a stock Mixamo zombie for ZWALK-1M and approved using Adobe's character and walking animation after the asset-source terms were explained. Render six poses for each of SE/NE and replace both directional stills with frame 0. Keep raw FBX sources out of the app and do not redistribute them. Walker only; runner/brute and attacks remain deferred.
**Why / trade-off:** Rigged motion should correct the generated-pose prototype's unbalanced gait, at the cost of changing the character's appearance. Adobe's current Mixamo FAQ permits royalty-free character/animation use in video games: https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html (checked 2026-10-31). Prototype and supporting work preserved in local commit `c12e557`.

### D-026 implementation / verification note (2026-10-31)
Selected Yaku J Ignite / Zombie Walk through the owner's newly installed Chrome extension; original browser blocker resolved. Embedded FBX textures retained. Shared iso renderer helpers are imported through a new main guard, avoiding duplicated camera/light values. Fixed cycle-wide projected fit supplies the existing 256×232 canvas; root-motion distance after that fit gives 0.6149123397 tiles per loop. Editable FBX sources and intermediate recordings stay local and ignored by Git. Native simulator clicks failed; documented actual-app fixtures substitute for automated visual checks, while normal-horde hands-on acceptance remains explicitly pending. No third-party runtime library was added.

## D-027 — Owner picks the 3D option; spike first (2026-11-01) [Accepted]
**Decision:** After comparing two plans and mockups (`docs/plans/living-world-plan.md` vs `docs/plans/3d-rendering-plan.md`, pictures in `docs/plans/mockups/`), the owner chose real 3D (Tropico-style world, turnable camera, real shadows). Work starts with chunk 1R only: a DEBUG RealityKit spike that doesn't touch the game. 2R/2M and later start only after the owner says "go" on 1R's results. Engine is RealityKit (SceneKit is soft-deprecated; no third-party engine). Minimum iOS (stay 17 vs raise to 18) is decided after 1R.
**Why / trade-off:** 3D is ~3–4× the work of the 2D living-world pass, mostly art, and every new feature gets drawn twice while both renderers exist. A cheap spike turns the choice into a measured one. This is outside Phase 1 scope; the owner approved it explicitly. The 2D plan is parked, not deleted.

## D-028 — 1R spike: two hosts, Mixamo USDZ kept local (2026-11-01) [Spike]
**Decision:** The DEBUG 3D spike draws one shared scene through both `RealityView` (virtual camera, iOS 18+) and `ARView` non-AR mode (the only iOS 17 route), switchable on screen, so the iOS 17-vs-18 choice is measured rather than guessed. The animated Mixamo walker USDZ is git-ignored like its FBX source (D-026: only rendered PNGs are committed) until the Adobe terms check for shipping a rigged character is done. Spike tuning lives in `App/Spike3D/spike3d.json`, not `Content/`, so game content and `ContentFilesTests` stay untouched.
**Why / trade-off:** A little extra spike code buys a direct comparison. The spike folder is throwaway and its USDZ files are copied into Release builds too, so delete `App/Spike3D/` before any TestFlight build or when 2R lands.

## D-028 — GO on 3D; minimum iOS raised to 18 (2026-11-01) [Accepted]
**Decision:** After chunk 1R (`docs/plans/3d-spike-1R-results.md`: real iPhone 18 Pro held 60 fps with 100 animated walkers and shadows), the owner said go on 2R and 2M and chose iOS 18 as the minimum. `IPHONEOS_DEPLOYMENT_TARGET` 17.0 → 18.0 in the project file (owner-approved edit) and `Core/Package.swift` `.iOS(.v18)`.
**Why / trade-off:** RealityKit's `RealityView` virtual camera, particles, billboards, opacity fades and ambient-light control are iOS 18+. Staying on 17 meant a second 3D code path (`ARView`) or giving those up. Cost: iPhones that can't update past iOS 17 can't install the game (iPhone 15 runs iOS 18+, so the stated iPhone 15+ target is unaffected). Still open for later: free vs snapped camera rotation (before 2R's camera tuning), older-phone and heat checks (5R), Mixamo shipping terms (3M).

## D-029 — 3D camera snaps to 4 angles (2026-11-01) [Accepted]
**Decision:** In the 3D view the camera turns in 90° steps (4 angles, like Tropico), not freely. A two-finger twist past a threshold rotates to the next angle with a short eased turn. Pan, pinch zoom and limited tilt stay as in 1R. Snap angle count, turn time and twist threshold go in JSON.
**Why:** The owner wants it easier to manage: buildings and walls always line up with the screen, you can't get lost at an odd angle, and art/occlusion only need checking from 4 sides. Supersedes the "free vs snapped" open question in D-028.


## D-030 — 2D retired; the game is 3D only (2026-11-01) [Accepted]
**Decision:** Right after 2R made the game run in 3D, the owner said "retire all that, we're moving to full 3D" and, when told that building would be off until 3D placement exists, chose to retire 2D now (chunk 6R done early, ahead of 3R–5R). Removed: the SpriteKit scene and node factories, isometric/top-down views and toggle, the 2D camera and taps, `Art/Iso` and `Art/TopDown` (~4.6 MB), Core `GridProjection`/`Facing` (+ tests), and the 2D parts of `presentation.json` (now schema 2) including the brief `renderer` switch. Kept: SwiftUI menus/HUD and UI-kit art, `PlacementController` logic and bars (for 3R), 8 iso building pictures moved to `Art/Menu/` for build-menu cards, the DEBUG 1R spike, `tools/` and the source art folders (not in the app; 2M reuses the Blender model scripts). Supersedes the "keep 2D alongside until 5R" part of the 3D plan (§4) and makes chunk 2A (2D walker frames) moot.
**Why / trade-off:** One renderer means every later feature is drawn once, not twice. Cost: until 3R, the player can watch the town and hordes but can't build, move, select or draw walls; the old 2D code is only in git history if ever needed. The save format is unchanged.

## D-031 — 2R choices: display-link clock, camera math in Core, one step per twist (2026-11-01) [Accepted]
**Decision:** (1) The game clock is a `CADisplayLink` in `GameTicker`, not the renderer's frame callback, so time never depends on what draws it and can pause (DEBUG spike). Core events are buffered and drained by the 3D view each frame. (2) The orbit camera's math (`OrbitCamera3D`) lives in Core's `Presentation/` beside `WorldMapping3D` (Foundation only, like D-016) so pan, zoom-toward-fingers, minimum height, map clamp and snapping are unit-tested; the simulator's touch injection is unreliable for checking these. (3) One two-finger twist turns at most one 90° step: in the simulator a 60° twist turned the view 180° when every 25° counted. (4) `ModelRegistry` loads any `<artId>.usdz` in the bundle, so the 1R spike's six models already show; `reality3d.loadModels: false` gives boxes only.
**Why / trade-off:** (1) costs one frame of possible lag between tick and draw, which isn't visible. (2) puts App-only math in the Core package, which the simulation never calls.

## D-032 — 3R choices: touches picked by Core ray math, two-finger pan only in the wall tool (2026-11-01) [Accepted]
**Decision:** (1) A tap or drag becomes a ray from the camera (`OrbitCamera3D.ray`); Core's `RayPicking3D` finds the first building box it enters (footprint × roof height, the loaded model's real height or the placeholder's) and the ghost's occluders. RealityKit collision components and scene raycasts are not used. (2) Two-finger up/down drag tilts the camera everywhere except the wall tool, where one finger draws, so two fingers pan instead. (3) Look-only numbers (grid radius 6, lift 56 pt, ghost 0.6 / faded 0.3 opacity) stay named Swift constants, as they were in 2D. (4) Only buildings fade in front of the ghost, not decorations.
**Why / trade-off:** (1) is the same unit-tested math as the camera (D-031) and works the same with boxes or 2M models; a footprint box is a little bigger than a thin model (a tap just beside a watchtower's legs still selects it), which suits fingers. (2) keeps the 2R camera intact while the 2D rule "two fingers pan" still holds where it mattered. (4) decorations are low boxes for now; revisit when 2M brings tall trees.

## D-033 — 1B: build queue replaces timer-only construction (2026-11-01) [Accepted]
**Decision:** Replaces D-012 (every building just counts down its own timer, cost paid at placement). Now every build, upgrade and rubble rebuild is a `ConstructionJob` in `Base.jobs`: `constructionSlotsByHq` run at once, up to `constructionQueueLength` wait, each running job borrows `buildersPerJob` survivors, and the **cost is paid when a job starts**. Placing/upgrading still needs the money at that moment (so a wrong click fails with a reason) but a waiting job can sit unpaid; if funds drop it is skipped and a cheaper waiting job starts first. A running job refunds `cancelRefundPct` (75, new JSON field) when cancelled; a waiting one is free. A wall line is capped by the free room (slots + queue) and says "queue full". Damaged-building repair stays instant and free of builders (D-020). Save v3 turns a half-built v2 building into a running, already-paid job with no builders.
**Why / trade-off:** Gives upgrades and the Builders/slot limits the rules text already promised. Until chunk 2B (manual jobs) workers are auto-assigned, so a builder is simply taken from the survivor pool and auto-staffing refills from whoever is left: a busy town briefly runs its farms with fewer workers. Starting walls ring needs no jobs (they begin finished).

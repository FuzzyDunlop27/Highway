# MAP — where everything lives

_Read this before opening any code. Keep it accurate: if you add, move, rename, or delete a file, update this page in the same change._

**Status key:** `[ ]` planned, not created yet · `[x]` exists. Flip the box when you create the file.
Everything for milestone 1A exists (Core package + App target). `Content/` is bundled into the app as a folder. The map is drawn in 3D only (D-030).

## Lookup: "I want to change X" → look in Y

| I want to change… | Look in |
|---|---|
| Zombie speed, health, damage, wall-bashing | `Content/zombies.json` |
| Horde size, timing, which map edge they use | `Content/hordes.json` |
| Building cost, build time, size, output, upgrade levels | `Content/buildings.json` |
| Wall/tower cost, range, fire rate, slow % | `Content/buildings.json` (defenses live here too) |
| Starting resources, base storage caps, survivor arrival | `Content/resources.json` |
| Defender/survivor stats, training time | `Content/units.json` |
| Research items, costs, what they unlock | `Content/research.json` |
| Tick rate, autosave, frame-hitch cap, HQ-loss penalty % | `Content/economy.json` |
| Offline credit cap (12h), what progresses while away, Horde Alert timing | `Content/offline.json` |
| Which number to change when it feels too slow/hard | `docs/features/balance.md` |
| Map layout, roads, spawn edges | `Content/maps/phase1_exit.json` |
| How buildings / zombies look in 3D | `App/Rendering/{BuildingLayer3D,ZombieLayer3D}.swift`; models `<artId>.usdz` via `ModelRegistry.swift` (effects: chunk 4R) |
| Horde chip, banners, debug menu | `App/UI/HordeChipView.swift`, `HordeBannerView.swift`, `DebugMenuView.swift` |
| Horde timing, size, mix, edges | `Content/hordes.json`; code `Core/.../Systems/Hordes/` (notes: `docs/features/hordes.md`) |
| Zombie routes, bashing, traps | `docs/features/pathing.md`; code `Core/.../Systems/Pathing/`, `Systems/Combat/ZombieMovement.swift` |
| Which zombie a tower shoots | `Core/Sources/HoldoutCore/Systems/Combat/TargetingSystem.swift` |
| How zombies choose a route / pile up at walls | `Core/Sources/HoldoutCore/Systems/Pathing/FlowField.swift` |
| What happens when HQ falls | `Core/Sources/HoldoutCore/Systems/Hordes/HordeOutcome.swift` |
| What happens while the app was closed | `Core/Sources/HoldoutCore/Systems/OfflineCatchUp/OfflineCatchUp.swift` |
| Save format / old-save migration | `Core/Sources/HoldoutCore/Save/` |
| How fast farms/posts produce, caps, survivor arrival (code) | `Core/Sources/HoldoutCore/Systems/Economy/EconomySystem.swift` |
| Why a spot is red / placement rules | `Core/Sources/HoldoutCore/Systems/Construction/PlacementRules.swift` |
| What the App can call in Core | `docs/features/core-api.md` |
| Placeholder box size/color/label for a missing 3D model | `App/Rendering/ModelRegistry.swift`; heights in `Content/presentation.json` `reality3d.placeholderHeightTiles` |
| Which model an entity uses | its art id (`sprite` in buildings/zombies JSON) → `<artId>.usdz` in the app bundle (`ModelRegistry.swift`) |
| Menu/HUD pictures, missing-picture placeholder | `App/Rendering/ArtRegistry.swift`, `PlaceholderArt.swift`; art in `Art/UI`, `Art/Menu` |
| Camera feel: pan, pinch, twist snap, tilt, min height, zoom limits | `Content/presentation.json` `reality3d.camera`; math `Core/.../Presentation/OrbitCamera3D.swift`; touches `App/Input/OrbitGestures3D.swift` |
| Sun, shadows, fill light, background color | `Content/presentation.json` `reality3d.light`, `outsideMapColor`; code `App/Rendering/World3D.swift` |
| Tile ↔ 3D world position | `Core/.../Presentation/WorldMapping3D.swift` |
| Ground look (merged mesh, colors) | `App/Rendering/GroundMesh3D.swift` |
| Game clock (who advances Core each frame) | `App/GameTicker.swift` |
| Wall tool (drag a line, cost, Build) | `App/Input/PlacementController.swift` (`.drawingLine`), `App/UI/WallLineBarView.swift`; drawn by `App/Rendering/PlacementLayer3D.swift`; rules `Core/.../Construction/WallLinePlanner.swift` |
| Tap-to-place, ghost, grid, invalid-spot red | logic `App/Input/PlacementController.swift`; touches `App/Input/PlacementTouches3D.swift`; drawing `App/Rendering/PlacementLayer3D.swift` |
| What a tap hits (roof vs ground), what fades in front of the ghost | `Core/.../Presentation/RayPicking3D.swift`; boxes `BuildingLayer3D.pickBoxes`; fading `App/Rendering/OccluderFader3D.swift` |
| Selection outline, range ring | `App/Rendering/SelectionLayer3D.swift` (shapes `OverlayMeshes3D.swift`) |
| Text shown when a spot is invalid | `App/Input/PlacementMessages.swift` |
| Confirm/Cancel and Move/Demolish bars | `App/UI/PlacementBarView.swift` |
| Where the save file lives / when it saves | `App/Platform/SaveFileStore.swift`, `App/Platform/AppLifecycle.swift` |
| Top bar (resources, clock) | `App/UI/HUDView.swift` |
| Pause / 1x / 2x buttons | `App/UI/SpeedButtonsView.swift` (speeds from `Content/economy.json speedOptions`) |
| Build slots, queue length, builders per job, cancel refund | `Content/buildings.json rules`; code `Core/.../Systems/Construction/BuildQueue.swift` |
| Upgrading a building | `Core/.../Systems/Construction/UpgradeSystem.swift`; level data in `Content/buildings.json` |
| Build menu | `App/UI/BuildMenuView.swift` |
| Menu look (colors, buttons, panels, glyphs from the UI kit) | `App/UI/KitStyle.swift`; art in `HighwayHoldout_UI_Kit/` |
| 3D spike (chunk 1R, DEBUG) | `App/Spike3D/`; results `docs/plans/3d-spike-1R-results.md` |
| Free CC0 asset spike (DEBUG, "Free assets" scene) | layout `App/Spike3D/Spike3DLayouts.swift`; convert `tools/blender/free_assets_spike_export.py`; results `docs/research/free-assets.md` |
| Blender model scripts (source for 2M's USDZ export) | `tools/blender/*_models.py` |
| Settings (Time factor, Horde Alerts) | `App/UI/SettingsView.swift` |
| "Welcome back" summary | `App/UI/WelcomeBackView.swift` |
| Horde Alert notification text/timing | `App/Platform/NotificationScheduler.swift` |
| Replace a placeholder box with a real model | add `<artId>.usdz` to the app (chunk 2M pipeline); menu PNGs: `python3 tools/import_art.py <folder> --view ui` |

## Folder tree

```
/
├─ [x] AGENTS.md            Rules for all agents (single source of truth)
├─ [x] CLAUDE.md            Points Claude Code at AGENTS.md
├─ docs/
│  ├─ [x] STATUS.md         Where we left off, next step, open questions
│  ├─ [x] MAP.md            This file
│  ├─ [x] DECISIONS.md      Why things are the way they are
│  ├─ [x] BUILD-QUEUE.md    Build chunks (1A, 2A, 1B…): dependencies, status, start prompts
│  ├─ [x] GAME-DESIGN.md    What the game is; Phase 1 content list
│  ├─ [x] PHASE1-PLAN.md    Stack, milestones 1A–1E, exit checks, kickoff prompts
│  ├─ [x] PHASE1-TASKS.md   Task-by-task plan for what's left (1V two views → 1E), owner decisions
│  ├─ [x] graphics-spec-phase1.md  Art ids/filenames (still the id list); its top-down sprite specs are retired (D-030)
│  ├─ [x] art-templates/           RETIRED (D-030): iso diamond guides
│  ├─ plans/                Proposals for the owner to pick from (not yet in BUILD-QUEUE)
│  │  ├─ [x] living-world-plan.md  Option 1: Tropico-style living world in 2D (chunks 1K 1N 1F 1U 1S 2F 2S)
│  │  ├─ [x] 3d-rendering-plan.md  Option 2: real 3D drawing with RealityKit (chunks 1R–6R, 2M, 3M)
│  │  ├─ [x] 3d-spike-1R-results.md  Chunk 1R results: fps table, iOS 17/18 findings, gaps, go/no-go
│  │  ├─ [x] spike-1R/     1R screenshots (3D spike + current 2D for comparison)
│  │  └─ [x] mockups/      Look-alike pictures of each option (painted over a real screenshot / Blender render)
│  └─ features/             One short note per feature (see list below)
│     ├─ [x] _TEMPLATE.md   Copy this to start a new feature note
│     ├─ [x] balance.md     Pacing targets, formulas, timeline, tuning knobs
│     ├─ [x] core-api.md    What the App calls in Core (load, tick, commands, placement, save)
│     ├─ [x] economy.md     Production, caps, housing, survivor arrival, auto-staffing
│     ├─ [x] construction.md  Place/move/demolish, placement rules, the map
│     ├─ [x] save.md        Versioned save JSON + migrations; save file + autosave
│     ├─ [x] rendering-art.md  3D renderer: ticker, RealityView world, ground, ModelRegistry, layers
│     ├─ [x] zombie-walk-mixamo.md  RETIRED 2D walker frames (D-030); Mixamo source notes still useful for 3M
│     ├─ [x] input.md       Camera, ghost placement, select/move/demolish
│     └─ [x] hud-ui.md      GameStore, HUD, build menu, bottom bars
├─ Content/                 ALL tuning data, loaded at runtime. No numbers in Swift.
│  ├─ [x] resources.json    Food/Scrap/Survivors: starting amounts, base caps, survivor arrival
│  ├─ [x] buildings.json    All buildings AND defenses: footprint, cost, levels 1–3, effects
│  ├─ [x] units.json        Survivor, Defender
│  ├─ [x] zombies.json      Walker, Runner, Brute
│  ├─ [x] hordes.json       Horde schedule, size curve, composition, spawn edges, bonus horde
│  ├─ [x] research.json     Metal Fortification, Marksmanship, Agriculture
│  ├─ [x] economy.json      Tick rate, speeds, autosave, HQ-loss penalty
│  ├─ [x] offline.json      Time factor (offline credit) + Horde Alert notification rules
│  ├─ [x] presentation.json 3D view: camera, light, placeholder box sizes, background color (App only)
│  └─ maps/
│     └─ [x] phase1_exit.json  The highway-exit starting map (40×30, highway on the north edge)
├─ Core/                    Swift package HoldoutCore: pure simulation, Foundation only
│  ├─ [x] Package.swift     iOS 18 / macOS 14, Swift 6; `cd Core && swift test`
│  ├─ Sources/HoldoutCore/
│  │  ├─ Model/             Plain saved data
│  │  │  ├─ [x] GameState.swift   Clock, speed, random, group, bases
│  │  │  ├─ [x] NewGame.swift     Fresh game: starting resources + starting layout
│  │  │  ├─ [x] Base.swift        One town: map id, buildings, stock (food/scrap)
│  │  │  ├─ [x] Group.swift       Survivors + Knowledge (carries to future bases)
│  │  │  ├─ [x] Building.swift    A placed building: level, origin, build progress, staffed
│  │  │  ├─ [x] ConstructionJob.swift  One build / upgrade / rebuild job, waiting or running (Base.jobs)
│  │  │  └─ [x] GridPoint.swift   Tile x/y (y down) + footprint tiles
│  │  ├─ Simulation/
│  │  │  ├─ [x] GameLoop.swift    Fixed tick, commands, placement checks: the App's entry point
│  │  │  ├─ [x] Command.swift     Player actions in, outcomes/errors out
│  │  │  └─ [x] SeededRandom.swift  Deterministic random (SplitMix64), saved
│  │  ├─ Presentation/      [x] WorldMapping3D.swift (tile ↔ 3D metres), OrbitCamera3D.swift (camera math), RayPicking3D.swift (finger ray, box hits) — App only
│  │  ├─ Model/ (1B)        [x] Zombie.swift, HordeState.swift (+ ActiveHorde); Simulation/SimEvent.swift (events for drawing)
│  │  ├─ Content/           ContentLoader + Codable definitions matching Content/*.json (+ PresentationDefs.swift)
│  │  │  ├─ [x] ContentLoader.swift / ContentValidator.swift / GameContent.swift
│  │  │  ├─ [x] ResourceDefs.swift (+ Cost) / BuildingDefs.swift / MapDef.swift / EconomyDefs.swift
│  │  │  └─ [x] UnitDefs / ZombieDefs / HordeDefs / ResearchDefs / OfflineDefs.swift  (decoded now, used 1B–1D)
│  │  ├─ Systems/           One folder per game system:
│  │  │  ├─ Economy/        [x] EconomySystem, StorageRules, Staffing, ResourceSnapshot
│  │  │  ├─ Construction/   [x] PlacementRules, ConstructionSystem (place/move/demolish), BuildQueue + BuildQueueStatus (slots, queue, builders), UpgradeSystem
│  │  │  ├─ [ ] Jobs/           Assign survivors to work; defender training & garrison
│  │  │  ├─ Pathing/        [x] FlowField (Dijkstra cost to HQ; walls cost by hp), FlowFieldCache (rebuild on change)
│  │  │  ├─ Combat/         [x] ZombieMovement, WallBashing, Traps (spikes/barbed wire), TargetingSystem, TowerFiring
│  │  │  ├─ Hordes/         [x] HordeSystem (clock, warning, spawn), HordeComposer (size/mix/edges),
│  │  │  │                  HordeResolution (deaths, loot, rubble), HordeOutcome (held bonus, HQ fall), HordeStatus
│  │  │  ├─ Construction/   [x] RepairSystem (repair damage at once, rebuild rubble on a timer; cost preview)
│  │  │  ├─ [ ] Research/       Knowledge items (stored on Group, not Base)
│  │  │  └─ [ ] OfflineCatchUp/ Time-factor catch-up: resources/builds only, never attacks
│  │  └─ Save/              [x] SaveCodec (versioned JSON), SaveMigrations (upgrade old saves)
│  └─ Tests/HoldoutCoreTests/  Swift Testing; folders mirror Sources/
│     ├─ [x] TestSupport.swift  Finds repo Content/ via #filePath, builds test games
│     ├─ [x] Presentation/WorldMapping3DTests.swift, OrbitCamera3DTests.swift, RayPicking3DTests.swift
│     ├─ [x] Systems/Pathing/FlowFieldTests.swift · Systems/Combat/{ZombieMovement,TargetingSystem,TowerFiring}Tests.swift (+ CombatTestSupport)
│     ├─ [x] Systems/Hordes/{HordeSystem,HordeComposer,HordeResolution}Tests.swift · Systems/Construction/RepairSystemTests.swift
│     ├─ [x] Content/ContentFilesTests.swift · Simulation/GameLoopTests.swift · Save/SaveCodecTests.swift
│     └─ [x] Systems/Economy/EconomySystemTests.swift · Systems/Construction/PlacementRulesTests.swift, ConstructionSystemTests.swift, BuildQueueTests.swift
├─ [x] HighwayHoldout.xcodeproj  App project (created once, D-014). Never edit project.pbxproj.
├─ App/                     App target HighwayHoldout (iOS, synced folder: new files need no project edit)
│  ├─ [x] HighwayHoldoutApp.swift  App entry point; saves when the app leaves the foreground
│  ├─ [x] GameStore.swift   @Observable bridge: loads content + save, owns Core GameLoop, sends Commands
│  ├─ [x] GameTicker.swift  The game clock: display link → GameStore.advance each frame; buffers Core events
│  ├─ Rendering/            RealityKit 3D (2D SpriteKit retired, D-030)
│  │  ├─ [x] Reality3DView.swift   SwiftUI host: RealityView (virtual camera) + touch layer
│  │  ├─ [x] World3D.swift         scene: camera, sun/fill light, ground, layers; per-frame sync to Core
│  │  ├─ [x] GroundMesh3D.swift    one merged ground mesh + decorations; Reality3DSizes helpers
│  │  ├─ [x] BuildingLayer3D.swift one entity per building, rebuilt on Signature change; wall direction; pick boxes
│  │  ├─ [x] PlacementLayer3D.swift ghost, tile grid, green/red footprint, planned wall line (3R)
│  │  ├─ [x] SelectionLayer3D.swift selected building's outline + range ring (3R)
│  │  ├─ [x] OccluderFader3D.swift  fades buildings between the camera and the ghost (3R)
│  │  ├─ [x] OverlayMeshes3D.swift  flat see-through ground shapes: tiles, outlines, ring (3R)
│  │  ├─ [x] ZombieLayer3D.swift   one entity per zombie, moved/turned every frame
│  │  ├─ [x] ModelRegistry.swift   art id → USDZ model loaded in the background, else labeled box; never crashes
│  │  ├─ [x] ArtRegistry.swift     menu/HUD pictures (Art/UI, Art/Menu) + placeholder; UIColor.hex, ArtCategory
│  │  └─ [x] PlaceholderArt.swift  labeled flat box for missing menu art; per-prefix colors (also 3D boxes)
│  ├─ Input/
│  │  ├─ [x] OrbitGestures3D.swift      3D touches: pan, pinch toward fingers, twist snap, tilt (pan in wall tool); routes taps/drags
│  │  ├─ [x] PlacementTouches3D.swift   tap select/place, lifted ghost drag, wall-line drag (finger → ray)
│  │  ├─ [x] PlacementController.swift  Mode (select/place/move/line), ghost spot, validity, Confirm command
│  │  └─ [x] PlacementMessages.swift    Core placement problems/errors → player text
│  ├─ UI/                   SwiftUI
│  │  ├─ [x] GameRootView.swift  3D map + overlays, ArtIcon, notice banner, load-error screen
│  │  ├─ [x] HUDView.swift / SpeedButtonsView.swift / BuildMenuView.swift / PlacementBarView.swift (Confirm/Cancel; Move/Demolish)
│  │  ├─ [x] KitStyle.swift      UI kit look: colors, panels, buttons, glyphs, icon buttons
│  │  ├─ [x] HordeChipView.swift / HordeBannerView.swift  day + countdown chip; start/held/HQ-fell banners
│  │  ├─ [x] DebugMenuView.swift  DEBUG only (long-press horde chip): horde now, +500, kill all, open 3D spike
│  │  ├─ [ ] SettingsView.swift         (1D)
│  │  └─ [ ] WelcomeBackView.swift      Summary after Time-factor catch-up (1D)
│  ├─ Platform/
│  │  ├─ [x] SaveFileStore.swift        Read/write Application Support/HighwayHoldout/save.json
│  │  ├─ [ ] NotificationScheduler.swift  Horde Alert local notifications (1D)
│  │  └─ [x] AppLifecycle.swift         Save on leaving foreground + every economy.json autosaveSeconds
│  ├─ Spike3D/              DEBUG chunk 1R RealityKit spike (reference; its Models/*.usdz also show in the game until 2M); notes: docs/plans/3d-spike-1R-results.md
│  │  ├─ [x] Spike3DScreen.swift       screen: fps readout, scene/walker/shadow/host/cap toggles, launch args
│  │  ├─ [x] Spike3DLayouts.swift      which models each spike scene places (study town / free-asset lineup)
│  │  ├─ [x] Spike3DWorld.swift        scene: ground, models, dusk sun + fill, walker rings, per-frame update
│  │  ├─ [x] Spike3DHosts.swift        RealityView virtual camera (iOS 18) and ARView non-AR (iOS 17) hosts
│  │  ├─ [x] Spike3DOrbitCamera.swift  pan / zoom / twist / limited tilt → camera transform
│  │  ├─ [x] Spike3DGestureLayer.swift UIKit touch recognizers driving the orbit camera
│  │  ├─ [x] Spike3DConfig.swift + spike3d.json  spike-only tuning
│  │  ├─ Models/               USDZ from tools/blender/spike_export_usdz.py (walker USDZ is git-ignored, Mixamo)
│  │  └─ FreeAssets/           git-ignored fa_*.usdz from tools/blender/free_assets_spike_export.py (sources in HighwayHoldout_3D_Sources/free-assets/, also git-ignored)
│  ├─ AppIconLayers/        app_icon_bg/fg layers (written by tools/import_art.py)
│  └─ Assets.xcassets/      AppIcon + Art/UI/ (UI kit, tools/import_art.py --view ui) + Art/Menu/ (8 old iso building pictures for menu cards)
├─ HighwayHoldout_UI_Kit/   ChatGPT's UI kit (menu panels, buttons, glyphs, 3/4 build cards). Don't edit; import with --view ui.
├─ HighwayHoldout_3D_Sources/  Raw 3D source files (Mixamo walker FBX for chunk 3M).
├─ HighwayHoldout_Blender_Study/  3D art study (models + scripts) the isometric art is rendered from. Art team owns it.
├─ HighwayHoldout_3D_Sources/  Raw 3D source files (Mixamo walker FBX for chunk 3M).
├─ HighwayHoldout_Blender_Study/  Fresh 3D style study: editable .blend, models/, ten png/ samples, renders/, scripts/, QA and Claude handoff.
├─ HighwayHoldout_Blender_Study.zip  Shareable Blender study and sample assets.
└─ tools/
   ├─ [x] import_art.py     PNGs → imagesets; only --view ui is still used (topdown/iso folders were removed, D-030)
   └─ blender/
      ├─ [x] render_mixamo_walk.py  FBX walker → fixed-camera SE/NE frames, stills and measured stride
      ├─ [x] spike_export_usdz.py   one-off 1R export: 6 study models + Mixamo walker → USDZ (not the 2M pipeline)
      ├─ [x] free_assets_spike_export.py  free-asset spike: downloaded CC0 glTF/FBX/OBJ → fa_*.usdz (real metres, 1K textures)
      ├─ [x] preview_mixamo_walk.py  rendered walker → comparison overlay + four-facing GIF (Pillow)
      └─ [x] extra_models.py        stand-in models for buildings the study lacks
```

## Feature notes (`docs/features/`)
Create a note from `_TEMPLATE.md` the first time a feature is built. Planned names:
`economy.md` · `construction.md` · `jobs.md` · `pathing.md` · `combat.md` · `hordes.md` ·
`research.md` · `offline-catchup.md` · `save.md` · `rendering-art.md` · `input.md` ·
`hud-ui.md` · `notifications.md` · `settings.md` · `balance.md` (which JSON knobs to turn)

## Art delivery and review
- `HighwayHoldout_UI_Kit/`: `README.md`, `CLAUDE_HANDOFF.md`, `QA.md`, `manifest.json`, design tokens, PNG/SVG/Blender sources, generation scripts and four previews.
- `HighwayHoldout_UI_Kit.zip`: portable UI art handoff.
- `docs/reviews/2026-10-31-art-and-build-review.md`: verified GitHub baseline, two presentation findings and prioritized remaining work.

- Isometric placement direction and acceptance checks: `docs/PHASE1-TASKS.md` → Approved update — isometric placement first; decision D-022; implementation notes in `docs/features/input.md`.


- `docs/BUILD-QUEUE.md`: dependency-labelled chunks and paste-ready next-chat handoffs.



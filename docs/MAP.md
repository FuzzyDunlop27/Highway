# MAP — where everything lives

_Read this before opening any code. Keep it accurate: if you add, move, rename, or delete a file, update this page in the same change._

**Status key:** `[ ]` planned, not created yet · `[x]` exists. Flip the box when you create the file.
Everything for milestone 1A exists (Core package + App target). `Content/` is bundled into the app as a folder.

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
| How zombies / defenses / effects look | `App/Rendering/Nodes/{Zombie,Defense,FX}NodeFactory.swift` |
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
| Placeholder shape/color/label for missing art | `App/Rendering/ArtRegistry.swift` |
| Which image an entity uses | `App/Rendering/ArtRegistry.swift` |
| How a building/zombie/etc. is drawn | `App/Rendering/Nodes/<Type>NodeFactory.swift` |
| Camera pan/zoom feel | `App/Input/CameraController.swift`; zoom limits in `Content/presentation.json` |
| Isometric vs top-down: tile size, default view, auto top-down while building, block heights, art anchors | `Content/presentation.json` |
| How the view switch looks (fade, keep the spot centered) | `App/Rendering/ViewSwitcher.swift` |
| What draws in front of what | `App/Rendering/DepthSort.swift` |
| Placeholder blocks/boxes look | `App/Rendering/PlaceholderArt.swift` |
| How to draw isometric art (for ChatGPT/Blender) | `docs/graphics-spec-iso.md`, `docs/art-templates/` |
| Wall tool (drag a line, cost, Build) | `App/Input/PlacementController.swift` (`.drawingLine`), `App/Rendering/Nodes/WallLineNodeFactory.swift`, `App/UI/WallLineBarView.swift`; rules `Core/.../Construction/WallLinePlanner.swift` |
| Tap-to-place, ghost preview, invalid-spot red | `App/Input/PlacementController.swift` (logic), `App/Rendering/Nodes/GhostNodeFactory.swift` (look) |
| Text shown when a spot is invalid | `App/Input/PlacementMessages.swift` |
| Confirm/Cancel and Move/Demolish bars | `App/UI/PlacementBarView.swift` |
| Where the save file lives / when it saves | `App/Platform/SaveFileStore.swift`, `App/Platform/AppLifecycle.swift` |
| Tile size on screen, grid ↔ screen math | `App/Rendering/GridGeometry.swift` |
| Top bar (resources, clock, speed buttons) | `App/UI/HUDView.swift` |
| Build menu | `App/UI/BuildMenuView.swift` |
| Menu look (colors, buttons, panels, glyphs from the UI kit) | `App/UI/KitStyle.swift`; art in `HighwayHoldout_UI_Kit/` |
| Re-render isometric art from the 3D models | `tools/blender/render_iso_sprites.py` (models: Blender study + `tools/blender/extra_models.py`) |
| Settings (Time factor, Horde Alerts) | `App/UI/SettingsView.swift` |
| "Welcome back" summary | `App/UI/WelcomeBackView.swift` |
| Horde Alert notification text/timing | `App/Platform/NotificationScheduler.swift` |
| Replace a placeholder with real art | drop PNG in a folder → `python3 tools/import_art.py <folder> --view topdown` (or `--view iso`) |

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
│  ├─ [x] graphics-spec-phase1.md  Art filenames, sizes, style (for ChatGPT); top-down view
│  ├─ [x] graphics-spec-iso.md     Isometric view art: camera, canvas, anchors, facings
│  ├─ [x] art-templates/           iso-template-1x1/2x2/3x3.png diamond guides for artists
│  └─ features/             One short note per feature (see list below)
│     ├─ [x] _TEMPLATE.md   Copy this to start a new feature note
│     ├─ [x] balance.md     Pacing targets, formulas, timeline, tuning knobs
│     ├─ [x] core-api.md    What the App calls in Core (load, tick, commands, placement, save)
│     ├─ [x] economy.md     Production, caps, housing, survivor arrival, auto-staffing
│     ├─ [x] construction.md  Place/move/demolish, placement rules, the map
│     ├─ [x] save.md        Versioned save JSON + migrations; save file + autosave
│     ├─ [x] rendering-art.md  SpriteKit scene, ArtRegistry/placeholders, node factories
│     ├─ [x] zombie-walk-mixamo.md  ZWALK-1M: approved stock Mixamo route; waiting for source FBX
│     ├─ [x] zombie-walk-animation.md  ZWALK-1: realistic walker limb prototype + remaining checks
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
│  ├─ [x] presentation.json Views (isometric + top-down): tile sizes, art folders, zoom, placeholder heights (App only)
│  └─ maps/
│     └─ [x] phase1_exit.json  The highway-exit starting map (40×30, highway on the north edge)
├─ Core/                    Swift package HoldoutCore: pure simulation, Foundation only
│  ├─ [x] Package.swift     iOS 17 / macOS 14, Swift 6; `cd Core && swift test`
│  ├─ Sources/HoldoutCore/
│  │  ├─ Model/             Plain saved data
│  │  │  ├─ [x] GameState.swift   Clock, speed, random, group, bases
│  │  │  ├─ [x] NewGame.swift     Fresh game: starting resources + starting layout
│  │  │  ├─ [x] Base.swift        One town: map id, buildings, stock (food/scrap)
│  │  │  ├─ [x] Group.swift       Survivors + Knowledge (carries to future bases)
│  │  │  ├─ [x] Building.swift    A placed building: level, origin, build progress, staffed
│  │  │  └─ [x] GridPoint.swift   Tile x/y (y down) + footprint tiles
│  │  ├─ Simulation/
│  │  │  ├─ [x] GameLoop.swift    Fixed tick, commands, placement checks: the App's entry point
│  │  │  ├─ [x] Command.swift     Player actions in, outcomes/errors out
│  │  │  └─ [x] SeededRandom.swift  Deterministic random (SplitMix64), saved
│  │  ├─ Presentation/      [x] GridProjection.swift (tile ↔ screen), Facing.swift (facing image choice) — App only
│  │  ├─ Model/ (1B)        [x] Zombie.swift, HordeState.swift (+ ActiveHorde); Simulation/SimEvent.swift (events for drawing)
│  │  ├─ Content/           ContentLoader + Codable definitions matching Content/*.json (+ PresentationDefs.swift)
│  │  │  ├─ [x] ContentLoader.swift / ContentValidator.swift / GameContent.swift
│  │  │  ├─ [x] ResourceDefs.swift (+ Cost) / BuildingDefs.swift / MapDef.swift / EconomyDefs.swift
│  │  │  └─ [x] UnitDefs / ZombieDefs / HordeDefs / ResearchDefs / OfflineDefs.swift  (decoded now, used 1B–1D)
│  │  ├─ Systems/           One folder per game system:
│  │  │  ├─ Economy/        [x] EconomySystem, StorageRules, Staffing, ResourceSnapshot
│  │  │  ├─ Construction/   [x] PlacementRules, ConstructionSystem (place/move/demolish, build timers)
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
│     ├─ [x] Presentation/GridProjectionTests.swift, FacingTests.swift
│     ├─ [x] Systems/Pathing/FlowFieldTests.swift · Systems/Combat/{ZombieMovement,TargetingSystem,TowerFiring}Tests.swift (+ CombatTestSupport)
│     ├─ [x] Systems/Hordes/{HordeSystem,HordeComposer,HordeResolution}Tests.swift · Systems/Construction/RepairSystemTests.swift
│     ├─ [x] Content/ContentFilesTests.swift · Simulation/GameLoopTests.swift · Save/SaveCodecTests.swift
│     └─ [x] Systems/Economy/EconomySystemTests.swift · Systems/Construction/PlacementRulesTests.swift, ConstructionSystemTests.swift
├─ [x] HighwayHoldout.xcodeproj  App project (created once, D-014). Never edit project.pbxproj.
├─ App/                     App target HighwayHoldout (iOS, synced folder: new files need no project edit)
│  ├─ [x] HighwayHoldoutApp.swift  App entry point; saves when the app leaves the foreground
│  ├─ [x] GameStore.swift   @Observable bridge: loads content + save, owns Core GameLoop, ticks it, sends Commands
│  ├─ Rendering/            SpriteKit
│  │  ├─ [x] GameScene.swift      SKScene hosted in SpriteView; syncs nodes to Core state; gestures
│  │  ├─ [x] ArtRegistry.swift    art id → texture/UIImage; labeled colored placeholder if image missing
│  │  ├─ [x] GridGeometry.swift   CoreGraphics wrapper around Core's GridProjection for the active view
│  │  ├─ [x] ArtStyle.swift       active view: geometry, art folder, placeholder heights, per-image fixes
│  │  ├─ [x] PlaceholderArt.swift flat labeled boxes (top-down) and 3D blocks/diamonds (isometric)
│  │  ├─ [x] DepthSort.swift      ZLayer draw order; front-to-back sorting
│  │  ├─ [x] DirectionalSprite.swift  facing images (_se, _ne, … + mirroring) or rotate one image
│  │  ├─ [x] ViewSwitcher.swift   fade between isometric and top-down, keep the spot centered
│  │  ├─ [x] ZombieLayer.swift    one node per Core zombie, synced every frame
│  │  ├─ [x] EventPlayer.swift    Core events → effects (capped), remembers tower aim
│  │  ├─ [x] HordeWarningOverlay.swift  warning arrows + edge highlight at warned spawn edges
│  │  └─ Nodes/                   One factory per entity type:
│  │     ├─ [x] TerrainNodeFactory.swift   ground tiles + decorations; ZLayer draw order
│  │     ├─ [x] BuildingNodeFactory.swift  buildings; scaffolding, rubble, health bar; defenses → DefenseNodeFactory
│  │     ├─ [x] DefenseNodeFactory.swift   walls turned to their line, flat traps, aiming turret tops
│  │     ├─ [x] ZombieNodeFactory.swift    zombie facing image, bob, health bar, hit flash, crowd spread
│  │     ├─ [x] FXNodeFactory.swift        tracer, muzzle flash, goo, dust, shake, trap flash
│  │     ├─ [x] BarNodeFactory.swift       small progress / health bars
│  │     ├─ [x] GhostNodeFactory.swift     placement ghost (green/red tile polygons), selection outline, range ring
│  │     └─ [ ] UnitNodeFactory.swift      survivors/defenders (1C)
│  ├─ Input/
│  │  ├─ [x] CameraController.swift     Pan/pinch-zoom, bounds
│  │  ├─ [x] PlacementController.swift  Mode (select/place/move), ghost spot, validity, Confirm command
│  │  ├─ [x] HitTesting.swift           isometric taps: front-most drawn building, else ground tile
│  │  └─ [x] PlacementMessages.swift    Core placement problems/errors → player text
│  ├─ UI/                   SwiftUI
│  │  ├─ [x] GameRootView.swift  SpriteView + overlays, view toggle button, ArtIcon, notice banner, load-error screen
│  │  ├─ [x] HUDView.swift / BuildMenuView.swift / PlacementBarView.swift (Confirm/Cancel; Move/Demolish)
│  │  ├─ [x] KitStyle.swift      UI kit look: colors, panels, buttons, glyphs, icon buttons
│  │  ├─ [x] HordeChipView.swift / HordeBannerView.swift  day + countdown chip; start/held/HQ-fell banners
│  │  ├─ [x] DebugMenuView.swift  DEBUG only (long-press horde chip): horde now, +500, kill all
│  │  ├─ [ ] SettingsView.swift         (1D)
│  │  └─ [ ] WelcomeBackView.swift      Summary after Time-factor catch-up (1D)
│  ├─ Platform/
│  │  ├─ [x] SaveFileStore.swift        Read/write Application Support/HighwayHoldout/save.json
│  │  ├─ [ ] NotificationScheduler.swift  Horde Alert local notifications (1D)
│  │  └─ [x] AppLifecycle.swift         Save on leaving foreground + every economy.json autosaveSeconds
│  ├─ AppIconLayers/        app_icon_bg/fg layers (written by tools/import_art.py)
│  └─ Assets.xcassets/      AppIcon + Art/{TopDown,Iso,UI}/ sprites (written by tools/import_art.py --view; don't hand-edit)
├─ HighwayHoldoutAssets/    ChatGPT's top-down art pack (source PNGs in png/). ChatGPT owns it; don't edit.
├─ HighwayHoldout_UI_Kit/   ChatGPT's UI kit (menu panels, buttons, glyphs, 3/4 build cards). Don't edit; import with --view ui.
├─ HighwayHoldout_Blender_Study/  3D art study (models + scripts) the isometric art is rendered from. Art team owns it.
├─ HighwayHoldout_Iso_Art/  Rendered isometric PNGs (tools/blender/render_iso_sprites.py); README says what's in it.
├─ HighwayHoldoutAssets_8bit/  Abandoned pixel-art experiment; not selected for the app.
├─ HighwayHoldout_Blender_Study/  Fresh 3D style study: editable .blend, models/, ten png/ samples, renders/, scripts/, QA and Claude handoff.
├─ HighwayHoldout_Blender_Study.zip  Shareable Blender study and sample assets.
└─ tools/
   ├─ [x] import_art.py     PNGs → imagesets: --view topdown (trimmed), iso (untrimmed), ui (UI kit as-is)
   └─ blender/
      ├─ [x] render_iso_sprites.py  Blender script: renders isometric sprites + ground tiles
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

- Zombie detail pass: `tools/blender/zombie_details.py` supplies faces, costumes and materials to `tools/blender/zombie_models.py`; `HighwayHoldout_Iso_Art/zombie-review/` contains original sprites and `comparison.png`.

- Realistic walker pilot: `HighwayHoldout_Iso_Art/realistic-walker/` contains `source/`, `png/`, `previous/`, `prepare.py`, `PROMPTS.md`, `README.md`, `preview.png`, and simulator review captures. Reapply its sprites after old Blender renders.
- `docs/BUILD-QUEUE.md`: dependency-labelled chunks and paste-ready next-chat handoffs.

- Walker limb animation: `HighwayHoldout_Iso_Art/walker-walk/{source/,png/,prepare.py,preview.gif,in-game.png,PROMPTS.md,README.md}`; twelve `_w0…_w5.imageset` entries under `App/Assets.xcassets/Art/Iso/`. Runtime in `ZombieNodeFactory.swift` + `ArtRegistry.swift`; configuration in `Content/presentation.json` and `PresentationDefs.swift`.

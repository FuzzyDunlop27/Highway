# Feature: Rendering & art

> **2D retired (D-030, 2026-11-01).** The SpriteKit isometric/top-down views, their sprites and the 2D projection math are gone. The map is real 3D with RealityKit (D-027). This note's history before 2026-11-01 lives in git (`git log -- docs/features/rendering-art.md`).

## Purpose
Draws the map, decorations, buildings and zombies in real 3D (RealityKit `RealityView`, virtual camera, iOS 18+). Real models where a `<artId>.usdz` exists, otherwise a labeled colored box. Menus and the HUD stay SwiftUI with UI-kit PNGs.

## Files involved
- `App/GameTicker.swift` — the game clock: a `CADisplayLink` that calls `GameStore.advance` every screen frame and buffers Core's `SimEvent`s; `drainEvents()` hands them to the 3D view. Pauses while `store.isClockPaused` (the DEBUG 1R spike covering the game).
- `App/Rendering/Reality3DView.swift` — SwiftUI host: background color, `RealityView` (`content.camera = .virtual`), per-frame `SceneEvents.Update` → `World3D.update`, and the touch layer.
- `App/Rendering/World3D.swift` — the scene: camera entity, dusk sun (+ shadows) and fill light, ground, decorations, building and zombie layers; each frame finishes the camera turn, applies the camera, syncs to Core. Starts centered on the HQ.
- `App/Rendering/GroundMesh3D.swift` — **one merged ground mesh** for the whole map (one part per tile art id × checker parity), plus the map's decorations; `Reality3DSizes` (placeholder heights, Core point → simd).
- `App/Rendering/GroundTextures3D.swift` — repeating Poly Haven photo textures for ground tiles (`reality3d.groundTextures`); loads each image once from `App/Textures/Ground/` (1024 px JPGs, CC0); a missing image → the flat tile color.
- `App/Rendering/BuildingLayer3D.swift` — one entity per building; rebuilt only when its `Signature` changes (def, level, origin, finished, rubble, wall direction). Picks the art id: finished → `sprite`, building (2×2+) → `constructionSprites`, building (1×1) → own art faded, rubble → `rubbleSprite1x1/2x2`. Walls in a north-south line turn 90°. `pickBoxes` gives one footprint box per building for taps and fading.
- `App/Rendering/PlacementLayer3D.swift`, `SelectionLayer3D.swift`, `OccluderFader3D.swift`, `OverlayMeshes3D.swift` — placement ghost, grid, footprint, wall line, selection outline, range ring, fading in front of the ghost (chunk 3R; rules in `input.md`). Overlays are unlit, see-through merged meshes just above the ground that cast no shadow.
- `App/Rendering/EffectsLayer3D.swift` + `EffectMeshes3D.swift` — Core's `SimEvent`s as short effects (4R): tower/defender tracers, muzzle flash, goo splat where a zombie died, dust cloud when a building falls, white flash on a trap, short shake of a hit building. Same caps as the old 2D EventPlayer: 60 goo splats (oldest goes), 80 air effects (extra skipped).
- `App/Rendering/TurretLayer3D.swift` — the aiming top of each finished tower (`buildings.json turretSprite`: `def_watchtower_gunner`, `def_mg_nest_gun`), hung under the tower's entity; turns toward each target (capped turn speed), keeps its aim between shots; tracers start at its `muzzle` marker.
- `App/Rendering/BarsLayer3D.swift` — floating bars above roofs: green progress while building/repairing, health (green > 60 %, amber > 30 %, red) when damaged; turned like the camera so they lie flat on the screen.
- `App/Rendering/HordeWarning3D.swift` — during the warning time (`hordes.json warningSeconds`): warned spawn-edge tiles glow red and a pulsing red arrow lies on the ground inside each, pointing at the map middle.
- `App/Rendering/ZombieLayer3D.swift` — one animated zombie per zombie (3M: glide, turn, walk/attack/idle; see `characters-3d.md`); small fixed crowd spread per zombie id.
- `App/Rendering/ModelRegistry.swift` — art id → entity. Returns at once with a box (footprint × height, art id written above it, always facing the camera); loads `<artId>.usdz` from the app bundle in the background (`Entity(contentsOf:)`) and swaps the box for the model in every entity still showing it. Missing or broken file → the box stays. Never crashes.
- `App/Rendering/ArtRegistry.swift` — 2D pictures for SwiftUI only: HUD icons (`Art/UI`) and build-menu pictures (`Art/UI` `ui_build_<id>`, else `Art/Menu/<sprite>`); `UIColor.hex`, `ArtCategory`.
- `App/Rendering/PlaceholderArt.swift` — labeled flat box picture for missing menu art; `color(for:)` = one color per art-id prefix, also used for the 3D boxes and ground.
- `App/Input/OrbitGestures3D.swift` — camera touches (see `input.md`).
- `Core/Sources/HoldoutCore/Presentation/WorldMapping3D.swift` — tile ↔ world metres (tested).
- `Core/Sources/HoldoutCore/Presentation/OrbitCamera3D.swift` — camera math: pan, zoom toward a point, tilt, snapped eased turns, limits (tested).
- `Core/Sources/HoldoutCore/Content/PresentationDefs.swift` — Codable for `Content/presentation.json`.
- `App/Assets.xcassets/Art/UI/` (UI kit, `tools/import_art.py --view ui`) and `Art/Menu/` (8 old isometric building pictures kept only for build-menu cards without a `ui_build_` card).
- `App/Spike3D/` — the DEBUG 1R spike (reference). Its `Models/*.usdz` are in the bundle, so `ModelRegistry` already shows them for HQ, shelter, farm, watchtower base, wood wall and car wreck.
- Tests: `Core/Tests/HoldoutCoreTests/Presentation/{WorldMapping3D,OrbitCamera3D}Tests.swift`, `Content/ContentFilesTests.swift`.

## Data files
- `Content/presentation.json` → `outsideMapColor`; `reality3d`: `metresPerTile`, `loadModels`, `placeholderHeightTiles` (per building category + `decoration`, `default`), `zombieBoxTiles`, `camera` (see `input.md`), `light` (sun elevation/azimuth/lux/color, fill lux/color, shadows on/off, shadow distance/bias), `groundTextures` (tile art id → image `file`, `repeatTiles`, `tint`; optional).
- `Content/maps/*.json` → `legend[*].tile` (ground colors by art id), `decorations` (id + footprint).
- `Content/buildings.json` → `sprite`, `footprint`, `category` (box height), `rules.constructionSprites`, `rules.rubble.*`.
- `Content/zombies.json` → `sprite` (zombie art id).

## Key rules
- World axes: **1 tile = `metresPerTile` m (1)**, +X = east, +Y = up, +Z = south (−Z = north; Blender +Y), map middle at the origin. Every position goes through `WorldMapping3D`.
- Models: one USDZ per art id named exactly like the art id (`bld_hq.usdz`), origin at the footprint's ground middle, front facing +X; scaled by `metresPerTile`. Zombie heading → `WorldMapping3D.yaw(heading:)` = −heading.
- Placeholder box = footprint (minus a small gap) × `placeholderHeightTiles[category]` tiles, colored by art-id prefix (`PlaceholderArt.color`), art id written above it (billboard, no shadow). Ground tiles aren't labeled.
- The renderer never changes game state. Clock = `GameTicker`; `World3D.update` drains Core events each frame and plays them **before** the layers sync, so a zombie that died this frame is still drawn where it fell.
- Effects age in real seconds; all their sizes, times and caps are look-only constants in `EffectsLayer3D` / `EffectMeshes3D` (not game tuning, so not JSON). Effects are unlit, see-through and cast no shadow; meshes/materials are shared.
- Turret models follow the 2M model rule (origin at the footprint's ground middle, built at their height on the tower) with the gun along +X and an empty named `muzzle` at the barrel tip. Missing turret model → labeled box sitting on the tower's box (`ModelRegistry.entity(lift:)`).
- `ModelRegistry` swaps only a container's direct `placeholder` child (a tower also holds its turret's placeholder).
- Characters: `characters-3d.md`.
- Look-only constants (box gap, label size/lift, faded opacity, checker, crowd spread) are named constants in the files above, not JSON.

## Known issues
- Models take a few seconds to load in the simulator; boxes show meanwhile (intended).
- No fps readout in the game since SpriteKit's went away; the 1R spike still has one. Add one with 5R's performance pass.

## Change log
- 2026-11-01 — Ground textures (owner request, D-043): grass, dirt, concrete and asphalt tiles use Poly Haven photo textures (`GroundTextures3D`, UVs in tiles on the merged mesh); `presentation.json reality3d.groundTextures`. Checked in the simulator.
- 2026-11-01 — Chunk 4R: effects (tracers, muzzle flash, goo, dust, trap flash, shake), health/progress bars, aiming turrets, horde warning arrows (D-039). Checked in the simulator; day-40 horde ~59–60 fps.
- 2026-11-01 — Chunk 3M: animated zombies, gliding between ticks, runner/brute variants (`characters-3d.md`, D-038).
- 2026-11-01 — Chunk 3R: placement/selection overlays (`PlacementLayer3D`, `SelectionLayer3D`, `OccluderFader3D`, `OverlayMeshes3D`); `BuildingLayer3D.pickBoxes`.
- 2026-11-01 — 2D retired (D-030): SpriteKit scene, node factories, iso/top-down sprites, GridProjection/Facing, view toggle removed; 3D files moved into `App/Rendering/`; 8 menu pictures kept in `Art/Menu`.
- 2026-11-01 — Chunk 2R: RealityKit 3D view (merged ground, labeled boxes, background model loading, buildings/zombies synced), shared `GameTicker`, `WorldMapping3D` + `OrbitCamera3D` in Core with tests.
- 2026-11-01 — 2M: real models now load from `App/Models/` (see `models-3d.md`); the 1R spike's study USDZ were removed.

# Feature: Rendering & art

## Purpose
Draws the map, decorations, and buildings with SpriteKit in two views: **isometric** (normal, Tropico style) and **top-down** (building view). Real art where it exists for that view; otherwise a labeled placeholder (3D block in iso, flat box top-down).

## Files involved
- `HighwayHoldout_Blender_Study/` — original 3D art-direction study, editable Blender scene/model libraries and ten transparent sprite samples; not installed into the app.
- `Core/Sources/HoldoutCore/Presentation/GridProjection.swift` — pure tile ↔ screen math for both views (tested in Core; the simulation never uses it, D-016).
- `Core/Sources/HoldoutCore/Content/PresentationDefs.swift` — Codable for `Content/presentation.json`.
- `App/Rendering/GameScene.swift` — the SpriteKit scene: calls `GameStore.advance` every frame, switches view when `GameStore.activeView` changes, syncs nodes to Core state; owns the touch gestures.
- `App/Rendering/ViewSwitcher.swift` — fade out, rebuild the world in the other view, keep the same map spot centered, fade in.
- `App/Rendering/ArtStyle.swift` — the active view: geometry, art folder (`Iso` / `TopDown`), placeholder heights, per-image fixes.
- `App/Rendering/GridGeometry.swift` — CoreGraphics wrapper around `GridProjection` (points, outlines, depth, footprint sizes).
- `App/Rendering/ArtRegistry.swift` — art id → sprite sized/anchored for the view, or a placeholder; SwiftUI icons from `Art/UI`. Never crashes.
- `App/Rendering/PlaceholderArt.swift` — draws flat labeled boxes and isometric blocks/diamonds.
- `App/Rendering/DepthSort.swift` — `ZLayer` draw order (ground, sorted upright things, selection, ghost).
- `App/Rendering/DirectionalSprite.swift` — picks facing images (`_se`, `_ne`, … with mirroring) or rotates one image.
- `App/Rendering/Nodes/TerrainNodeFactory.swift` — ground tiles + decorations.
- `App/Rendering/Nodes/BuildingNodeFactory.swift` — one building/defense: sprite (+ turret top), or scaffolding + progress bar.
- `App/Rendering/Nodes/GhostNodeFactory.swift` — placement ghost (projected tile polygons) and the selection outline.
- `App/Assets.xcassets/Art/{TopDown,Iso,UI}/` — namespaced imagesets written by `tools/import_art.py --view` (don't hand-edit).
- `docs/graphics-spec-iso.md` + `docs/art-templates/iso-template-*.png` — how to draw isometric art.
- `tools/blender/render_iso_sprites.py` + `tools/blender/extra_models.py` — render the iso art from the Blender study's models (+ stand-ins) into `HighwayHoldout_Iso_Art/png/` (see its README).
- Tests: `Core/Tests/HoldoutCoreTests/Presentation/GridProjectionTests.swift`.

## Data files
- `Content/maps/phase1_exit.json` → `legend[*].tile` (ground art id per tile), `decorations` (id + footprint).
- `Content/buildings.json` → `sprite`, `turretSprite`, `footprint`, `category` (placeholder height), `rules.constructionSprites` (`"WxH"` → scaffold art).
- `Content/presentation.json` → `defaultView`, `autoTopDownWhilePlacing`, `switchFadeSeconds`, `outsideMapColor`; per view: `tileWidthPt/tileHeightPt`, `artNamespace`, `facings`, `turretFacings`, `minScale/startScale`, `placeholderHeightTiles`, `assets.<id>` (`anchor`, `scale`, `mirrorable`).

## Key rules
- The simulation is one square grid; views only change drawing. Every position comes from `GridGeometry` (never assume top-down).
- Top-down: sprite = footprint rectangle, anchored at its middle. Isometric: sprite is as wide as the footprint diamond, any height, anchored at the diamond's bottom point (`[0.5, 1.0]` from the image's top-left unless `assets.<id>.anchor` says otherwise).
- Upright things (buildings, decorations, later units/zombies) use `ZLayer.sorted(depth:)`; depth = footprint middle's `x + y` in iso (bigger = in front). Ground stays flat underneath.
- Each view only uses its own art folder; missing art falls back to that view's placeholder, never to the other view's image.
- Isometric ground-tile placeholders are unlabeled colored diamonds (1,200 labels are noise); every other placeholder carries its id.
- In iso, turret tops need facing images (`def_watchtower_gunner_se`, …); without them the tower block stands alone.
- To swap in art: `python3 tools/import_art.py <folder> --view topdown|iso`. No code change.
- Nodes are rebuilt only when a building's def/level/origin/finished state changes or the view switches; progress bars update every frame.

## Known issues
- Isometric art is rendered from the Blender study (D-019). Still blocks: metal wall, MG nest, spikes, barbed wire, runner, brute (1B).
- Wood walls are one model facing one way; walls in a north-south line will look sideways until a rotated wall image exists (1B).
- Iso sorting uses footprint middles: right for non-overlapping footprints up to 3×3; a zombie walking right behind a tall HQ can be hidden (planned: fade that building, 1B).
- The view toggle uses SF Symbols (not art) for now.
- `import_art.py` makes a 1×1 tile 96 px at @3x, so art is crisp at camera scale 1 and a little soft when zoomed in to the max (scale 0.5).
- `import_art.py` trims and refits sprites; the ChatGPT hand-off note asks not to trim (keeps unit pivots consistent). Matters for 1B units; see STATUS open questions.

## Change log
- 2026-10-31 — Real isometric art rendered from the Blender study (+ stand-in models, darker ground tiles); isometric view no longer shows blocks for 1A buildings.
- 2026-10-31 — 1V: two views (isometric + top-down), presentation.json, projection math in Core, depth sorting, iso placeholder blocks, view switching, namespaced art import.
- 2026-10-31 — Owner abandoned the 8-bit variant; created a fresh Blender miniature-style study and ten PNG samples (40 image checks passed). App artwork remains unchanged.
- 2026-10-31 — Created (1A App half): scene, ArtRegistry with generated placeholders, terrain/building/ghost factories.

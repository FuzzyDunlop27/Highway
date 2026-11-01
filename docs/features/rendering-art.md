# Feature: Rendering & art

> **Approved direction, implementation pending (D-022):** improve isometric placement with a ground grid, clear footprint/validity feedback, draggable preview and temporary occluder fading. Once verified on iPhone, disable auto-top-down switching; keep the manual top-down fallback during testing. Existing behavior described below is unchanged in code. See `docs/PHASE1-TASKS.md` → Approved update — isometric placement first.

## Purpose
Draws the map, decorations, buildings, defenses, zombies, and combat effects with SpriteKit in two views: **isometric** (normal, Tropico style) and **top-down** (building view). Real art where it exists for that view; otherwise a labeled placeholder (3D block in iso, flat box top-down).

## Files involved
- `HighwayHoldout_Iso_Art/realistic-walker/` — realistic static walker sources, exact prompts, reproducible canvas fitting, production PNGs, previous sprites and review images.
- `tools/blender/zombie_details.py` — zombie facial sculpt, costume details and local surface materials; composed by `zombie_models.py`.
- `HighwayHoldout_Iso_Art/zombie-review/` — before sprites and comparison of the first zombie detail pass.
- `HighwayHoldout_Blender_Study/` — original 3D art-direction study, editable Blender scene/model libraries and ten transparent sprite samples; not installed into the app.
- `Core/Sources/HoldoutCore/Presentation/GridProjection.swift` — pure tile ↔ screen math for both views (tested in Core; the simulation never uses it, D-016).
- `Core/Sources/HoldoutCore/Content/PresentationDefs.swift` — Codable for `Content/presentation.json`.
- `App/Rendering/GameScene.swift` — the SpriteKit scene: calls `GameStore.advance` every frame (which returns that frame's `SimEvent`s), switches view when `GameStore.activeView` changes, syncs buildings/zombies/warnings/selection to Core state, hands events to `EventPlayer`; owns the touch gestures.
- `App/Rendering/ZombieLayer.swift` — one `ZombieNode` per zombie in `loop.state.base.zombies`: adds, moves every frame, removes.
- `App/Rendering/EventPlayer.swift` — `SimEvent`s → effects (shot: tracer + muzzle flash + zombie flash + turret aim; died: goo; damaged: shake; destroyed: dust; trap hit: flashes). Caps effect counts; remembers each tower's last aim.
- `App/Rendering/HordeWarningOverlay.swift` — pulsing red arrows + tile highlight at the warned spawn edges (`map.spawnEdges`, `hordeStatus.warningEdges`).
- `App/Rendering/ViewSwitcher.swift` — fade out, rebuild the world in the other view, keep the same map spot centered, fade in.
- `App/Rendering/ArtStyle.swift` — the active view: geometry, art folder (`Iso` / `TopDown`), placeholder heights, per-image fixes.
- `App/Rendering/GridGeometry.swift` — CoreGraphics wrapper around `GridProjection` (points, outlines, depth, footprint sizes).
- `App/Rendering/ArtRegistry.swift` — art id → sprite sized/anchored for the view, or a placeholder; SwiftUI icons from `Art/UI`. Never crashes.
- `App/Rendering/PlaceholderArt.swift` — draws flat labeled boxes and isometric blocks/diamonds.
- `App/Rendering/DepthSort.swift` — `ZLayer` draw order (ground, sorted upright things, selection, ghost).
- `App/Rendering/DirectionalSprite.swift` — picks facing images (`_se`, `_ne`, … with mirroring) or rotates one image.
- `App/Rendering/Nodes/TerrainNodeFactory.swift` — ground tiles + decorations.
- `App/Rendering/Nodes/BuildingNodeFactory.swift` — one building: sprite, scaffolding + progress bar, rubble, health bar when damaged; finished defenses go to `DefenseNodeFactory`.
- `App/Rendering/Nodes/DefenseNodeFactory.swift` — walls (mirrored in iso for a north-south line), flat traps, towers (base + turret top that aims; faded when unstaffed), muzzle point.
- `App/Rendering/Nodes/ZombieNodeFactory.swift` — `ZombieNode`: facing sprite, shamble walk cycle (hop + lean, step rate from zombie speed, stops while attacking), health bar when hurt, hit flash.
- `App/Rendering/Nodes/FXNodeFactory.swift` — tracer, muzzle flash, goo splat, dust puff, building shake, trap flash (each removes itself).
- `App/Rendering/Nodes/BarNodeFactory.swift` — the small progress/health bars.
- `App/Rendering/Nodes/GhostNodeFactory.swift` — placement ghost (projected tile polygons), the selection outline, and the range ring (projected circle) of a selected tower/HQ.
- `App/Assets.xcassets/Art/{TopDown,Iso,UI}/` — namespaced imagesets written by `tools/import_art.py --view` (don't hand-edit).
- `docs/graphics-spec-iso.md` + `docs/art-templates/iso-template-*.png` — how to draw isometric art.
- `tools/blender/render_iso_sprites.py` + `tools/blender/extra_models.py` — render the iso art from the Blender study's models (+ stand-ins) into `HighwayHoldout_Iso_Art/png/` (see its README).
- Tests: `Core/Tests/HoldoutCoreTests/Presentation/GridProjectionTests.swift`.

## Data files
- `Content/maps/phase1_exit.json` → `legend[*].tile` (ground art id per tile), `decorations` (id + footprint).
- `Content/buildings.json` → `sprite`, `turretSprite`, `footprint`, `category` (placeholder height; `wall`/`tower`/`trap` = drawn by DefenseNodeFactory), `levels[].hp` (health bar), `levels[].effects.range` (range ring), `rules.constructionSprites` (`"WxH"` → scaffold art), `rules.rubble.rubbleSprite2x2` / `rubbleSprite1x1`.
- `Content/zombies.json` → `sprite` (facing images `<sprite>_se` / `_ne`), `hp` (health bar).
- `Content/maps/*.json` → `spawnEdges` (warning arrows).
- `Content/presentation.json` → `defaultView`, `autoTopDownWhilePlacing`, `switchFadeSeconds`, `outsideMapColor`; per view: `tileWidthPt/tileHeightPt`, `artNamespace`, `facings`, `turretFacings`, `minScale/startScale`, `placeholderHeightTiles`, `assets.<id>` (`anchor`, `scale`, `mirrorable`).

## Key rules
- Current walker: D-026 / ZWALK-1M uses `walker-mixamo/png/` for twelve walk frames and matching SE/NE stills; re-import that folder after full old Blender renders. `realistic-walker/` and `walker-walk/` are historical recovery sources. Existing mirroring supplies SW/NW. See `zombie-walk-mixamo.md` for evidence and pending acceptance.
- The simulation is one square grid; views only change drawing. Every position comes from `GridGeometry` (never assume top-down).
- Top-down: sprite = footprint rectangle, anchored at its middle. Isometric: sprite is as wide as the footprint diamond, any height, anchored at the diamond's bottom point (`[0.5, 1.0]` from the image's top-left unless `assets.<id>.anchor` says otherwise).
- Upright things (buildings, decorations, later units/zombies) use `ZLayer.sorted(depth:)`; depth = footprint middle's `x + y` in iso (bigger = in front). Ground stays flat underneath.
- Each view only uses its own art folder; missing art falls back to that view's placeholder, never to the other view's image.
- Isometric ground-tile placeholders are unlabeled colored diamonds (1,200 labels are noise); every other placeholder carries its id.
- In iso, turret tops need facing images (`def_watchtower_gunner_se`, …); without them the tower block stands alone.
- To swap in art: `python3 tools/import_art.py <folder> --view topdown|iso`. No code change.
- Nodes are rebuilt only when a building's `Signature` changes (def, level, origin, finished, rubble, health in tenths, defense variant) or the view switches; progress bars update every frame.
- Zombies stand at `GridGeometry.standingAnchor` (iso: bottom corner of a 1×1 diamond centered on them), sorted by `depth(gx:gy:)`. Facing = screen angle of the grid heading (`GridGeometry.screenAngle`) → `DirectionalSprite`; a missing facing image falls back to the base image, then a placeholder.
- Walls: iso wall art is drawn for a line along x; a wall with more wall neighbors at y±1 than at x±1 is mirrored left-right. Top-down walls are not turned.
- Finished traps lie flat at `ZLayer.trap`; goo at `ZLayer.decal`; tracers/flashes/dust/arrows at `ZLayer.effects`.
- Turret tops face their last target (from `.shot`); idle: right top-down, lower right iso. Unstaffed towers show the turret faded.
- Effect art (`fx_*`) exists only top-down; both views use it (`ArtRegistry.effectTexture`); goo is squashed to half height in iso.
- Effect counts are capped (`EventPlayer`: 60 goo, oldest removed; 80 tracers/flashes/dust, extras skipped); building shakes and flashes don't restart while playing. Look-only numbers (bob, flash times, bar sizes) are named constants in the factories, not JSON (they are not game tuning).

## Known issues
- Isometric art for metal wall, MG nest, spikes, barbed wire, runner, brute is being rendered (1B); until imported they are labeled blocks.
- If a wall render faces the other way, north-south and east-west lines swap; flip the rule in `DefenseNodeFactory.addParts` (or set `mirrorable: false`).
- Iso sorting uses footprint middles: right for non-overlapping footprints up to 3×3; a zombie walking right behind a tall HQ can be hidden (fading that building is not built yet).
- A building under repair shows scaffolding + progress (same as construction).
- The view toggle uses SF Symbols (not art) for now.
- `import_art.py` makes a 1×1 tile 96 px at @3x, so art is crisp at camera scale 1 and a little soft when zoomed in to the max (scale 0.5).
- `import_art.py` trims and refits sprites; the ChatGPT hand-off note asks not to trim (keeps unit pivots consistent). Matters for 1B units; see STATUS open questions.

## Change log
- 2026-10-31 — Integrated realistic static walker cutouts (SE/NE + base) using the existing importer and 256×232 canvas; left other types and procedural shamble unchanged. Sources and prompt history retained in `realistic-walker/`.
- 2026-10-31 — Refined all three zombie models with facial features, weathered costume details and distinct roadside/athletic/workwear styling; rendered and imported nine iso sprites. Existing poses, facing rules and gameplay preserved.
- 2026-10-31 — Recorded owner-approved isometric placement direction and staged rollout (D-022); documentation only, implementation pending.
- 2026-10-31 — 1B App: zombies (facings, bob, health bar, hit flash), defenses (wall direction, flat traps, aiming turrets, range ring), effects from SimEvents, rubble + building health bars, horde warning arrows.
- 2026-10-31 — Real isometric art rendered from the Blender study (+ stand-in models, darker ground tiles); isometric view no longer shows blocks for 1A buildings.
- 2026-10-31 — 1V: two views (isometric + top-down), presentation.json, projection math in Core, depth sorting, iso placeholder blocks, view switching, namespaced art import.
- 2026-10-31 — Owner abandoned the 8-bit variant; created a fresh Blender miniature-style study and ten PNG samples (40 image checks passed). App artwork remains unchanged.
- 2026-10-31 — Created (1A App half): scene, ArtRegistry with generated placeholders, terrain/building/ghost factories.
- 2026-10-31 — Zombies now shamble: a 4 pt hop and ±0.1 rad lean per step (was a barely visible 1.5 pt bob that never stopped); step time from `speed`; idle while bashing. Single sprite per facing, so it's a procedural walk; real frame animation would need new art.

- 2026-10-31 — ZWALK-1/chunk 2A prototype: realistic walker limb textures advance by distance; attack holds frame zero; still fallback retained. Frames use ArtRegistry cache and presentation.json zombieWalk; importer accepts `_wN`. See zombie-walk-animation.md for files and remaining gait checks.

- 2026-10-31 — ZWALK-1M replaced walker frames and directional stills with Mixamo Yaku J Ignite / Zombie Walk; existing rendering reused, stride measured in JSON; fixture verification recorded, normal-horde acceptance pending.

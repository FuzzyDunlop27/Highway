# Claude handoff — Blender art study

This folder is a new art-direction prototype, not the full production asset set. The owner abandoned the 8-bit variant and asked for something different using Blender. Ten representative original 3D models and PNG samples are delivered. The current app still uses its existing artwork.

## Start here

1. Review `renders/01_roadside_diorama.png` for the intended miniature look.
2. Review `renders/02_transparent_sprite_samples.png` for actual sprite views.
3. Read the repository's `AGENTS.md`, `docs/STATUS.md`, and `docs/features/rendering-art.md` before changing the game. Coordinate the art camera with the separately proposed switchable-view milestone.

Use the `.blend` source to produce assets in the final selected game projection. The hero diorama is not a screenshot of the running game.

## Sources

`HighwayHoldout_Blender_Study.blend` contains the full diorama and the model collections. Individual collection libraries are in `models/`. Models face world +X when a directional front is required. The meshes, materials and geometry are newly created; there are no external textures to relink.

The production geometry comes from:

- `scripts/geometry.py`: primitives, bevels, palette, collection helpers.
- `scripts/buildings.py`: station HQ, shelter, raised beds, crates and barrels.
- `scripts/props.py`: watchtower, wood wall, sedan and scene dressing.
- `scripts/characters.py`: survivor, defender/gunner and walker.
- `scripts/staging.py`: Cycles lights, cameras and diorama layout.
- `scripts/create_study.py`: assemble models, save `.blend`, render samples.
- `scripts/package_study.py`: exact-size PNGs and review/QA sheets.

## Current PNG conventions

The ten PNGs use existing snake_case ids. Sizes: HQ 384×384; shelter/farm 256×256; wreck 256×128; wall, tower layers and characters 128×128. Set their world size from the existing footprint × tile size. Keep each full transparent canvas.

Units, zombies, the wreck and tower layers use a pure overhead orthographic camera. Their zero-rotation facing is east. Tower base and top share a centered `(0.5, 0.5)` anchor; rotate only the top. Buildings and the wall use an orthographic camera 26.6° from vertical. The diorama uses a separate three-quarter camera.

Use linear filtering for these rendered sprites. Do not apply the abandoned pixel-art filtering rules. Do not trim/refit the supplied PNGs: it would alter the rotating-character pivots. `tools/import_art.py --dry-run` passed for these names, but its normal normalization is not suitable for preserving these finished canvases unchanged.

If the app adopts an isometric projection, rerender consistent views from the Blender source. Do not rotate a tall building's two-dimensional raster to simulate changing the camera. Select ground anchors, bounds and depth sorting to match the chosen projection before expanding this into a full set.

## Remaining art work

- Produce the remaining 47 assets if this style is chosen, and bring sample content into full spec coverage (for example, the farm greenhouse).
- Confirm the final camera, scale and ground anchors with the renderer.
- Evaluate contrast on real terrain and readability at actual phone zoom levels.
- Decide whether directional characters need separate render angles for a three-quarter game view.
- Create the complete catalog/app icon and perform app/device checks during integration.

The samples passed 40 PNG checks and a visual review. No game code, content tuning, project file or installed app artwork was changed to deliver this study.

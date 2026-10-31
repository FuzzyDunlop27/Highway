# Highway Holdout — Blender style study

A fresh 3D art direction, built and rendered in Blender 5.2.3 LTS. The scene uses original mesh models, solid materials, rounded edges, and soft Cycles lighting. It does not reuse the vector or pixel-pack geometry or images.

This is a **style study with ten sprite samples**, not a replacement for the full 57-asset pack. The game has not been changed. The 8-bit experiment was abandoned at the owner's request.

## See the result

- `renders/01_roadside_diorama.png` — the main 1600×1200 presentation render.
- `renders/02_transparent_sprite_samples.png` — the ten game-sized samples on review backgrounds.
- `renders/03_rotation_and_readability.png` — the tower/gunner overlay and 48px review.
- `HighwayHoldout_Blender_Study.blend` — the complete editable scene. Open in Blender and press F12 to render the active diorama camera. Camera view is available with Numpad 0.

## What is included

| Location | Contents |
|---|---|
| Main `.blend` | Roadside diorama, Cycles lighting, orthographic cameras, original material palette, model collections |
| `models/` | Ten standalone collection libraries; append their collections into another Blender file |
| `png/` | Ten transparent sRGB PNGs with original game filenames and exact master dimensions |
| `renders/*_2x.png` | Sprite renders at twice the specified master size |
| `scripts/` | Original procedural modeling and render code, plus image packaging/QA |
| `manifest.json` | Sample names, dimensions, camera conventions, centered anchors and hashes |
| `qa_report.json` | 40 passing image checks |
| `CLAUDE_HANDOFF.md` | What Claude can use and what still needs production work |

The samples are `bld_hq`, `bld_shelter`, `bld_farm`, `def_watchtower_base`, `def_watchtower_gunner`, `def_wall_wood`, `dec_car_wreck`, `unit_survivor`, `unit_defender`, and `zmb_walker`.

## Art direction

The new look is a handcrafted miniature roadside settlement: cream plaster, faded teal metal, coral roofs and pumps, warm wood, faceted plants, rounded defenders, and green/purple zombies. The presentation render includes a diorama base and cast shadows. The transparent sprite exports have no studio floor or separate ground shadow catcher; surface shading and shadows within each modeled object remain.

The diorama camera is a three-quarter view. The PNGs retain the earlier game's camera convention: buildings are near-overhead, while units, the wreck, and tower layers are directly overhead. These are separate camera tests. The reusable 3D source makes new isometric or three-quarter exports possible after the final game projection is selected.

Materials use a new, broader palette for the requested different style. The farm sample emphasizes raised garden beds; a greenhouse and the rest of the Phase 1 content are future production work if this direction is chosen.

## Editing

Open the main `.blend`. Each placement in the diorama instances a named model collection. To append a model elsewhere, use Blender's **File → Append**, open a file in `models/`, choose **Collection**, and select the asset's collection. The models use ordinary mesh geometry, curves and materials; no external textures or add-ons are required.

The main scenes are `01_ROADSIDE_DIORAMA` and `02_TRANSPARENT_SPRITE_STAGE`. The latter is a reusable light/camera stage; the export script inserts one collection at a time.

To rebuild with Blender installed at the standard macOS path:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --threads 8 --python scripts/create_study.py
python3 scripts/package_study.py
```

The packaging script requires Pillow and uses macOS Arial fonts for the review sheets. Blender itself supplies the modeling/rendering Python runtime. No dependency is added to the game.

Rebuilding overwrites generated models and images. Save manual Blender edits to a separate file if you want to keep them.

## Verification

Blender completed the diorama and all ten sprite renders. The ten exported PNGs pass 40 checks for exact dimensions, transparency, at least four pixels of padding and embedded sRGB profiles. The repo importer recognizes all ten filenames in dry-run mode. The main scene, sample sheet and tower overlay were visually inspected.

The existing importer trims and refits sprites, which changes intended pivots. This study has not been imported into the app, and no app build or gameplay test with these samples is claimed.

# Feature: 3D models (buildings, defenses, decorations)

_Chunk 2M. Characters (zombies, survivors, defenders) are chunk 3M: `characters-3d.md`._

## Purpose
Every building, defense, construction/rubble state and map decoration has a realistic 3D model, so the map no longer shows labeled boxes for them.

## Files involved
- `tools/blender/export_usdz.py` — runs every recipe, scales metres → tiles, shrinks textures, drops normal maps, writes `App/Models/<artId>.usdz`; `review=<folder>` renders one 4-angle picture per model
- `tools/blender/model_kit.py` — building blocks: Quaternius kit pieces (`piece`, `wall_ring`, `flat_roof`), Poly Haven props (`prop`, decimated), sandbags, simple textured shapes (`box`, `stake`, `coil`)
- `tools/blender/recipes_buildings.py` — HQ, shelter, farm, scavenger post, workshop, barracks, storage, construction sites, rubble
- `tools/blender/recipes_defenses.py` — wood/metal walls, chain-link fence, watchtower, MG nest, their aiming turrets (4R), spikes, barbed wire, car wreck, dead tree
- `tools/blender/recipes_dressing.py` — map dressing: fuel cache, supply crates, camp (picnic table + barrel stove), junk pile, weeds (grass + dandelions)
- `tools/blender/blend_parts.py` — takes single objects out of Poly Haven `.blend` downloads (fence panel, foliage); `cutout=True` gives foliage a plain diffuse + alpha material the USD exporter understands
- `tools/check_models.py` — lists art ids the content uses that have no model (exit 1 if a non-character one is missing)
- `App/Models/*.usdz` — the exported models (committed; loaded by `App/Rendering/ModelRegistry.swift`)
- Review sheets: `docs/plans/models-2m/<artId>.jpg`, in-game shot `docs/plans/models-2m/in-game.jpg`

## Sources (all CC0, D-036)
- Buildings: Quaternius Downtown City MegaKit modular pieces; props: Poly Haven models; plank/rust/corrugated/bark textures: Poly Haven.
- Raw downloads live in `HighwayHoldout_3D_Sources/free-assets/` (git-ignored, large). Poly Haven ones are in `polyhaven/items/`, `polyhaven/foliage/` and `polyhaven/textures/` (zips unpacked next to them); `model_kit.prop_folder` looks in all three. To rebuild on another Mac, download them again (list in `docs/research/free-assets.md`).

## Key rules
- Built in real metres, Blender Z-up, front towards -Y (south in the game), origin at the footprint's ground centre; exported at `TILES_PER_METRE` 0.41 (a 1.8 m person = the walker) because the game draws 1 model unit = 1 tile.
- Kit wall pieces are 2 m wide × 3 m tall, outside facing -Y; a few are 4 m (`WIDE_PIECES`). A 2×2 footprint gets a 4 × 4 m shell, the 3×3 HQ 6 × 6 m.
- Walls are modelled running along X; the game turns north–south walls itself.
- Textures 512 px, normal maps dropped, props decimated to ~1,500 triangles, sandbags ~200 (they come in dozens). Biggest model ~3 MB; all 19 ≈ 20 MB.
- A missing or broken model still shows the labeled box (ModelRegistry), never a crash.
- Turrets (`turretSprite`, 4R) are separate models the game turns about the footprint centre: gun along +X, built at its height on the tower, an empty named `muzzle` at the barrel tip. The watchtower has an open platform (no roof) so its gun is visible from the game camera (D-039).
- The chain-link wire stays see-through: its alpha texture is exported as USD opacity (blended, not cut out). Foliage `.blend` materials are too complex for the USD exporter (it wired the normal map in as colour), so `blend_parts` rebuilds them.
- Map dressing (`dec_*`) blocks building and zombies like every decoration (MapDef.decorationTiles), so it sits on the east side of the map, away from the town and from the tiles Core tests build on.
- Run: `/Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/export_usdz.py -- [only=bld_hq] [review=<folder>]`, then `python3 tools/check_models.py`.

## Known issues
- Kit windows lose their fake-interior shader and show pale glass.
- Building tiers (L2/L3) use the same model; upgrades don't change the look yet.
- Not yet measured on a real phone (simulator only).

## Change log
- 2026-11-01 — Owner's Poly Haven downloads (D-043): `def_wall_fence` (Chain Fence wall), map dressing `dec_fuel_cache`, `dec_supply_crates`, `dec_camp`, `dec_junk_pile`, `dec_weeds`; `blend_parts.py`; props found in `items/`/`foliage/` subfolders; review sheets + `in-game-polyhaven.jpg`. 27/27 models.
- 2026-11-01 — Chunk 4R: `def_watchtower_gunner` and `def_mg_nest_gun` turret models (with `muzzle` empties); watchtower roof removed; `check_models.py` counts `turretSprite` (21/21).
- 2026-11-01 — Chunk 2M: pipeline, 19 models, missing-model checker, review sheets (D-036, D-037).

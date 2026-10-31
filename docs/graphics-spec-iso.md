# Graphics Spec — Isometric view (for ChatGPT / Blender)

**What this is:** the game has two views (DECISIONS D-016). The **top-down** view (building mode) uses the art in `docs/graphics-spec-phase1.md`. The **isometric** view ("Tropico style", the normal view) uses the art described here. Same filenames, same palette and style rules (section 1–2 of the phase 1 spec); only the camera and canvas rules differ.
**Status:** until isometric art exists, the game draws labeled 3D blocks. Any file with the right name replaces its block; partial delivery is fine.
**Rendered so far:** every phase 1 building, defense (incl. MG nest gun facings), unit and zombie (walker, runner, brute), plus the ground tiles, all from Blender — see `HighwayHoldout_Iso_Art/README.md`. Still missing: fx_* (flat top-down effects are reused) and vehicles.

---

## 1. Camera (must be exact so pieces line up)
- **True 2:1 isometric ("dimetric")**: a flat ground tile is a diamond exactly **twice as wide as tall**.
- Blender: **orthographic** camera, rotation X = **60°**, Z = **45°** (Y = 0). Ortho scale so one 1 m ground tile renders **256 px wide × 128 px tall**. Light from the **top-left** of the image (sun roughly from the north-west).
- Image generators: attach `iso-template-2x2.png` (a diamond grid drawn on a transparent canvas, see section 4) and say "draw the building standing on this diamond, same angle, same light".
- **North-west of the map is the top of the screen.** The highway (north edge of the map) runs along the upper-right edge.

## 2. Canvas rules
| Footprint | Canvas width | Diamond height at the bottom | Canvas height |
|---|---|---|---|
| 1×1 (walls, towers, traps, units, zombies, decor, ground tiles) | 256 px | 128 px | free (ground tiles: exactly 128) |
| 2×2 (shelter, farm, scavenger, workshop, barracks, storage, construction, rubble) | 512 px | 256 px | free (≈ 512–640) |
| 3×3 (HQ, construction 3×3) | 768 px | 384 px | free (≈ 768–900) |
| 2×1 (car wreck, RV, pickup) | 384 px | 192 px | free |

- The object **stands on its footprint diamond**, and the diamond's **bottom point touches the bottom-middle of the canvas**. That point is the anchor the game uses. Extra height goes upward; never crop the top.
- Transparent background, no baked shadow on the ground beyond a soft contact shadow under the object.
- **Do not trim** the transparent edges. The importer keeps the canvas as-is, because the anchor depends on it.
- Ground tiles (`tile_*`): an opaque diamond on transparent corners, 256×128, seamless with neighbors on all four diagonal edges. `tile_asphalt_line` has its lane line running along the upper-right/lower-left diagonal (the highway's direction).

## 3. Things that turn (facings)
Moving things can't be spun like in top-down, so each gets a few drawings. Names add a screen-direction suffix:
- **Survivors, defenders, zombies:** 4 facings. Draw **`_se`** (walking toward the lower right) and **`_ne`** (toward the upper right). The game mirrors them for `_sw` and `_nw`. Example: `zmb_walker_se.png`, `zmb_walker_ne.png`.
- **Turret tops** (`def_watchtower_gunner`, `def_mg_nest_gun`): 8 facings. Draw `_e`, `_se`, `_s`, `_ne`, `_n`; the game mirrors for `_w`, `_sw`, `_nw`. Each top is drawn on the same 256-wide canvas as its base, so it sits in place when layered.
- Anything without facing images falls back to a block (towers) or the base image.

## 4. Template images
- `docs/art-templates/iso-template-1x1.png`, `-2x2.png`, `-3x3.png` (in the repo): transparent canvases at the sizes above, with the footprint diamond outlined in red at the bottom and the anchor point marked yellow. Use them as the "stand here" guide in every prompt, then hide the outline before export.

## 5. Delivery and import
1. Put finished PNGs in one folder (any name), filenames exactly as in `docs/graphics-spec-phase1.md` (plus facing suffixes).
2. Run `python3 tools/import_art.py <folder> --view iso`. Files go to `App/Assets.xcassets/Art/Iso/`; UI icons go to `Art/UI/`.
3. If something stands a bit off, don't redraw: fix it in `Content/presentation.json` → `views.isometric.assets.<id>` with `"anchor": [x, y]` (ground point as fractions from the image's top-left; default `[0.5, 1.0]`) or `"scale": 1.1`.

## 6. Priority
P1 for the isometric view to look finished: `tile_grass`, `tile_dirt`, `tile_asphalt`, `tile_asphalt_line`, `tile_concrete`, `bld_hq`, `bld_shelter`, `bld_farm`, `bld_scavenger`, `bld_construction_2x2`, `bld_construction_3x3`, `def_wall_wood`, `def_watchtower_base`. Then the rest of the phase 1 list, then units/zombies with facings (needed from milestone 1B).

## Walker animation frames (chunk 2A prototype)
`zmb_walker_se_w0.png` through `_w5.png`, and `zmb_walker_ne_w0.png` through `_w5.png`. Twelve transparent 256×232 masters, unchanged scale/baseline across frames; mirror for SW/NW. Preserve the approved realistic walker source, not the old Blender model. Still-facing sprites remain fallbacks. Source: `HighwayHoldout_Iso_Art/walker-walk/`.

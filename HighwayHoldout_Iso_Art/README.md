# Isometric art

**Current walker:** `walker-mixamo/` supplies the stock Mixamo Yaku J Ignite / Zombie Walk as 12 limb frames and matching SE/NE stills (D-026). Re-import `walker-mixamo/png/` after full old Blender renders. Read its README for reproducible rendering, measured stride, verified checks and pending normal-horde acceptance. `realistic-walker/` and `walker-walk/` preserve the earlier 2D pilot/prototype; they are no longer the current production route. Raw FBX sources stay local and never ship.

These PNGs are the game's **isometric view** art. They were rendered by `tools/blender/render_iso_sprites.py`
from the Blender study's 3D models (`HighwayHoldout_Blender_Study/scripts`) with the camera in `docs/graphics-spec-iso.md`.

- Study models: HQ, shelter, farm, wood wall, watchtower (+ gunner, 5 facings), car wreck, dead tree, rubble,
  survivor / defender / walker (se + ne facings).
- Stand-in models by Claude in the study's style (`tools/blender/extra_models.py`): scavenger post, workshop,
  barracks, storage, construction scaffolds 2x2/3x3, rubble 2x2, and the five ground tiles.
- Milestone 1B defenses by Claude (`tools/blender/defense_models.py`): metal wall (same size/orientation as the
  wood wall), MG nest base + gun (5 facings, on the base's 256x216 canvas, like the watchtower gunner), spikes,
  barbed wire.
- Milestone 1B zombies by Claude (`tools/blender/zombie_models.py`): runner (~0.9x walker, lean, sprinting) and
  brute (~1.6x walker, hulking), each with a base image + se/ne facings.
- Not made yet: fx_* effects (the iso view reuses the flat top-down effects), vehicles (phase 3), a 1x1
  construction scaffold (walls/towers reuse the 2x2 one).

Re-render everything (about a minute), then import (`--only def_mg_nest_gun` also renders its base, so the layers share a canvas):
```sh
/Applications/Blender.app/Contents/MacOS/Blender -b --python tools/blender/render_iso_sprites.py -- --samples 48
python3 tools/import_art.py HighwayHoldout_Iso_Art/png --view iso
```
Any PNG from the art team with the same name replaces one of these on the next import.

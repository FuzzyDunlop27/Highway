# Isometric art (rendered, not hand-drawn)

These PNGs are the game's **isometric view** art. They were rendered by `tools/blender/render_iso_sprites.py`
from the Blender study's 3D models (`HighwayHoldout_Blender_Study/scripts`) with the camera in `docs/graphics-spec-iso.md`.

- Study models: HQ, shelter, farm, wood wall, watchtower (+ gunner, 5 facings), car wreck, dead tree, rubble,
  survivor / defender / walker (se + ne facings).
- Stand-in models by Claude in the study's style (`tools/blender/extra_models.py`): scavenger post, workshop,
  barracks, storage, construction scaffolds 2x2/3x3, rubble 2x2, and the five ground tiles.
- Not made yet (still placeholder blocks in game): metal wall, MG nest, spikes, barbed wire, runner, brute.

Re-render everything (about a minute), then import:
```sh
/Applications/Blender.app/Contents/MacOS/Blender -b --python tools/blender/render_iso_sprites.py -- --samples 48
python3 tools/import_art.py HighwayHoldout_Iso_Art/png --view iso
```
Any PNG from the art team with the same name replaces one of these on the next import.

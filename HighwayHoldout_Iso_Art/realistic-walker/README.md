# Realistic walker — static sprite pilot

Only the isometric walker is replaced. These are realistic generated 2D cutouts, not a rigged 3D model. The original requested appearance was adapted to intact skin and non-graphic detail after the image service rejected an earlier attempt. Runner, brute, buildings and top-down art are unchanged by this pilot.

- `source/walker-se.png`, `source/walker-ne.png`: full-resolution transparent originals from built-in image generation. RGB in transparent pixels can look like a glow in viewers that ignore alpha; actual compositing is clean.
- `PROMPTS.md`: exact successful generation prompts.
- `prepare.py`: reproducible canvas fitting and review preview. Uses existing alpha, resizes and pads; does not repaint the character.
- `png/`: three production masters (`zmb_walker`, `_se`, `_ne`), 256×232 each. Base is identical to southeast. Existing mirroring supplies southwest/northwest.
- `previous/`: the prior detailed low-poly walker sprites, retained for recovery.
- `preview.png`: close-up front/back artwork and smaller sprite previews.

Rebuild using a Python environment with Pillow (the existing `/tmp/hh-art-venv/bin/python` worked for this pass):

```sh
python3 HighwayHoldout_Iso_Art/realistic-walker/prepare.py
cp HighwayHoldout_Iso_Art/realistic-walker/png/*.png HighwayHoldout_Iso_Art/png/
python3 tools/import_art.py HighwayHoldout_Iso_Art/realistic-walker/png --view iso
```

The sprites use the existing walker height and footprint: no simulation, save, code or tuning changes are needed. Fine facial detail naturally reduces at normal gameplay zoom.

**Protect this artwork:** re-rendering the old walker with `tools/blender/render_iso_sprites.py` overwrites the aggregate PNGs with its low-poly model. Reapply this folder afterward. Do not use that old model as the source of realistic walker walk frames.

**Animation handoff:** chunk 1B / ZWALK-1 is a separate owner-requested chat. Preserve this character, costume, angle, body scale and foot pivot. The existing procedural shamble remains; this pilot supplies no limb animation or rig. The next chat must select a consistent frame-production approach for this 2D source rather than assuming a matching Blender model exists.

## Verification
- Latest app build succeeded for iPhone 18 Pro (iOS 27 simulator).
- Import: 3/3 masters, no warnings; three RGBA canvases match and visible pixels do not touch edges.
- Verified transparency against grass, and all four directions in the running app.
- `in-game-four-facings.png`: actual simulator capture using a temporary paused fixture with four walkers near the town, one per direction. This is not a generated/composited town mockup. Natural horde rendering was also inspected; walls obscured walkers, so the fixture makes review easier.
- Restored the pre-test simulator town byte-for-byte and left the app stopped. No fixture is shipped.
- No Core or tuning changes in this art pass; Core tests were not rerun. No limb animation implemented.

# Walker — Mixamo pipeline (ZWALK-1M)

Owner approved a stock replacement and matching SE/NE frame-0 stills in D-026. This supersedes the generated-pose prototype for the walker only. Runner, brute, top-down art, simulation and saves are unchanged.

- Character: **Yaku J Ignite**. Animation: **Zombie Walk**. Selected/downloaded through the owner's logged-in Chrome using the ChatGPT extension on 2026-10-31.
- Mixamo controls: Stride 50, Overdrive 50, Character Arm-Space 50, trim 0–100%, Mirror off. Both exports: FBX Binary, With Skin, 30 fps, Keyframe Reduction none. In Place on for `walker_walk_inplace.fbx`, off for `walker_walk_root.fbx`.
- `source/`: the two local FBX working files (embedded textures intact). Ignored by Git, excluded from the app, not for redistribution. Keep a private backup; a fresh checkout cannot regenerate without them.
- `png/`: twelve RGBA 256×232 walk frames plus two matching stills, imported without warnings. West facings are mirrored in the app. Original base fallback remains in place; normal directional stills are replaced as approved.
- `render-metadata.json`: action range, six fractional sample times, scale, measured root distance, stride and endpoint closure. Samples exclude the duplicate last frame. One fixed camera/scale across both facings and all poses: global projected silhouette envelope 160 px tall, lowest cycle silhouette at y=184. Individual frames naturally vary in height/foot projection; no per-frame fitting.
- `compare.png`: previous SE still, new frame zero, and 50% overlay. `preview.gif`: all four facings, timed at configured walker speed. `mixamo-selection.png`: browser selection evidence.
- `in-game-paused*.png`: actual simulator, four facings plus unchanged runner/brute. Walker crop differences between captures were zero.
- `in-game-fallback.png`: actual simulator built with SE w0 temporarily omitted. Matching still displayed, no crash. Source imageset restored; full build reinstalled afterward.
- `in-game-attack*.png` / `attack-comparison.png`: existing wall-bashing state holds frame zero; sprite crop unchanged over three seconds. No attack animation was added.
- `walker-motion-detail.png`: six cropped frames from the actual simulator recording, showing alternating legs. `local-review/` holds raw/trimmed recordings and intermediate captures, ignored by Git.
- `in-game-day40*.png`: temporary 35-zombie day-40 fixture. Initial capture 56.3 fps / 34 survivors; later protected-HQ fixture 60 fps at 8 and 10 seconds / 32 survivors / 1,389 nodes. Protected HQ prevents the test ending early; not a normal debug-menu-generated horde or a device benchmark.

## Reproduce

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/render_mixamo_walk.py -- HighwayHoldout_Iso_Art/walker-mixamo/source/walker_walk_inplace.fbx HighwayHoldout_Iso_Art/walker-mixamo/png --root-fbx HighwayHoldout_Iso_Art/walker-mixamo/source/walker_walk_root.fbx
# Add --test for only the SE frame-zero scale comparison before rendering all frames.
# Python with Pillow installed (this session used /tmp/hh-art-venv/bin/python):
python3 tools/blender/preview_mixamo_walk.py HighwayHoldout_Iso_Art/walker-mixamo
python3 tools/import_art.py --view iso HighwayHoldout_Iso_Art/walker-mixamo/png
```

The renderer imports camera axes, FACING angles, camera helper and staging from `render_iso_sprites.py`; that script now has an import-safe main guard. Material colors/textures come from the FBX, with an adjacent-file relink fallback. No image repainting. Measured loop root travel 1.486675 m × fitted scale 0.41361584 = **0.6149123397 tiles**; configured in `presentation.json`. Six frames remain. Preview GIF derives tempo from that stride and the configured walker speed.

## Verification and limits — 2026-10-31

119 Core tests passed, including ContentFilesTests. iPhone 18 Pro / iOS 27 simulator builds passed for full assets, deliberate missing-frame test, and restored full assets. Render outputs have clear transparent borders. Endpoint maximum difference is 0.0000713 rendered pixels. Existing runtime reused without any Swift changes.

Native simulator clicks failed even though CLI launch/capture worked. Four-facing motion, pause, attack hold, fallback and crowd checks used temporary save fixtures in the actual app, not generated town mockups. The long-press → Horde now path was not exercised. Hands-on assessment of foot sliding and smoothness over a normal horde remains pending; do not close chunk 2A or start runner/brute based on the automated checks alone.

Original simulator save restored byte-for-byte, app stopped, complete normal build installed. Original save SHA-256: `f6aaa4c161e7ba3ed5ab839bb62c8d0d3fe4007595873c62e025b3cfd86c9510`. Fixtures were outside the shipped app and are not retained as production data.

After an old full Blender art render or old walker import, re-import this folder to restore the current walker frames and directional stills. Earlier sources remain in `realistic-walker/` and `walker-walk/`, with prototype backup commit `c12e557`.

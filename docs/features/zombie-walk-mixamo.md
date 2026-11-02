> **3D (chunk MOD-002):** the same FBX now feed `tools/blender/export_characters.py`; see `docs/features/characters-3d.md`.

> **Cleanup 2026-11-01:** the 2D walker frames, renderer scripts and Iso art folder were deleted (D-030). The FBX files now live in `HighwayHoldout_3D_Sources/mixamo-walker/`; only the Mixamo source/licence notes here still apply (chunk MOD-002). Paths below to deleted files are history (see git).

# ZWALK-1M — Walker limb animation via Mixamo (alternative route for chunk ART-003)

> **RETIRED as 2D frames (D-030, 2026-11-01):** the app no longer uses the rendered walker PNGs. The Mixamo source and D-026 terms notes still matter for chunk MOD-002 (animated 3D walker).

**Label:** `ZWALK-1M` · **Ticket:** ART-003 (art track, see `docs/BUILD-QUEUE.md`) · **Type:** art + rendering only (no Core, gameplay or save change)
**Runs in:** Claude Code (this repo) or ChatGPT/Codex. Each step says who does it.

## Why this route
The first 2A prototype used AI-generated 2D poses, and the walker limps: the strides aren't balanced and the feet
slide (`zombie-walk-animation.md` → "Still pending"). Mixamo (free, Adobe account) has professionally animated
**zombie walk** cycles. If we render those from a 3D character, the strides are correct by construction.

**The app side is already built.** `ZombieNodeFactory` picks `zmb_walker_<se|ne>_w0…w5` by distance walked, and
`presentation.json → views.isometric.zombieWalk` sets frames and stride. This route only replaces the 12 PNGs, plus
the still if the owner decides so in step 0.

## Current session — 2026-10-31
- Steps 0–3 implemented: D-026 approval; prototype `c12e557`; Chrome extension connected; stock **Yaku J Ignite / Zombie Walk** downloaded with both in-place and root motion. All sliders default 50, full trim, mirror off; FBX Binary, With Skin, 30 fps, reduction none.
- Renderer: `tools/blender/render_mixamo_walk.py`; shared iso staging imported after making `render_iso_sprites.py` import-safe. Separate `preview_mixamo_walk.py` builds comparison/GIF artifacts. Test overlay inspected before all-frame render. Embedded textures intact.
- Outputs: 12 frames + 2 matching stills imported, zero warnings. Fixed 256×232 canvas / 160 px global envelope / y=184 cycle baseline. Actual action frames 1–122, six evenly spaced samples excluding duplicate endpoint. Root 1.486675 m × scale 0.41361584 = stride **0.6149123397 tiles**. No Swift/Core/save implementation changes.
- Step 4: 119 Core tests and simulator builds pass. Actual-app fixtures checked four facings, paused stability, attacking hold, missing-frame fallback and crowd rendering. Missing SE w0 restored and full build reinstalled. Two later day-40 crowd captures read 60 fps (32 zombies / 1,389 nodes; protected HQ fixture).
- **Still pending:** native simulator clicks failed, so long-press → Horde now and hands-on smoothness/foot-sliding acceptance over a normal horde remain unchecked. Chunk ART-003 remains in progress for that visual acceptance; runner/brute not started.
- Original town restored byte-for-byte; app stopped. Full evidence, limits and reproduction commands: `HighwayHoldout_Iso_Art/walker-mixamo/README.md`. Raw FBX and local review recordings stay local and ignored by Git.

## Step 0 — Owner decisions (before any work)
1. **Character source.** Mixamo animates a 3D model, but the approved realistic walker is 2D art with no 3D model. Pick one:
   - **(a) Mixamo stock zombie** (recommended, fastest): choose a zombie from Mixamo's Characters tab that's closest
     to the approved walker. The look will change somewhat.
   - **(b) Make a 3D model from the approved cutout** with an image-to-3D tool, then upload it to Mixamo. This is
     closer to the current look but adds a tool, an account and a cleanup step, and needs its own DECISIONS entry.
2. **Still image.** The walking frames should match the still. Default: also replace `zmb_walker_se/ne` with frame 0
   of the new render. Otherwise the walker changes look when it stops.
3. **Licence.** Mixamo characters and animations are royalty-free in games, as long as the raw files aren't
   redistributed. Check Adobe's current Mixamo FAQ, then add a `docs/DECISIONS.md` entry recording the owner's
   approval of Mixamo as an asset source (AGENTS.md: third-party content needs owner approval).
4. **Housekeeping.** The first 2A prototype is uncommitted in the working tree (`walker-walk/`, `_wN` imagesets,
   ArtRegistry/ZombieNodeFactory/presentation changes). Commit it first (it holds the app wiring this route reuses).

## Step 1 — Mixamo: get the animation (browser; owner or agent)
Who: **here**, Claude uses *Claude in Chrome* in the owner's logged-in Chrome. **In ChatGPT**, use agent mode's
browser, or the owner clicks through this checklist (about 5 minutes).
1. mixamo.com → **Characters** → pick the zombie from step 0. For route (b), **Upload Character**, then place the
   chin, wrist, elbow, knee and groin markers.
2. **Animations** → search "zombie walk" and preview a few. Pick a slow, shambling, *looping* cycle that reads well
   from above at a distance. Note its exact name in the change log.
3. Tick **In Place** (required: the game moves the zombie; the animation must not drift). Leave the speed/overdrive
   sliders at their defaults unless the owner wants it slower.
4. **Download:** Format **FBX Binary (.fbx)**, Skin **With Skin**, Frames per second **30**, Keyframe Reduction **none**.
5. Optional, for measuring stride: download the same animation once more with **In Place unticked**.
6. Save the files in `HighwayHoldout_3D_Sources/mixamo-walker/` (`walker_walk_inplace.fbx`, `walker_walk_root.fbx`).
   Keep them as source; never ship them in the app.

## Step 2 — Blender: render 12 frames (agent; script)
New script `tools/blender/render_mixamo_walk.py` (keep it under ~250 lines). Run it headless:
`blender -b -P tools/blender/render_mixamo_walk.py -- <fbx> <out_dir>`.
- **Camera, lights, render settings:** reuse the orthographic iso camera, `FACING` angles and lighting from
  `render_iso_sprites.py` (import its helpers; don't copy-paste numbers). The new art should sit in the same world as
  the buildings.
- **Orientation and scale:** Mixamo imports at a different scale, and its characters don't face +X like our models.
  Rotate the character to face +X. Scale it so its height matches the current walker: same **256×232 canvas**,
  **about 160 px tallest body height**, **feet on the baseline at y = 184** (`graphics-spec-iso.md`,
  `realistic-walker/README.md`). Verify with one test render overlaid on the current still before rendering all frames.
- **Frames:** the loop runs from `frame_start` to `frame_end`, and its last frame equals its first. Sample 6 frames
  evenly over one full cycle (two steps), excluding the duplicate end frame.
- **Facings:** render `se` and `ne` only (the game mirrors them for `sw`/`nw`). Check that mirroring looks right.
  Mixamo walks are close to symmetric, so it should.
- **Output:** transparent PNGs `zmb_walker_se_w0.png … _w5.png` and `zmb_walker_ne_w0 … _w5`. If step 0.2 says
  replace, also `zmb_walker_se.png` / `zmb_walker_ne.png` from frame 0.
- **Materials:** if the FBX loses colours or textures, fix them in the script (re-link the textures Mixamo exports
  next to the FBX). Never repaint in an image editor, so the pipeline stays repeatable.
- Also write `preview.gif` (four facings, looping) and a side-by-side `compare.png` against the current still.

## Step 3 — Import and tune (agent)
1. `python3 tools/import_art.py --view iso HighwayHoldout_Iso_Art/walker-mixamo/png`. It already accepts `_wN`.
   Expect 12 (or 14) imported and zero warnings.
2. **Stride.** Set `presentation.json → views.isometric.zombieWalk.strideTiles` so the feet don't slide. From the
   root-motion FBX: distance travelled per loop ÷ tile size in the same scale. Otherwise tune by eye in the
   simulator. Keep `frames` at 6. This is the only JSON field expected to change, and no Swift change is expected.
3. If the frames reveal an app bug (jitter, wrong mirror, wrong frame order), fix it in `ZombieNodeFactory.swift`
   and say so.

## Step 4 — Checks (agent; needs a Mac with Xcode for the simulator)
- `cd Core && swift test` passes. The simulator build passes: `xcodebuild -scheme HighwayHoldout -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build`.
- In the simulator, long-press the horde chip → **Horde now**. Check all four directions, smooth alternating steps,
  no foot sliding, no size/anchor jump between frames, a stopped/attacking walker holds still, and the
  runner/brute are unchanged.
- Missing-frame fallback: temporarily rename one `_w` imageset and confirm the still image shows with no crash, then
  restore it.
- A day-40 horde (debug menu) still reads about 60 fps on the DEBUG overlay.
- In ChatGPT without Xcode: say so, and leave the simulator checks for a Mac session. Never claim they passed.

## Step 5 — Paperwork (agent)
Update `zombie-walk-animation.md` (current implementation: Mixamo route, animation name, verification),
`docs/BUILD-QUEUE.md` 2A status, `docs/MAP.md` (new script and folder), `docs/DECISIONS.md` (step 0.3),
`docs/STATUS.md`, `HighwayHoldout_Iso_Art/README.md`, and the Craft handoff log.

## Not in scope
Runner and brute (same recipe later, one at a time), attack swings, top-down art, gameplay/Core/save changes.

## Hand-off prompt (paste into a new Claude Code or ChatGPT/Codex session)
> Run ZWALK-1M: follow `docs/features/zombie-walk-mixamo.md`. Start by asking me the step 0 decisions. Then do step 1
> (if you can drive my browser, use my logged-in Mixamo session; otherwise give me the click-by-click checklist and
> wait for the FBX files), then steps 2–5. Walker only. Follow AGENTS.md. If you can't run the simulator, say so.

## Change log
- 2026-10-31 — Spec written (Claude) as a Mixamo alternative to the generated-pose prototype. Not started.

- 2026-10-31 — Step 0 approved (D-026), prototype committed as c12e557; step 1 handed to owner after browser-control failures. Waiting for FBX files before steps 2–5.

- 2026-10-31 — Chrome extension resolved download blocker; implemented Mixamo render/import pipeline (Yaku J Ignite / Zombie Walk), measured stride, matching stills and actual-app fixture checks. Normal-horde hands-on visual acceptance remains; original town restored.

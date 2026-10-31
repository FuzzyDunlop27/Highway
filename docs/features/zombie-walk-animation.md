# ZWALK-1 — Zombie walk animation (limbs) — walker prototype in progress

**Label:** `ZWALK-1` · **Type:** art + rendering (no Core/gameplay change) · **Fits:** 1E Art swap & polish, or any time

## Current implementation — 2026-10-31
- **Approved next route:** ZWALK-1M / D-026 replaces the walker with a Mixamo stock character and matching frame-0 stills. Prototype preserved in `c12e557`; waiting for owner FBX downloads after browser-control failure. Follow `zombie-walk-mixamo.md` before the historical recipes below.
- **Chunk 2A in progress:** realistic walker only; 12 generated transparent poses (six SE, six NE), mirrored for SW/NW. Source sheets, slicing script, four-facing `preview.gif`, and simulator capture live in `HighwayHoldout_Iso_Art/walker-walk/`.
- Built-in image generation uses the approved realistic cutouts as references. The historical Blender recipe below is NOT the current walker pipeline. No Blender model was replaced.
- `ZombieNodeFactory.swift` accumulates distance between Core positions; selects `_w0…_w5`, holds frame zero while attacking, swaps cached textures on the existing body, and disables fake hop/lean when a walk frame exists. Missing frames use the still art and legacy shamble.
- `presentation.json` → `views.isometric.zombieWalk`: six frames, 0.36 tile stride. `PresentationDefs.swift` decodes this optional presentation-only data; no simulation or save change. Top-down omits it.
- `ArtRegistry.swift` exposes cached real textures; `tools/import_art.py` recognizes the `_wN` suffix. Generated frames share the current 256×232 canvas, 160-pixel maximum body height and bottom baseline 184. No per-pose scaling.
- **Verified:** 12 distinct transparent frame files with clear borders; importer 12/12, zero warnings; 119 Core tests pass; iPhone 18 Pro simulator build passes; launched a day-7 horde, realistic walkers render and DEBUG overlay reads 60 fps. Test-town backup restored byte-for-byte; app stopped.
- **Still pending:** balanced opposite-leg strides, torso/foot registration polish, deliberate pause/attack/missing-frame and mirrored-motion checks, and day-40 performance review. Current AI poses favor one leg and look like a limp. Do not mark the chunk finished or extend to other zombies yet.

## Source correction — realistic walker pilot (2026-10-31)
The owner approved the realistic walker and reserved animation for a separate chat (**chunk 2A** in `docs/BUILD-QUEUE.md`). The current walker is now generated **2D cutout artwork** in `HighwayHoldout_Iso_Art/realistic-walker/`; there is no matching realistic Blender model or rig. The Blender-only recipe below predates that pilot and must NOT be applied to the walker as written, or it will revert the approved appearance to polygons. Preserve its identity, costume, camera, 256×232 canvas, scale and foot position; select a compatible frame-production approach first. The old Blender recipe remains relevant only to the unchanged runner/brute, which are outside chunk 2A. Read the realistic walker README and exact prompts before generating anything.

## How to run this later
Open a new Claude Code (or Codex) session in this repo and paste:

> Implement chunk 2A in `docs/BUILD-QUEUE.md`: animate only the realistic walker, preserving the source art in
> `HighwayHoldout_Iso_Art/realistic-walker/`. Read the source correction above; do not render the old low-poly walker.
> Wire consistent limb frames into the app and show a simulator check. Leave runner/brute and attacks for later.

Doing the walker first is a cheap test of the whole pipeline before spending credits on all three types.

_Status: walker prototype started 2026-10-31. Owner asked "can the limbs move?" Answer: yes, and it fits the existing art pipeline._

## Goal
Zombies swing their arms and legs while walking, instead of one still pose sliding along with a procedural hop/lean
(see the 2026-10-31 shamble entry in `rendering-art.md`). Attacking zombies get a simple 2–3 frame swing later (optional, step 5).

## Why it's feasible
- Zombies are built in Blender by `tools/blender/zombie_models.py`, and limbs are `beam(name, start, end, ...)` calls
  between joint points (hip, knee, shoulder, elbow…). Moving those points moves the limb, so no rigging is needed.
- `tools/blender/render_iso_sprites.py` already renders each zombie per facing (`UNIT_FACINGS = ('se', 'ne')`, mirrored
  in-game for sw/nw). Rendering N poses per facing is a loop around the same code.
- The app already swaps a zombie's texture by facing (`DirectionalSprite`). Swapping by walk frame is the same idea.

## Plan

### 1. Blender: pose the models by walk phase (`zombie_models.py`, maybe a new `zombie_poses.py` if it passes ~250 lines)
- Give `walker()`, `runner()` and `brute()` a `phase` argument (0.0–1.0 = one full stride: left step, then right step).
- Replace fixed joint points with ones computed from `phase`:
  - Hip → knee → foot: legs swing forward/back opposite each other (`sin(2π·phase)` and the negative), and the knee
    bends more on the swinging leg. The planted foot stays on the ground (z = 0).
  - Shoulder → elbow → hand: arms swing opposite the legs. Walkers keep their arms reaching forward with a small sway.
    Runners pump their arms hard. Brutes drag their knuckles with a small swing.
  - Torso: a small up/down bob (highest mid-stride) and a slight twist.
- Keep the current pose as `phase = 0` so existing still sprites don't change. Detail parts from `zombie_details.py`
  (face, costume) must follow the limb or torso they sit on, so attach them relative to the joint points.

### 2. Render the frames (`render_iso_sprites.py`)
- Add `WALK_FRAMES = 6` (look-only art setting, not game tuning) and render each zombie at
  `phase = i / WALK_FRAMES` for each facing.
- Name them `zmb_walker_se_w0.png` … `zmb_walker_se_w5.png` (same for `_ne`, runner, brute) = 3 × 2 × 6 = **36 PNGs**.
- Keep camera, scale, anchor and canvas size identical to the current sprites, so feet land in the same spot in every
  frame. Otherwise the zombie jitters.
- Keep writing the plain `zmb_walker_se.png` (phase 0) as the fallback and still image.
- Import with `python3 tools/import_art.py --view iso <folder>`, and add the new names to `docs/graphics-spec-iso.md`.

### 3. App: pick the frame (`App/Rendering/Nodes/ZombieNodeFactory.swift`)
- Drive the frame from **distance walked**, not a timer, so feet don't slide: keep a per-zombie running total of how far
  its grid position moved between updates; `frame = Int(distance / strideTiles * WALK_FRAMES) % WALK_FRAMES`.
  `strideTiles` (already a look-only constant) should match the stride length in the Blender poses, about 0.3–0.4 tiles.
- Texture id = facing id + `_w<frame>` (e.g. `zmb_walker_se_w3`). Mirroring for sw/nw works unchanged.
- Fallback: if `hasImage` says the frame is missing, use the plain facing image (today's behavior). A missing walk set
  must never crash or show placeholders.
- Only swap the texture when the frame actually changes (as the code already does for facings), and use cached
  `SKTexture`s from `ArtRegistry`. Don't rebuild the sprite node.
- When `attacking != nil`, hold frame 0 (or play the attack frames from step 5).
- Shrink the procedural shamble once frames exist: hop about 1–1.5 pt, lean about 0.03 rad, or turn it off. It's
  there now only to fake motion.

### 4. Tests and checks
- Core is not touched (rendering only), so no Core tests are needed. Keep `cd Core && swift test` passing anyway.
- Optional small App-side helper `WalkFrame.index(distance:stride:frames:)`. If it goes in Core/Presentation (like
  `Facing.swift`), add a Swift Testing test for wrap-around and zero distance.
- Simulator check: start "Horde now" (long-press the horde chip). Walkers should step slowly, runners sprint, brutes
  plod. Feet shouldn't slide or jitter, and limbs should swing in the sw/nw (mirrored) directions too. A day-40 horde
  should still run at 60 fps (compare the DEBUG fps overlay).

### 5. Optional later: attack swing
- Same pipeline: render 3 frames `_a0…_a2` (arms raised → hit → recover). Play them on a timer while `attacking != nil`.

## Cost and size
- About 36 new sprites (about 72 with the attack swing). Each is small, and texture memory is fine at current horde
  sizes. Use an `SKTextureAtlas` per zombie type if node or draw counts climb.
- Work estimate: Blender posing is the bulk (one session per zombie type to make the stride look right). Rendering,
  import and app wiring is about one session.

## Files involved (when built)
- `tools/blender/zombie_models.py` (+ maybe `zombie_poses.py`), `tools/blender/zombie_details.py`,
  `tools/blender/render_iso_sprites.py`
- `App/Assets.xcassets/Art/Iso/` (via `import_art.py`), `docs/graphics-spec-iso.md`
- `App/Rendering/Nodes/ZombieNodeFactory.swift`, `docs/features/rendering-art.md`, `docs/MAP.md`

## Change log
- 2026-10-31 — Linked chunk 2A and corrected the walker source: realistic generated cutouts, not a matching Blender model. Owner reserved implementation for another chat.
- 2026-10-31 — Spec written (Claude). Not built.

- 2026-10-31 — Started chunk 2A: generated realistic walk sheets, imported twelve frames, distance-driven rendering, content configuration, successful build/tests and initial live-horde check. Gait polish and full visual exit checks remain.

- 2026-10-31 — Owner approved Mixamo stock replacement (D-026); prototype preserved in c12e557. Waiting for step-1 FBX downloads; no new rendering or simulator verification.

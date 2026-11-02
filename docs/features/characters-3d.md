# Feature: 3D characters (zombies, defenders)

_Chunk 3M. Buildings and props are `models-3d.md` (2M); effects/health bars are 4R._

## Purpose
Zombies are an animated Mixamo zombie instead of green boxes: they glide between Core's ticks, turn smoothly, walk with
the cycle matched to their speed (no foot sliding), and attack while bashing. Defenders use the same machinery once a
defender model exists (today they stay labeled boxes).

## Files involved
- `tools/makehuman/generate_blacksmith.py` + `README.md` — owner-requested MakeHuman base-body → binary FBX trial (3M-2MH), separate from game integration.
- `tools/makehuman/dress_blacksmith.py` — load preserved source, add face modifiers + fitted CC0 skin/clothes/hair; separate dressed MHM/FBX.
- `tools/blender/build_blacksmith_draft.py`, `blacksmith_geometry.py`, `blacksmith_review.py` — apron/beard/material assembly, mesh budget, atlas bake, portable exports, four-angle renders, clean FBX reimport checks.
- `tools/blender/check_makehuman_fbx.py` — real FBX import/height/geometry/image-path check, saved `.blend`, neutral review render; source locations/results in MakeHuman README.
- `docs/plans/blacksmith-profile.md` — age-45 medieval blacksmith sculpt, proportions, costume and pose brief; modern Workshop adaptation noted.
- `tools/blender/export_characters.py` — Mixamo FBX clips → `App/Models/<artId>.usdz` (all clips on one timeline) +
  `<artId>.anim.json` (clip start/end seconds, measured stride). Optional clips are used when their FBX exists.
- `Core/Sources/HoldoutCore/Presentation/CharacterMotion3D.swift` — glide, turn, walk/attack/idle choice, walk-rate math;
  `CharacterAnimFile` (the `.anim.json` shape). Tests: `Core/Tests/HoldoutCoreTests/Presentation/CharacterMotion3DTests.swift`.
- `App/Rendering/CharacterAnimator3D.swift` — plays the right clip on a character's model, cross-fades, sets speed.
- `App/Rendering/ModelRegistry.swift` — loads models; `variants` (scaled/tinted stand-ins), `animInfo`, `clip` (cuts a
  clip out of the single timeline with `AnimationView` trims).
- `App/Rendering/ZombieLayer3D.swift`, `App/Rendering/DefenderLayer3D.swift` — one character per zombie/defender.
- Sources (local only, D-038): `HighwayHoldout_3D_Sources/mixamo-walker/` (`walker_walk_inplace.fbx`, `walker_walk_root.fbx`,
  and when downloaded `walker_attack_inplace.fbx`, `walker_idle.fbx`); defender: `mixamo-defender/defender_idle.fbx`.

## Data files
- `Content/presentation.json` → `reality3d.characters`: glide bounds, snap distance, turn rate, stand speed/grace, speed
  smoothing, `maxWalkRate`, `clipBlendSeconds`, `variants` (`zmb_runner`, `zmb_brute` = the walker scaled and tinted).
- `App/Models/<artId>.anim.json` — written by the exporter, never by hand.

## Key rules
- MakeHuman trial: exact body sliders (muscle 0.80, weight 0.20, height 1.00), age in years, fresh neutral unrigged body; report actual measured height. Face, weathering, clothing and work posture are a manual art pass. Follow `tools/makehuman/README.md`; the default mesh is not assumed mobile-ready. No game artId or runtime dependency added.
- Same scale as 2M: 0.41 tiles per metre (Mixamo zombie ≈ 0.78 tiles tall), feet at the origin, front towards +X.
- Walk playback speed = drawn speed × loop seconds ÷ stride (stride 0.6095 tiles for the walker, × variant scale), capped
  at `maxWalkRate`. The walker's Mixamo shamble is slow (4 s per loop), so a walker at 0.6 tiles/s plays it ≈ 3.9×, a
  runner ≈ 10×, a brute ≈ 1.7×.
- Attack plays while Core's `Zombie.attacking` is set; idle when standing. Missing clip: attack → idle → walk held still.
- Attack/idle run at the game speed (0 when paused). Each zombie starts its walk at its own phase.
- A move longer than `snapDistanceTiles` is drawn as a jump (spawn, reload); everything else glides.
- Mixamo-derived files never go into git (public repo, D-038). No USDZ = labeled box, as for any model.

## Known issues
- Clothed review draft now exists (3M-2MH-L): 9,209 triangles, single 1024 px atlas/material, ~1.22 MB static FBX/GLB, clean FBX round trip. See MakeHuman README for output folder, source assets and precise limitations. It is unrigged/unanimated; beard/skin details and costume remain a draft. Long sleeves and adapted modern collar/shoes deviate from the medieval brief. Original high-detail base preserved; no game asset replaced.
- MakeHuman trial now exports/imports successfully, but its base is 2.44386 m tall at the requested maximum slider and 28,796 triangles. It still needs the look/garments, optimization to ~10k, rig and animation. Blender must import this source with `use_custom_normals=False` to avoid severe facets; rendered before/after confirmed. Raw FBX retained, game assets not replaced.
- Clips used (Yaku J Ignite, default sliders): Zombie Walk (In Place, 121 frames), Zombie Attack (139 frames, hips lunge
  ~0.3 m and return; no In Place option), Zombie Idle (183 frames). All three loop cleanly; walker USDZ 3.0 MB.
- Foot sliding was checked by the maths (tests) and by eye on stills only; nobody has watched a horde from all 4 angles
  closely yet. A walk clip starts at a slightly high speed for ~0.15 s after spawning while the speed settles.
- Runner and brute are the walker scaled/tinted; the runner's 10× shamble looks frantic — a Mixamo run clip would suit it.
- Defenders stay boxes until a defender model is downloaded.
- A fresh clone of the repo shows zombie boxes until the exporter runs with local Mixamo files.
- No in-game fps readout yet (5R); the 1R spike measured 100 animated walkers at 60 fps on an iPhone 18 Pro.

## Change log
- 2026-11-01 — 3M-2MH-L: fitted source clothing/hair/older skin and jaw modifiers in MakeHuman; built leather apron/beard, corrected visual defects, reduced clothed assembly to 9,209 triangles; baked one atlas, exported blend/FBX/GLB, reviewed four angles and verified clean FBX reimport; packaged review bundle. No rig/animation or game hookup.
- 2026-11-01 — 3M-2MH-V: actually generated FBX/MHM in live MakeHuman, imported in Blender, checked exact height/finite geometry/images, saved `.blend` and reviewed a clean preview after disabling bad imported custom normals. Output 831,468-byte FBX / 28,796 triangles / 2.443859 m; not phone-ready or dressed/rigged. No App/Core changes.
- 2026-11-01 — Owner-requested status audit: installed files/settings/script link and active MakeHuman process rechecked; expected blacksmith export folder contains zero FBXs/reports. Preparation and installation done; real export/import and all human game integration remain pending. Craft handoff/kanban reconciled; no character/code changes.
- 2026-11-01 — Chunk 3M-2MH-I: installed official MakeHuman source + CC0 system assets in user Applications, isolated Python packages, Mac launcher and linked trial script. Modeling screen observed, scripting/FBX plugin loads confirmed, pip check passes. Real export/import still pending.
- 2026-11-01 — Chunk 3M-2MH: MakeHuman body/FBX script, usage and API evidence, precise blacksmith profile. Syntax/control-flow checks only; MakeHuman execution and real FBX import pending.
- 2026-11-01 — Chunk 3M (in progress): exporter, `CharacterMotion3D` + tests, animator, variants, walker in game (D-038).
- 2026-11-01 — Chunk 3M done: Mixamo Zombie Attack + Zombie Idle downloaded and exported; attack/idle switch confirmed in the app.

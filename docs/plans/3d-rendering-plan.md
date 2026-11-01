# Plan: real 3D drawing for Highway Holdout (option two)

> **Status 2026-11-01:** chosen (D-027), 1R spike GO (D-028), 2R done, and 2D retired early at the owner's request (D-030), so §4's "run side by side" no longer applies and 6R is done. Live status: `docs/BUILD-QUEUE.md`.

_Written 2026-10-31. A plan only: nothing here is built or approved. Compare it with `docs/plans/living-world-plan.md` (option one, staying 2D) and pick._

## In one paragraph
Today the game draws flat pictures (sprites) that were rendered from 3D models in Blender at one fixed angle. Going "real 3D" means the phone draws those 3D models itself, every frame. That gives you a camera you can turn and tilt, real sunlight and shadows, and smooth animation from any angle. The game rules (`Core/`) and the menus/HUD stay exactly as they are. Only the part that draws the map changes. It's a big job, roughly **3–5 times the work of the 2D living-world pass**, and most of that work is art, not code. **My advice:** first do a short, cheap test (chunk 1R, below) that shows our models running in 3D on a real iPhone. Decide after seeing it, and only continue if the 2D art redo can't get the look you want.

## 1. Which 3D engine? (recommendation: RealityKit)

| Option | What it is | Verdict |
|---|---|---|
| **RealityKit** | Apple's current 3D engine (built for AR, but it also works as a normal game view). Swift-first, real lighting and shadows, loads Apple's USDZ 3D file format directly, plays character animations. | **Recommended.** It's where Apple is putting its effort, it fits our Swift 6 / SwiftUI app, and it's free and built into the phone (no third-party dependency). |
| **SceneKit** | Apple's older 3D engine. Easy and mature. | **No.** At WWDC 2025 Apple *soft-deprecated* it: it still works, but it only gets critical bug fixes and no new features, and Apple tells developers to move to RealityKit. Starting new work on it would mean building on something that's being wound down. |
| **Metal directly** | Writing our own 3D engine on Apple's graphics chip interface. | **No.** Months of engine work before any game shows up. Only worth it for a studio with graphics specialists. |
| **Outside engine** (Unity, Godot) | Full game engines with editors and big toolsets. | **Comparison only.** We would have to rebuild the SwiftUI menus and connect our Swift game rules to another language/runtime. That brings licence terms (Unity) or immature Swift bindings (Godot), and needs a third-party approval in DECISIONS. Too disruptive for what we need. |

**The catch with RealityKit.** The modern SwiftUI way to show a RealityKit scene on iPhone (`RealityView` with a virtual camera) needs **iOS 18**. On iOS 17 there is only the older `ARView` in "non-AR" mode. Instancing (drawing hundreds of copies of one model cheaply) needs **iOS 26**. Our minimum is iOS 17. Two ways out, and you'd pick one (see Owner decisions):
- **(a) Raise the minimum to iOS 18 for the whole app (recommended).** iOS 17-only phones are now a small group.
- **(b) Keep iOS 17, and have those phones keep the 2D view forever.** That works with the switch in §4, but we'd maintain two renderers indefinitely.

RealityKit also has fewer game tutorials than SceneKit had, and some features (particles, billboards) only arrived in recent iOS versions. Chunk 1R exists to find any such gaps early.

## 2. What in `App/` is replaced and what is kept

| Kept as is | Replaced (3D version alongside the old one until 2D is retired) |
|---|---|
| All SwiftUI: `UI/` HUD, build menu, placement bar, banners, debug menu, `KitStyle` | `GameScene` (SpriteKit scene) → a `RealityView` world |
| `GameStore` (the bridge to Core) and the `Command`s it sends | `Nodes/*Factory.swift` → one 3D "entity factory" per type (terrain, building, defense, zombie, FX, ghost) |
| `PlacementController` logic (mode, ghost spot, validity, Confirm) and `PlacementMessages` | `CameraController` → orbit camera: pan, pinch zoom, **rotate** (two-finger twist, snapping to 4 angles optional), limited tilt |
| UI icons from `Art/UI` (`ArtIcon`), menu thumbnails (still PNGs) | `HitTesting` → a "ray" from the finger to the ground plane (tile) or to a building's collision box |
| `Platform/` (saving, lifecycle) | `ArtRegistry` → a **ModelRegistry** (art id → 3D model, or labeled placeholder) |
| | `DepthSort` / `ZLayer` → **deleted in 3D**: the graphics chip sorts by distance automatically |
| | `DirectionalSprite`, wall mirroring trick → **gone**: models simply rotate to any angle |
| | `ViewSwitcher` (iso ↔ top-down) → top-down becomes "tilt the camera straight down" |

One structural change: today `GameScene` drives the game clock (it calls `store.advance` every frame). That job moves into a small shared "ticker" so both renderers use it. That keeps the game rules running identically whichever view is on.

**`Core/…/Presentation/` in 3D.** `GridProjection` (tile ↔ screen math for the flat views) and `Facing` (pick 1 of 4/8 pictures) stay for the 2D renderer. 3D barely needs them: tile (x, y) simply becomes a world position (x metres east, y metres south, height up). A zombie's heading becomes a smooth rotation instead of a snapped picture. We'd add one tiny, tested `WorldMapping3D` file there (presentation-only, Foundation-only, like D-016). **No simulation, rule, or save code changes.**

## 3. Art pipeline: Blender → USDZ

- **Format:** USDZ (Apple's 3D package; Blender exports USD natively). One file per art id, named exactly as today (`bld_hq.usdz`, `zmb_walker.usdz`…), so `Content/*.json` keeps its `sprite` ids unchanged.
- **Buildings and props:** the Blender study (`HighwayHoldout_Blender_Study/models/`) and `tools/blender/*_models.py` already hold real 3D models. A new script `tools/blender/export_usdz.py` would export each one with fixed rules: **1 tile = 1 metre**, origin at the footprint's ground centre, facing +X (the study already uses +X). Good news: the study uses flat palette colours with no texture images, so these files will be small. Bad news: they were modelled to be seen from one angle. Backs, roofs and undersides need checking now that the camera turns, and about 47 assets were never modelled at all (handoff note). **This is the biggest single job.**
- **Zombies/people (Mixamo):** the approved walker (D-026, `zombie-walk-mixamo.md`) is already a rigged 3D character with a walk cycle in FBX. Blender converts it to a USDZ that keeps the skeleton and clips (walk, attack, idle). The game plays "walk" at a speed matched to movement (the stride number already in `presentation.json`), so feet don't slide. Note: shipping the rigged character inside the app is a different use from shipping rendered frames. Re-check Adobe's Mixamo terms and add a DECISIONS line.
- **Missing-model rule (same promise as today):** `ModelRegistry` loads models in the background. Until a model loads, or if it's missing or broken, it draws a **coloured box** the size of the footprint × `placeholderHeightTiles`, **with the art id written on it**. It never crashes. A small checker script lists which art ids have no model yet.
- **Effects:** tracers, muzzle flash and dust become simple glowing shapes or RealityKit particles. Goo becomes a flat decal on the ground. Health bars become small camera-facing bars.

## 4. Can 2D and 3D run side by side? Yes, and they should

Add one field to `Content/presentation.json`, e.g. `"renderer": "sprite2d" | "reality3d"` (plus a DEBUG toggle). The SwiftUI root view shows either the old SpriteKit view or the new 3D view. Both read the same `GameStore` and send the same Commands, so **the same save plays in either view**. The game stays fully playable in 2D at every step. If a 3D chunk stalls, nothing is lost, and the switch makes before/after comparisons on the same town easy. When 3D is good enough, flip the default. Delete 2D later only if you decide to (chunk 6R).

## 5. Performance, battery, app size

- **Target:** 60 fps on the oldest supported iPhone, with the day-40 horde (~35 zombies today, plan for 100+). Today's 2D baseline: 60 fps with 32–35 zombies (~1,400 sprites).
- **What's cheap:** buildings and props (a few hundred simple, untextured models). The 40×30 ground must be **one merged mesh**, not 1,200 tiles.
- **What's expensive:** animated characters. Each skinned zombie is drawn on its own; instancing doesn't help animated meshes. 35 is fine on modern phones; 100+ needs a low-poly zombie (~3–5k triangles), shared materials and maybe simpler animation at a distance. Shadows: one sun light, tuned cascades, and props that don't cast shadows where it doesn't show.
- **Battery/heat:** 3D with shadows uses noticeably more power than 2D sprites. Mitigations: a "Battery saver" setting (lower resolution, no shadows, 30 fps if RealityKit allows capping, which 1R must verify) and drawing less while the town is idle.
- **App size:** art today is ~8 MB. Palette-coloured building models are tiny; textured characters are ~2–5 MB each. Expect the 3D art to add **tens of MB**, far under App Store limits. The 2D sprites can be dropped if 2D is retired.

## 6. Build chunks

Track **R** = 3D renderer code, track **M** = 3D models/art (new letters, so they don't clash with A/B/C). The "Needs" lines below override the global wave rule. These chunks depend **only on each other**, not on the Phase 1 B track. They are not in Phase 1 scope, so you'd add them to `BUILD-QUEUE.md` only after choosing this option.

| Chunk | Goal | Needs | Size |
|---|---|---|---|
| 1R | Go/no-go spike on a real phone | — | S |
| 2R | 3D view behind the switch, placeholder boxes | 1R | M |
| 2M | Blender → USDZ pipeline + buildings/props | 1R | L |
| 3R | Placement, selection, walls in 3D | 2R | M |
| 3M | Animated zombies (+ survivors/defenders) | 2R, 2M | M |
| 4R | Combat effects, overlays, health bars | 3R, 3M | M |
| 5R | Performance pass + make 3D the default | 4R | M |
| 6R | Retire 2D (optional) | 5R + owner yes | S |

**1R — Go/no-go spike.** _Goal:_ see our models in real 3D on an iPhone before committing. _Scope:_ a DEBUG-only RealityKit screen (not wired to the game): ground plane, HQ + 5 study models exported by hand, sun + shadows, orbit camera, 35 then 100 Mixamo walkers walking in circles. Measure fps on the oldest supported phone and in the simulator. Confirm frame-rate capping, iOS 17 vs 18 behaviour, and particle/billboard availability. _Not:_ game hookup, export script, other models. _Exit check:_ screenshots/video next to the current 2D view, an fps table, and a one-page "gaps found" note. You decide go/no-go. _Start prompt:_ "Do chunk 1R from docs/plans/3d-rendering-plan.md: read AGENTS.md and that plan only; build the DEBUG RealityKit spike and report fps and screenshots."

**2R — 3D view behind the switch.** _Goal:_ the real game, playable in 3D with labeled boxes. _Scope:_ `renderer` field in `presentation.json`; shared ticker moved out of `GameScene`; RealityView world; merged ground mesh from the map; orbit camera (pan/zoom/rotate/tilt limits in JSON); ModelRegistry with the labeled-box placeholder; buildings and zombies synced from Core state (same "rebuild on Signature change" rule); `WorldMapping3D` + Core test. _Not:_ placement, effects, real models. _Exit check:_ a game runs in 3D with boxes moving correctly; flipping the switch back gives the unchanged 2D game on the same save; Core tests and build pass. _Start prompt:_ "Implement chunk 2R from docs/plans/3d-rendering-plan.md: read AGENTS.md, docs/MAP.md, docs/features/rendering-art.md and that chunk only."

**2M — Model pipeline + buildings/props.** _Goal:_ every building, defense and decoration has a 3D model in the game. _Scope:_ `tools/blender/export_usdz.py` (scale/origin/facing rules), an import location in `App/`, a missing-model checker; export the study models; finish backs/roofs; model the missing assets in the same style; tower base + turret as separate parts so the turret can aim. _Not:_ characters, code beyond loading. _Exit check:_ the checker reports zero missing for buildings/props; one review screenshot of each model from 4 angles. _Start prompt:_ "Implement chunk 2M from docs/plans/3d-rendering-plan.md: read AGENTS.md, HighwayHoldout_Blender_Study/CLAUDE_HANDOFF.md and that chunk only."

**3R — Placement in 3D.** _Goal:_ building feels as good as the D-022 isometric placement. _Scope:_ ray hit-testing; ghost = see-through model + tile grid + green/red footprint + reason; ghost lifted above the finger; wall-line drag with count/cost; selection outline; range ring on the ground; buildings between camera and ghost fade (works at any camera angle). _Not:_ effects. _Exit check:_ repeat the D-022 simulator checks (1×1, 2×2, 3×3 move + cancel, invalid spots, wall line) in 3D at two camera angles. _Start prompt:_ "Implement chunk 3R from docs/plans/3d-rendering-plan.md: read AGENTS.md, docs/features/input.md and that chunk only."

**3M — Animated characters.** _Goal:_ zombies walk, turn and attack with real animation. _Scope:_ Mixamo walker → USDZ with walk/attack/idle; playback speed from movement; smooth turning; hit flash; runner/brute (Mixamo or a re-tint at first); survivors/defenders if they exist by then. _Not:_ effects. _Exit check:_ normal horde, no foot sliding from 4 camera angles, attack hold works, missing-model box shows if a file is removed. _Start prompt:_ "Implement chunk 3M from docs/plans/3d-rendering-plan.md: read AGENTS.md, docs/features/zombie-walk-mixamo.md and that chunk only."

**4R — Effects and overlays.** _Goal:_ combat reads as well as in 2D. _Scope:_ tracers, muzzle flash, goo decals, dust, building shake, trap flash, health/progress bars, scaffolding/rubble, horde warning arrows, aiming turrets. The same caps as `EventPlayer`. _Not:_ new effects. _Exit check:_ the 1B on-screen defense check (breach, rubble, "Held!") passes in 3D. _Start prompt:_ "Implement chunk 4R from docs/plans/3d-rendering-plan.md: read AGENTS.md, docs/features/rendering-art.md and that chunk only."

**5R — Performance + default.** _Goal:_ 3D is ready to be the normal view. _Scope:_ day-40 and 100-zombie stress tests on the oldest supported phone; low-poly zombie and shadow tuning if needed; Battery saver setting; app-size measurement; make `reality3d` the default. _Not:_ deleting 2D. _Exit check:_ 60 fps at day 40 on the oldest phone (≥45 at 100 zombies), a 30-minute play session without the phone getting hot, a size report. _Start prompt:_ "Implement chunk 5R from docs/plans/3d-rendering-plan.md: read AGENTS.md and that chunk only; start with the stress test."

**6R — Retire 2D (optional).** Remove the SpriteKit renderer, iso sprite import path and top-down art; archive the render scripts. Only on your explicit yes, and only if option (a) in §1 was chosen. Exit check: build + tests pass, and MAP is updated.

## 7. Honest effort and risk

- **Effort:** roughly **25–40 agent work sessions**, plus your time reviewing models and look. Art (2M, 3M) is about half. Staying 2D with the living-world pass is roughly a quarter to a third of that.
- **Risk: medium-high.** Main risks: (1) the hand-made "miniature" charm of the renders can look plainer in real-time 3D unless lighting/materials get real attention; (2) RealityKit gaps for games (found in 1R, not later); (3) a large number of zombies on older phones; (4) two renderers to keep working during the switch, so every new feature (e.g. 3B panels, units) has to be drawn twice until 2D is retired. That last one argues for **not** running 3D in parallel with Phase 1 gameplay chunks.
- **What you get that 2D can't:** turning the camera, real shadows that move with time of day, no "zombie hidden behind the HQ" sorting bugs, smooth facing at any angle, and a pipeline where one Blender model replaces 4–8 rendered pictures per animation frame.

## 8. When it's worth doing
- **Worth it if** after the 2D art redo you still want a turnable camera, a day/night sun with moving shadows, or close-up zoom. Those are things sprites fundamentally can't do.
- **Not worth it if** the goal is "looks richer and more alive". The living-world 2D pass plus the art redo gets most of that for far less.
- **Best timing:** after Phase 1 is finished (chunk 6B), so gameplay isn't being built twice. Chunk 1R alone is cheap and safe any time, and it turns this from a guess into a measured decision.

## Owner decisions needed
1. **Go or no-go on the 1R spike** (small, can be done any time).
2. **Engine:** approve RealityKit (vs. any outside engine, which would need a third-party approval).
3. **Minimum iOS:** raise to 18 for everyone (recommended), or keep iOS 17 with 2D-only on those phones.
4. **Camera:** free rotation, or 4 snapped angles (Tropico-style); how far players may tilt/zoom.
5. **Timing:** after Phase 1 (recommended) or in parallel.
6. **Art:** who makes the ~47 missing models and the backs of existing ones (agent + Blender scripts, ChatGPT, or bought packs), and approval of shipping Mixamo characters inside the app.
7. **Endgame:** once 3D is the default, retire 2D (6R) or keep both.

## Sources checked (2026-10-31)
- Apple: [Bringing your SceneKit projects to RealityKit](https://developer.apple.com/documentation/realitykit/bringing-your-scenekit-projects-to-realitykit.md) (SceneKit soft-deprecated); forum: [SceneKit is now deprecated – when will it be removed?](https://developer.apple.com/forums/thread/795520) (no removal date); [SpriteKit's continued support](https://developer.apple.com/forums/thread/826562) (SpriteKit not deprecated).
- Apple: [Scene content, lights and cameras](https://developer.apple.com/documentation/realitykit/scene-content-lights-and-cameras.md), [DirectionalLightComponent.Shadow](https://developer.apple.com/documentation/realitykit/directionallightcomponent/shadow.md), [DirectionalLight](https://developer.apple.com/documentation/realitykit/directionallight.md) (non-AR virtual camera, shadows).
- Apple: [MeshInstancesComponent](https://developer.apple.com/documentation/realitykit/meshinstancescomponent.md) (GPU instancing, iOS 26+); forum: [RealityKit large-scale practices](https://developer.apple.com/forums/thread/836103) (one draw per mesh; merge meshes that share a material).
- Not confirmed by search: `RealityView` needing iOS 18 on iPhone comes from Apple's WWDC 2024 material as I know it. Chunk 1R must verify it first.

# Chunk RND-001 results — RealityKit go/no-go spike

_2026-11-01. DEBUG-only spike; not wired to the game. Plan: `docs/plans/3d-rendering-plan.md`. Decision context: D-027._

## What was built
- **Open it:** long-press the horde chip → Debug → **3D spike (RND-001)**. Or launch with `-spike3DWalkers 35` (also `-spike3DHost ar|reality`, `-spike3DShadows 0`, `-spike3DCap 1`, `-spike3DCompact 1`, `-spike3DDistance/Pitch/Yaw`) to open it straight away for measuring.
- **Scene:** an 80×80 m ground with a road, plus the HQ, shelter, farm, watchtower (with gunner), car wreck and 5 wood walls. These are the Blender study models exported to USDZ by `tools/blender/spike_export_usdz.py` (1 tile = 1 m, origin at the footprint's ground centre, the same fit-to-footprint rule as the sprite renderer). Files are 29–346 KB each.
- **Light:** one warm, low dusk sun (22° up) with shadows, a weak blue fill light, and RealityKit's built-in ambient light. Tuning lives in `App/Spike3D/spike3d.json`.
- **Camera:** one finger pans, pinch zooms, two-finger twist turns, and a two-finger up/down drag tilts (20°–70°). All four were checked in the simulator (screenshots 05–07).
- **Walkers:** the D-026 Mixamo walker, converted to an animated USDZ (8,144 triangles, 65 bones, 4.0 s walk loop, 6.5 MB). 0, 35 or 100 copies walk in circles at the stride-matched speed, so their feet don't slide.
- **Readout:** fps plus the worst frame time over each half second, shown on screen and printed as `SPIKE3D fps=…`.
- **Two hosts, same scene:** `RealityView` with the virtual camera (iOS 18+), and `ARView` in non-AR mode, which is the only route on iOS 17. On iOS 18+ you can switch between them in the panel.

Files: `App/Spike3D/` (6 Swift files, JSON, `Models/*.usdz`), `tools/blender/spike_export_usdz.py`, plus two small DEBUG hooks in `App/UI/DebugMenuView.swift` and `App/UI/HordeChipView.swift`. To remove the spike, delete those files and undo the hooks.

## FPS table

Each result covers about 10 s after loading (20 half-second samples). Scene: 10 buildings and props plus the walkers.

| Device | Host | Walkers | Shadows | Avg fps | Min fps | Worst frame |
|---|---|---|---|---|---|---|
| iPhone 18 Pro **simulator** (iOS 27) | RealityView | 0 | on | 60.0 | 59.9 | 17 ms |
| ″ | RealityView | 35 | on | 60.0 | 60.0 | 17 ms |
| ″ | RealityView | 100 | on | 60.0 | 60.0 | 17 ms |
| ″ | RealityView | 100 | off | 59.9 | 58.1 | 33 ms (one hitch) |
| ″ | ARView (iOS 17 route) | 0 | on | 59.9 | 58.1 | 34 ms (one hitch) |
| ″ | ARView | 35 | on | 60.0 | 60.0 | 17 ms |
| ″ | ARView | 100 | on | 60.0 | 60.0 | 17 ms |
| ″ | ARView | 100 | off | 60.0 | 60.0 | 17 ms |
| ″ | ARView, "cap 30" | 100 | on | 60.0 | 60.0 | 17 ms (the cap had no effect) |
| **Real iPhone 18 Pro** ("Ramrod18") | RealityView | 0 | on | 60.0 | 58.4 | 30 ms (one hitch) |
| ″ | RealityView | 35 | on | 60.0 | 60.0 | 20 ms |
| ″ | RealityView | 100 | on | 60.0 | 60.0 | 19 ms |
| ″ | RealityView | 100 | off | 60.0 | 60.0 | 19 ms |
| ″ | RealityView, close camera (9 m) | 100 | on | 60.0 | 60.0 | 19 ms |
| ″ | ARView (iOS 17 route) | 0 | on | 60.0 | 59.9 | 22 ms |
| ″ | ARView | 35 | on | 60.0 | 59.9 | 19 ms |
| ″ | ARView | 100 | on | 60.0 | 59.9 | 19 ms |
| ″ | ARView | 100 | off | 60.0 | 59.9 | 18 ms |
| ″ | ARView, "cap 30" | 100 | on | 60.0 | 60.0 | 18 ms (the cap had no effect) |

**Read the simulator rows with care.** The simulator draws with the Mac's graphics chip, so those rows only show that everything *works*. **The real-phone rows are the ones that count.** They were measured on the owner's iPhone 18 Pro, launched over the network, about 10 s per row after loading. The first run with 100 walkers dipped once to 55 fps while it was still loading; a rerun held 60. The phone has a 120 Hz screen, yet RealityKit drew at 60 fps every time. Without a frame-rate setting, 60 looks like RealityKit's normal pace here, and that's fine for this game. **Limit:** this is the newest iPhone. The "oldest supported phone" check planned for RND-005 still needs an older device; an iPhone 15-class phone has a slower graphics chip.

## Questions RND-001 had to answer

1. **iOS 17 or 18?** The SDK (Xcode 27.1) marks `RealityView`, `RealityViewCameraContent` and the `.virtual` camera **iOS 18.0+**. On iOS 17 the only option is `ARView(cameraMode: .nonAR)`. In the spike it shows the same scene, shadows and walkers at the same simulator fps, so iOS 17 *can* draw 3D. The catch is that many tools RND-002–RND-004 want are **also iOS 18+** (next point). The app still targets iOS 17; the spike uses `if #available(iOS 18.0, *)`.
2. **Particles and billboards?** Both exist, but only from iOS 18: `ParticleEmitterComponent` and `BillboardComponent` (iOS 18.0). Also iOS 18-only: `OpacityComponent` (fading buildings in front of the ghost in RND-003), `GroundingShadowComponent`, `DynamicLightShadowComponent`, `ImageBasedLightComponent` / `EnvironmentLightingConfigurationComponent` (ambient-light control), `ShaderGraphMaterial` and `ModelSortGroupComponent`. GPU instancing (`MeshInstancesComponent`) is iOS 26. On iOS 17 each of these needs a hand-made workaround.
3. **Can the frame rate be capped?** **Not with a public API.** `RealityView` has no frame-rate setting. `ARView` only has an undocumented, underscored `__preferredFrameRate`. Setting it to 30 changed nothing in the simulator or on the phone, and it isn't something to rely on for the App Store anyway. RealityKit already stayed at 60 fps on the phone's 120 Hz screen. A "Battery saver" therefore can't promise 30 fps. It can still turn shadows off, simplify the scene and cut work while idle.

## Gaps found (one page)
- **Minimum iOS (biggest decision).** Keeping iOS 17 means two 3D code paths (ARView and RealityView), or ARView only and losing particles, billboards, opacity fades and ambient control. Raising the minimum to iOS 18 removes all of that. **Recommend iOS 18**, as the plan already suggests.
- **No frame-rate cap** (see 3). Battery saver has to use other knobs. Measure heat on the phone in RND-005.
- **Look is plainer than the Blender mockup** (compare screenshot 01 with `mockups/option2-3d-rendering.png`). There's no ambient occlusion and the shadows are softer and lighter. The sun had to go up to 12,000 lux to beat the built-in ambient light. Fixable on iOS 18 with a custom ambient-light map plus `GroundingShadowComponent`; the materials need tuning too. That's a MOD-001/RND-005 art task, not a blocker.
- **Loading.** Loading on the main thread took 0.7–1.1 s for the 6 building models and 0.14–0.8 s for the walker (simulator). RND-002 must load in the background (`Entity(named:)` async is iOS 18+; iOS 17 has the older `loadAsync`). The ModelRegistry placeholder box covers the wait.
- **Walker tempo.** One 4.0 s clip is one 0.615-tile loop, so feet match at 0.154 tiles/s. The game walker moves at 0.6 tiles/s, so MOD-002 must play the clip about 3.9× faster (`AnimationPlaybackController.speed`). That's the same distance-driven rule the 2D walker uses.
- **Walker weight.** 8k triangles and 1024 px textures (6 maps), 6.5 MB. 100 copies held 60 fps on the iPhone 18 Pro, even with shadows and a close camera. On older phones RND-005 may still need a lighter zombie, as the plan predicted. **Mixamo licence:** the USDZ holds the rigged character, so it's kept out of git like the FBX (`.gitignore`). Shipping it still needs the Adobe terms check and a DECISIONS line (plan §3).
- **Camera feel.** Pinch is too sensitive. Minimum zoom lets the camera go inside the HQ roof (screenshot 05). Zoom aims at the screen centre, not the fingers. The ground edge shows at maximum zoom-out (screenshot 06). These are small RND-002 fixes: tuning, a collision-free minimum height, and clamping zoom to the map.
- **Export details that worked:** Blender's `convert_orientation` (Z-up → Y-up) gives Blender +X = RealityKit +X and Blender +Y = RealityKit −Z (north). Curves (the HQ antenna) had to be converted to meshes, and bevel modifiers export already applied. Keep all three rules in MOD-001's real `export_usdz.py`.
- **Housekeeping.** The `App/` synced folder copies the spike's USDZ files (~7 MB with the walker) into Release builds too; the Swift code is DEBUG-only. Delete `App/Spike3D/` before any TestFlight build, or once RND-002 has its own model folder. The game also keeps running behind the spike screen, so RND-002's shared ticker must pause or own the clock. The simulator test save advanced about 5 game-minutes during these runs. It was backed up afterwards and restored after the 2D check, but the earlier change can't be undone.
- **No blockers found:** USDZ export, shadows, skinned animation, cloning 100 animated characters and the orbit camera all worked first time on both hosts.

## Recommendation
**GO for RND-002 and MOD-001, with the minimum raised to iOS 18.** The condition is met: the real iPhone held 60 fps with 35 *and* 100 walkers, with shadows, on both screen types. Nothing found blocks the 3D route. iOS 17 could draw it too, but only by giving up particles, fades and billboards, or by keeping a second code path, so iOS 18 is the better trade. Still to check later (RND-005): an older phone, and heat over a 30-minute session.

## How to rerun
```sh
/Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/spike_export_usdz.py -- App/Spike3D/Models
xcodebuild -scheme HighwayHoldout -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build
# real phone (developer profile already trusted on it; keep the phone unlocked):
xcodebuild -scheme HighwayHoldout -destination 'id=00008160-0006602A1A80000A' -allowProvisioningUpdates DEVELOPMENT_TEAM=N4S7KFD2LW build
xcrun devicectl device install app --device 00008160-0006602A1A80000A <DerivedData>/Build/Products/Debug-iphoneos/HighwayHoldout.app
xcrun devicectl device process launch --device 00008160-0006602A1A80000A --console --terminate-existing com.highwayholdout.app -- -spike3DWalkers 100 -spike3DHost reality -spike3DCompact 1
```
The team id is passed on the command line only; the project file is unchanged. The walker USDZ needs the local Mixamo FBX. Without it, the spike shows "walker MISSING" and runs without walkers.

## Screenshots (`spike-1R/`)
01 hero view, 35 walkers · 02 control panel · 03 100 walkers on RealityView · 04 the same on ARView (the iOS 17 route; looks identical) · 05 pinch close-up (walker detail and shadows) · 06 after twist + zoom-out · 07 tilted near top-down · 08 the current 2D game on the same simulator, for comparison.

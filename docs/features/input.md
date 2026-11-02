# Feature: Input (camera, placement, selection)

> **3D only (D-030).** Placing, moving, selecting and the wall tool work again in 3D since chunk RND-003 (2026-11-01, D-032).

## Purpose
Lets the player look around the map and place, move, select, and demolish buildings with simple touches.

## Files involved
- `App/Input/OrbitGestures3D.swift` — the touch layer over the 3D view: one finger pans, pinch zooms toward the fingers, two-finger twist turns 90°, two-finger up/down drag tilts (pans instead in the wall tool). Taps and one-finger drags go to `PlacementTouches3D` first.
- `App/Input/PlacementTouches3D.swift` — finger → ray → ground tile and the building hit first; tap (select / move ghost / one-wall line), ghost drag (lifted `dragLiftPoints` above the finger), wall-line drag.
- `Core/Sources/HoldoutCore/Presentation/OrbitCamera3D.swift` — the camera math and every limit; `ray(screenX:…)` for touches (tested in `OrbitCamera3DTests`, `RayPicking3DTests`).
- `Core/Sources/HoldoutCore/Presentation/RayPicking3D.swift` — `Ray3D`, `Box3D`, nearest box hit (tall roof in front wins), occluders between camera and ghost (tested).
- `App/Input/PlacementController.swift` — mode (idle / selected / placing / moving / drawingLine), ghost position, Core's validity check, the Command "Confirm" sends, whether to keep placing after Confirm.
- `App/Input/PlacementMessages.swift` — Core `PlacementProblem` / `CommandError` → short player text.
- `App/Rendering/PlacementLayer3D.swift` — draws the ghost (see-through model or box), tile grid, green/red footprint, the wall tool's planned line.
- `App/Rendering/SelectionLayer3D.swift` — yellow footprint outline + range ring of the selected building.
- `App/Rendering/OccluderFader3D.swift` — fades buildings between the camera and the ghost.
- `App/Rendering/OverlayMeshes3D.swift` — flat see-through ground shapes (tiles, outlines, ring) as merged meshes.
- `App/Rendering/BuildingLayer3D.swift` → `pickBoxes` — one box per building (footprint × roof height: the real model's once loaded, else the placeholder's).
- `App/UI/PlacementBarView.swift`, `WallLineBarView.swift` — the bars (Confirm/Cancel, Move/Demolish, wall count/cost/Build).

## Data files
- `Content/presentation.json` → `reality3d.camera`: `fieldOfViewDegrees`, `startDistance` / `minDistance` / `maxDistance` (metres to the looked-at point), `minHeightMetres` (never lower: no flying into roofs), `startPitchDegrees` / `minPitchDegrees` / `maxPitchDegrees`, `tiltDegreesPerPoint`, `startYawDegrees` (45 = from the south-east, like the old iso view), `snapAngles` (4), `twistThresholdDegrees`, `snapTurnSeconds`, `pinchSensitivity` (1 = follow the fingers; 0.6 = calmer), `panMarginTiles`.
- Placement: none directly. Validity comes from Core (`GameLoop.checkPlacement` / `checkMove` / `planLine`), which reads `buildings.json` and the map.
- Look-only constants (not tuning, so Swift, like 2D had): `PlacementLayer3D.gridRadius` (6 tiles), `ghostOpacity` / `plannedWallOpacity` (0.6), `PlacementTouches3D.dragLiftPoints` (56), `OccluderFader3D.fadedOpacity` (0.3), overlay lifts/line widths in `OverlayMeshes3D`.

## Key rules
- **3D camera (D-029):** turns only in 90° steps. A two-finger twist past `twistThresholdDegrees` swings one step (eased, `snapTurnSeconds`); **one twist = one step** (lift and twist again for the next). Clockwise fingers turn the world clockwise. Pinch keeps the ground under the fingers in place. Zoom-out stops at `maxDistance` or when the map (seen from the current angle) fills the screen width, whichever is closer. The looked-at point stays within the map plus `panMarginTiles`.
- DEBUG launch argument `-debug3DSnap N` opens at snap angle N (screenshots without touches).
- **What a finger points at (D-032):** a ray from the camera through the finger. The building whose box it enters first wins (a tall roof in front beats what is behind it, and beats the ground tile under the finger); otherwise the ground tile where the ray meets the ground.
- Tap a building → select it: yellow outline on its footprint, a range ring on the ground for towers and the HQ (`effects.range`), and the selection bar (Move, Demolish, close). Tap empty ground → deselect.
- Build menu → pick a building → ghost appears at the screen center. Tap anywhere to move it there, or drag it: a drag that starts on the ghost (its tiles or its body) moves it, held `dragLiftPoints` above the finger; any other one-finger drag pans. It snaps to tiles and never leaves the map.
- While placing/moving: a tile grid around the ghost (`gridRadius` tiles), tiles that can never be built on (highway, wrecks, trees) tinted red, the footprint green (fine) or red (strong red = blocked/occupied tiles, light red = cost, limit, HQ level), the reason in the bar. Confirm is disabled while red. Validity is re-checked every frame.
- Buildings standing between the camera and the ghost fade to `fadedOpacity` and come back as soon as they stop hiding it, or on Confirm/Cancel; works from all 4 camera angles (rays from the camera to points on the ghost). Presentation only.
- Nothing changes until Confirm, which sends `.placeBuilding` / `.moveBuilding`. Cancel puts things back (move → the building stays and is selected again). Demolish asks first and shows the refund.
- After confirming a 1×1 defense (towers, traps) you stay in placing mode with the same type. Other buildings get selected after placing.
- **Wall tool** (any `category: "wall"` 1×1, i.e. wood and metal walls): one finger drags a line from where the drag starts to where it ends (straight, or an L along the longer side first); a tap plans a single wall. Planned walls show see-through on green tiles (orange if the line can't be built), turned along the line; red tiles (blocked, over the limit) are skipped, as are tiles that already have this wall. The bar shows count, total cost and what's skipped; **Build** places the whole line (disabled if you can't afford all of it), **Done** leaves; after Build the tool stays open. In the wall tool **two fingers pan** the map (they tilt everywhere else). No fading in the wall tool.

## Known issues
- Simulator testing: the simulator control tool's plain `tap` leaves the finger down until the next input (buttons stay pressed, then fire later). Use a `touch_path` with a down and an up point for taps. Screenshots of the 3D view can lag a frame; take a second one.
- Decorations (trees, wrecks) don't fade in front of the ghost yet; only buildings do (decorations are low boxes today; revisit with MOD-001 models).

## Change log
- 2026-11-01 — Chunk RND-003: placement, selection and the wall tool rebuilt in 3D (ray picking in Core, ghost/grid/footprint, lifted drag, wall line, outline + range ring, occluder fading from any angle; two-finger pan in the wall tool). D-032.
- 2026-11-01 — 2D retired (D-030): 2D camera, taps, ghost/wall drawing removed; placement off until RND-003. 3D orbit camera (RND-002): pan, pinch toward fingers, one-step snapped twist, tilt, min height, map-clamped zoom.
- 2026-10-31 — Wall tool: drag a line, see count + cost, Build all at once; two-finger pan.
- 2026-10-31 — D-022 isometric placement: grid, lifted drag, occluder fading; auto top-down off (old saved setting reset).
- 2026-10-31 — Recorded owner-approved isometric placement direction and staged rollout (D-022); documentation only, implementation pending.
- 2026-10-31 — 1B: keep placing after confirming a 1×1 defense; range ring on a selected tower.
- 2026-10-31 — 1V: auto top-down while placing/moving, iso roof taps, per-view camera limits from JSON.
- 2026-10-31 — Created (1A): camera pan/zoom/bounds, ghost preview with snap + red tiles, confirm, move, demolish.

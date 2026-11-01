# Feature: Input (camera, placement, selection)

> **2D retired (D-030, 2026-11-01):** the map is 3D only. The camera below is the 3D orbit camera. **Placing, moving, selecting and the wall tool are off until chunk 3R** rebuilds them in 3D; the logic (`PlacementController`, `PlacementMessages`, the SwiftUI bars) is kept for that. The "Placement rules (2D, to rebuild in 3R)" list is the target behaviour.

## Purpose
Lets the player look around the map and place, move, select, and demolish buildings with simple touches.

## Files involved
- `App/Input/OrbitGestures3D.swift` — 3D camera touches: one finger pans, pinch zooms toward the fingers, two-finger twist turns 90°, two-finger up/down drag tilts. Taps do nothing yet (3R).
- `Core/Sources/HoldoutCore/Presentation/OrbitCamera3D.swift` — the camera math and every limit (tested in `OrbitCamera3DTests`).
- `App/Input/PlacementController.swift` — mode (idle / selected / placing / moving), ghost position, Core's validity check, the Command "Confirm" sends, whether to keep placing after Confirm.
- `App/Input/PlacementMessages.swift` — Core `PlacementProblem` / `CommandError` → short player text.
- `App/UI/WallLineBarView.swift` — the wall tool's bar (plan from Core `GameLoop.planLine`); its 3D preview is 3R.

## Data files
- `Content/presentation.json` → `reality3d.camera`: `fieldOfViewDegrees`, `startDistance` / `minDistance` / `maxDistance` (metres to the looked-at point), `minHeightMetres` (never lower: no flying into roofs), `startPitchDegrees` / `minPitchDegrees` / `maxPitchDegrees`, `tiltDegreesPerPoint`, `startYawDegrees` (45 = from the south-east, like the old iso view), `snapAngles` (4), `twistThresholdDegrees`, `snapTurnSeconds`, `pinchSensitivity` (1 = follow the fingers; 0.6 = calmer), `panMarginTiles`.
- Placement: none directly. Validity comes from Core (`GameLoop.checkPlacement` / `checkMove`), which reads `buildings.json` and the map.

## Key rules
- **3D camera (D-029):** turns only in 90° steps. A two-finger twist past `twistThresholdDegrees` swings one step (eased, `snapTurnSeconds`); **one twist = one step** (lift and twist again for the next). Clockwise fingers turn the world clockwise. Pinch keeps the ground under the fingers in place. Zoom-out stops at `maxDistance` or when the map (seen from the current angle) fills the screen width, whichever is closer. The looked-at point stays within the map plus `panMarginTiles`.
- DEBUG launch argument `-debug3DSnap N` opens at snap angle N (screenshots without touches).

### Placement rules (2D, to rebuild in 3R)
- **Wall tool** (any `category: "wall"` 1×1, i.e. wood and metal walls): one finger drags out a line from where the drag starts to where it ends (straight, or an L with one corner along the longer side first); a tap plans a single wall. Planned walls show see-through on green tiles; red tiles (blocked, over the limit) and tiles that already have this wall are skipped and not charged. The bar shows count, total cost, and what's skipped; **Build** places the whole line at once (disabled if you can't afford all of it), **Done** leaves. After Build the tool stays open. Two fingers pan the map (always, in every mode). No building fading in the wall tool.
- Tap a building → select it (bottom bar: Move, Demolish, close). Tap empty ground → deselect.
- Placing and moving happen in **isometric** (D-022). Top-down is only a manual fallback (view button); the old auto-flip is off (`presentation.json autoTopDownWhilePlacing: false`) and the pre-D-022 saved setting is ignored (UserDefaults key bumped to `.v2`). Long-press the view button to turn auto-flip back on for testing.
- While placing: a tile grid around the ghost (`PlacementOverlay.gridRadius` tiles), tiles that can never be built on tinted red, the footprint green/red, the reason in the bar.
- Buildings and decorations drawn in front of the ghost fade to `PlacementOverlay.occluderAlpha` and come back as soon as they stop covering it, or on Confirm/Cancel. Presentation only.
- Dragging the ghost keeps it `GameScene.dragLiftPoints` above the finger, so the finger never hides it; a drag can start on its tiles or its picture.
- Build menu → pick a building → ghost appears at the screen center. Tap or drag the ghost to move it; it snaps to tiles and never leaves the map.
- A drag that starts on the ghost moves the ghost; any other drag pans the camera.
- Strong red tiles = blocked/occupied/highway; light red everywhere = something else (cost, limit, HQ level); the bar says why. Confirm is disabled while red.
- Validity is re-checked every frame (resources change as they tick).
- Nothing changes until Confirm, which sends `.placeBuilding` / `.moveBuilding`. Demolish asks first and shows the refund.
- After confirming a 1×1 defense (`buildings.json defenses`: walls, traps, towers) you stay in placing mode with the same type, so laying a wall line is tap + Confirm per tile. Other buildings get selected after placing.
- Selecting a tower (or the HQ) shows its range ring.

## Known issues
- (none yet)

## Change log
- 2026-11-01 — 2D retired (D-030): 2D camera, taps, ghost/wall drawing removed; placement off until 3R. 3D orbit camera (2R): pan, pinch toward fingers, one-step snapped twist, tilt, min height, map-clamped zoom.
- 2026-10-31 — Wall tool: drag a line, see count + cost, Build all at once; two-finger pan.
- 2026-10-31 — D-022 isometric placement: grid, lifted drag, occluder fading; auto top-down off (old saved setting reset).
- 2026-10-31 — Recorded owner-approved isometric placement direction and staged rollout (D-022); documentation only, implementation pending.
- 2026-10-31 — 1B: keep placing after confirming a 1×1 defense; range ring on a selected tower.
- 2026-10-31 — 1V: auto top-down while placing/moving, iso roof taps, per-view camera limits from JSON.
- 2026-10-31 — Created (1A): camera pan/zoom/bounds, ghost preview with snap + red tiles, confirm, move, demolish.

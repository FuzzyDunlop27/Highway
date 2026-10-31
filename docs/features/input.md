# Feature: Input (camera, placement, selection)

> **Approved direction, implementation pending (D-022):** improve isometric placement with a ground grid, clear footprint/validity feedback, draggable preview and temporary occluder fading. Once verified on iPhone, disable auto-top-down switching; keep the manual top-down fallback during testing. Existing behavior described below is unchanged in code. See `docs/PHASE1-TASKS.md` → Approved update — isometric placement first.

## Purpose
Lets the player look around the map and place, move, select, and demolish buildings with simple touches.

## Files involved
- `App/Input/CameraController.swift` — one-finger pan, pinch zoom toward the fingers, keeps the view inside the map.
- `App/Input/PlacementController.swift` — mode (idle / selected / placing / moving), ghost position, Core's validity check, the Command "Confirm" sends, whether to keep placing after Confirm.
- `App/Input/PlacementMessages.swift` — Core `PlacementProblem` / `CommandError` → short player text.
- `App/Rendering/GameScene.swift` — turns UIKit gestures (tap, pan, pinch) into the calls above; ignores touches during a view fade.
- `App/Rendering/PlacementOverlay.swift` — placement grid + fading of buildings that hide the ghost.
- `App/Input/HitTesting.swift` — isometric taps: the front-most building drawn under the finger wins (tall roofs), else the ground tile.
- `App/Rendering/Nodes/GhostNodeFactory.swift` — draws the ghost (green tiles = ok, red = blocked).

## Data files
- None directly. Validity comes from Core (`GameLoop.checkPlacement` / `checkMove`), which reads `buildings.json` and the map.

## Key rules
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
- Camera zoom limits come from `presentation.json` per view (`minScale`, `startScale`). Max zoom-out = the map's box fills the screen. On a view switch the zoom scales by the tile-width ratio so about the same area stays on screen.

## Known issues
- (none yet)

## Change log
- 2026-10-31 — D-022 isometric placement: grid, lifted drag, occluder fading; auto top-down off (old saved setting reset).
- 2026-10-31 — Recorded owner-approved isometric placement direction and staged rollout (D-022); documentation only, implementation pending.
- 2026-10-31 — 1B: keep placing after confirming a 1×1 defense; range ring on a selected tower.
- 2026-10-31 — 1V: auto top-down while placing/moving, iso roof taps, per-view camera limits from JSON.
- 2026-10-31 — Created (1A): camera pan/zoom/bounds, ghost preview with snap + red tiles, confirm, move, demolish.

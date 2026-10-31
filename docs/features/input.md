# Feature: Input (camera, placement, selection)

## Purpose
Lets the player look around the map and place, move, select, and demolish buildings with simple touches.

## Files involved
- `App/Input/CameraController.swift` — one-finger pan, pinch zoom toward the fingers, keeps the view inside the map.
- `App/Input/PlacementController.swift` — mode (idle / selected / placing / moving), ghost position, Core's validity check, the Command "Confirm" sends.
- `App/Input/PlacementMessages.swift` — Core `PlacementProblem` / `CommandError` → short player text.
- `App/Rendering/GameScene.swift` — turns UIKit gestures (tap, pan, pinch) into the calls above; ignores touches during a view fade.
- `App/Input/HitTesting.swift` — isometric taps: the front-most building drawn under the finger wins (tall roofs), else the ground tile.
- `App/Rendering/Nodes/GhostNodeFactory.swift` — draws the ghost (green tiles = ok, red = blocked).

## Data files
- None directly. Validity comes from Core (`GameLoop.checkPlacement` / `checkMove`), which reads `buildings.json` and the map.

## Key rules
- Tap a building → select it (bottom bar: Move, Demolish, close). Tap empty ground → deselect.
- Placing or moving flips to the top-down view (if `autoTopDownWhilePlacing`, long-press the view button to turn off) and back on Confirm/Cancel.
- Build menu → pick a building → ghost appears at the screen center. Tap or drag the ghost to move it; it snaps to tiles and never leaves the map.
- A drag that starts on the ghost moves the ghost; any other drag pans the camera.
- Strong red tiles = blocked/occupied/highway; light red everywhere = something else (cost, limit, HQ level); the bar says why. Confirm is disabled while red.
- Validity is re-checked every frame (resources change as they tick).
- Nothing changes until Confirm, which sends `.placeBuilding` / `.moveBuilding`. Demolish asks first and shows the refund.
- Camera zoom limits come from `presentation.json` per view (`minScale`, `startScale`). Max zoom-out = the map's box fills the screen. On a view switch the zoom scales by the tile-width ratio so about the same area stays on screen.

## Known issues
- (none yet)

## Change log
- 2026-10-31 — 1V: auto top-down while placing/moving, iso roof taps, per-view camera limits from JSON.
- 2026-10-31 — Created (1A): camera pan/zoom/bounds, ghost preview with snap + red tiles, confirm, move, demolish.

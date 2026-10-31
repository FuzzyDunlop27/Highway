# Feature: HUD & UI

## Purpose
The SwiftUI layer over the map: resource bar, build menu, and the bottom bars for placing and for a selected building.

## Files involved
- `App/HighwayHoldoutApp.swift` — entry point; creates `GameStore`, saves when the app leaves the foreground.
- `App/GameStore.swift` — @Observable bridge: loads content + save, owns Core's `GameLoop`, advances it from frame time, sends Commands, exposes `resources` / `selectedBuilding` / `notice`.
- `App/UI/GameRootView.swift` — `SpriteView` + overlays; view toggle button (top right; long-press: "Top-down while building"); `ArtIcon` (art id in SwiftUI); notice banner; load-error screen.
- `App/UI/KitStyle.swift` — ChatGPT's UI kit (`HighwayHoldout_UI_Kit/`): token colors, stretchable panels/buttons/cards, tinted glyphs, icon buttons, labels.
- `App/UI/HUDView.swift` — dark kit chips: food, scrap (amount/cap, +rate/min), survivors (count/housing, idle).
- `App/UI/BuildMenuView.swift` — kit drawer of building cards (3/4 picture, name, L1 cost; disabled card + red cost if you can't afford it).
- `App/UI/PlacementBarView.swift` — kit bars: Confirm/Cancel while placing or moving; Move/Demolish/close and a progress bar for a selected building.

## Data files
- `Content/resources.json` → `resources[*].icon`, `displayName` (HUD icons/labels).
- `Content/buildings.json` → `buildings[*]` (menu: `displayName`, `sprite`, `levels[0].cost`), `rules.demolishRefundPct` (refund shown before demolishing).

## Key rules
- Menu art comes from `Art/UI/` (import with `tools/import_art.py HighwayHoldout_UI_Kit/png --view ui`). Building pictures: `ui_build_<id>` (or `ui_build_<first word>`, so `wall_wood` → `ui_build_wall`), else the isometric sprite (`ArtRegistry.menuImage`).
- HUD icons come from `resources.json` `icon` (now the kit's `ui_item_food/scrap/survivors`).
- `GameStore.activeView` = top-down while placing (if auto is on), else the player's choice. View choices live in UserDefaults, not the save.
- UI never changes game state; every action is a Core `Command` sent through `GameStore`.
- `GameStore.resources` / `selectedBuilding` are reassigned only when they change, so SwiftUI doesn't redraw 60×/s.
- The build menu lists `buildings.json buildings` only; defenses join the menu in 1B.
- If `Content/` fails to load, a full-screen message shows the loader's error (file + problem) instead of the game.

## Known issues
- No speed buttons yet (pause/1x/2x is 1C).

## Change log
- 2026-10-31 — Adopted ChatGPT's UI kit for the HUD chips, build cards, buttons, bars, glyphs, and view button.
- 2026-10-31 — View toggle button + view preferences in GameStore (1V).
- 2026-10-31 — Created (1A): HUD resource bar, build menu, placement/selection bars.

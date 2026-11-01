# Feature: HUD & UI

## Purpose
The SwiftUI layer over the map: resource bar + horde chip, horde banners, build menu (Buildings / Defenses), the bottom bars for placing and for a selected building, and a DEBUG menu.

## Files involved
- `App/HighwayHoldoutApp.swift` — entry point; creates `GameStore`, saves when the app leaves the foreground.
- `App/GameStore.swift` — @Observable bridge: loads content + save, owns Core's `GameLoop`, advances it when `GameTicker` asks (returns the frame's events), sends Commands, exposes `resources` / `hordeStatus` / `banner` / `selectedBuilding` / `notice`; `isClockPaused`.
- `App/GameTicker.swift` — the game clock (display link), separate from drawing.
- `App/UI/GameRootView.swift` — the 3D map (`Reality3DView`) + overlays; `ArtIcon` (art id in SwiftUI); notice banner; load-error screen. The Build button is back since chunk 3R.
- `App/UI/KitStyle.swift` — ChatGPT's UI kit (`HighwayHoldout_UI_Kit/`): token colors, stretchable panels/buttons/cards, tinted glyphs, icon buttons, labels.
- `App/UI/HUDView.swift` — dark kit chips: food, scrap (amount/cap, +rate/min), survivors (count/housing, idle), then the horde chip.
- `App/UI/SpeedButtonsView.swift` — pause / 1x / 2x buttons at the end of the HUD row, one per `economy.json speedOptions` entry (kit pause/play/speed glyphs; the current one is teal). Taps send `.setSpeed`; the choice lives in the save.
- `App/UI/HordeChipView.swift` — "Day N / next horde 3:12" (clock glyph); red with the alert glyph during the warning; "Horde! / 23 left" during an attack. Long-press (DEBUG) opens the debug menu.
- `App/UI/HordeBannerView.swift` — `HordeBanner` (from `.hordeStarted`, `.hordeEnded(.held)` → "Held! +X scrap", `.hordeEnded(.hqFell)` → "HQ fell: −X") and its kit dialog panel; hides after 4 s or on tap.
- `App/UI/DebugMenuView.swift` — DEBUG builds only: Horde now, +500 food & scrap, Kill all zombies (Core debug commands), open the 1R 3D spike (the game clock pauses while it's open).
- `App/UI/BuildMenuView.swift` — kit drawer with Buildings / Defenses tabs (`ui_tab_normal` / `ui_tab_selected`) of cards (3/4 picture, name, L1 cost; disabled card + red cost if you can't afford it). The tab is remembered while the app runs.
- `App/UI/PlacementBarView.swift` — kit bars: Confirm/Cancel while placing or moving; Move/Demolish/close, a progress bar, a health bar when damaged, and Repair / Rebuild (rubble) for a selected building.

- `App/JobsSnapshot.swift` — what the job panels draw (population, build queue, defenders, training/run/research timers in whole seconds, the selected building's job); `GameStore.jobs` is reassigned only when it changes.
- `App/GameStore+Jobs.swift` — the panel actions: upgrade, cancel job, worker −/+, train/cancel training, garrison/recall, choose a hold spot, start/collect run, start research. All send Core Commands; a "no" shows Core's reason as a notice.
- `App/UI/BuildingPanelView.swift` — panel above the selection bar for a finished building: tinted level badge, Upgrade (cost; teal when possible, cream when Core says no, progress while upgrading), Workers −/+, then the building's own section. Also `PanelFormat`.
- `App/UI/BarracksSection.swift` — Train (cost), the training queue with cancel, defender cards (status, hp, Post… menu: wait at HQ, hold a spot, man a tower); `TowerGarrisonSection` for Watchtower/MG Nest (assign or release a defender).
- `App/UI/ScavengerSection.swift` — runs unlocked at the post's level (time, survivors, cost, reward × level multiplier), Send, run timer, Collect for the reward waiting at the post.
- `App/UI/WorkshopSection.swift` — research items (effect, time at this Workshop level, cost, HQ gate), Research button, progress, Known.
- `App/UI/BuildQueueStripView.swift` — "Building 2/3 · 1/6 waiting · 4 free hands" under the HUD while any job runs or waits.
- `App/Rendering/DefenderLayer3D.swift` — defenders as labeled boxes (`unit_defender`): in a row below the HQ, on their tower, on their held spot; hidden while knocked out.

## Data files
- `Content/resources.json` → `resources[*].icon`, `displayName` (HUD icons/labels).
- `Content/buildings.json` → `buildings[*]` and `defenses[*]` (menu tabs: `displayName`, `sprite`, `levels[0].cost`; `levels[].hp` for the health bar), `rules.demolishRefundPct` (refund shown before demolishing).

## Key rules
- Menu art comes from `Art/UI/` (import with `tools/import_art.py HighwayHoldout_UI_Kit/png --view ui`). Building pictures: `ui_build_<id>` (or `ui_build_<first word>`, so `wall_wood` → `ui_build_wall`), else the old isometric picture kept in `Art/Menu/` (`ArtRegistry.menuImage`).
- HUD icons come from `resources.json` `icon` (now the kit's `ui_item_food/scrap/survivors`).
- Panels never decide anything: a button is drawn cream instead of teal when Core's `upgradeProblem` / `trainingProblem` / `runProblem` / `researchProblem` says no, and pressing it shows that reason.
- UI never changes game state; every action is a Core `Command` sent through `GameStore`.
- `GameStore.resources` / `selectedBuilding` / `hordeStatus` are reassigned only when they change (the horde countdown only to the whole second), so SwiftUI doesn't redraw 60×/s.
- Banners come from events drained in `GameStore.advance`; a newer banner replaces the one showing.
- Repair/Rebuild sends `.repair(id:)`; Core decides cost and time. The button shows the current repair-cost preview.
- The debug menu and `GameStore.sendDebug` exist only in DEBUG builds.
- If `Content/` fails to load, a full-screen message shows the loader's error (file + problem) instead of the game.

## Known issues
- Eight build cards (scavenger, workshop, barracks, storage, metal wall, MG nest, spikes, barbwire) still use the old isometric pictures from `Art/Menu`; only five have kit-style `ui_build_*` art. No card is a placeholder. New kit art goes in with `tools/import_art.py --view ui`.

## Change log
- 2026-11-01 — Chunk 3B: upgrade button + level badge, build-queue strip, worker −/+, Barracks/defender/garrison, Scavenger Post and Workshop panels, defenders drawn in 3D, cancel-job button, range ring includes research bonus.
- 2026-11-01 — Chunk 1C: speed buttons in the HUD (pause/1x/2x from `speedOptions`, remembered by the save). `GameStore.speed` / `setSpeed`.
- 2026-11-01 — Chunk 3R: Build button and placement/selection bars switched back on (the `canBuildIn3D` flag is gone).
- 2026-11-01 — 2D retired (D-030): view toggle and its UserDefaults settings removed (old keys cleared on launch); Build button hidden until 3R; game clock moved to `GameTicker`; clock pauses behind the DEBUG spike.
- 2026-10-31 — Finished portable UI art delivery: 89 PNGs, editable sources, manifest/cap insets, four previews and Claude handoff; review recorded under docs/reviews. Inventory/pause previews remain design references.
- 2026-10-31 — 1B App: horde chip + debug menu, horde banners, build menu tabs (Buildings / Defenses), health bar + Repair/Rebuild in the selection bar.
- 2026-10-31 — Adopted ChatGPT's UI kit for the HUD chips, build cards, buttons, bars, glyphs, and view button.
- 2026-10-31 — View toggle button + view preferences in GameStore (1V).
- 2026-10-31 — Created (1A): HUD resource bar, build menu, placement/selection bars.

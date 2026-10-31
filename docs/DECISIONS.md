# DECISIONS — why things are the way they are

_Append-only. Newest at the bottom. Add an entry for any non-obvious choice, so nobody "fixes" it later by accident. To reverse a decision, add a new entry that says which one it replaces; don't delete the old one._

**Format**
```
## D-NNN — Short title (YYYY-MM-DD) [Accepted | Proposed | Replaced by D-NNN]
**Decision:** one sentence.
**Why:** one or two sentences.
```

---

## D-001 — Swift 6 + SwiftUI + SpriteKit (2026-10-31) [Accepted]
**Decision:** Native Swift 6; SwiftUI for menus/HUD, SpriteKit (via `SpriteView`) for the game world, `@Observable` for state.
**Why:** All built into iOS, no engines or licenses, and best supported by AI coding agents. SpriteKit is plenty for a 2D top-down game with a few hundred sprites.

## D-002 — Simulation in its own package (Core/App split) (2026-10-31) [Accepted]
**Decision:** All game rules live in Swift package `HoldoutCore` with no SpriteKit/UIKit imports; the app only draws it and sends commands.
**Why:** Rules can be unit-tested in seconds without a simulator (even on Linux, e.g. Codex cloud), and agents can fix logic bugs without touching UI code.

## D-003 — Fixed-timestep, deterministic simulation (2026-10-31) [Accepted]
**Decision:** Core advances in fixed ticks (rate set in `Content/economy.json`) and uses only seeded random numbers.
**Why:** Same inputs give the same result every time, so bugs are reproducible in a test, and 2x speed / offline catch-up are just "run more ticks."

## D-004 — All tuning in Content/*.json (2026-10-31) [Accepted]
**Decision:** Costs, stats, timers, and caps live in JSON files loaded at runtime; none are hardcoded in Swift.
**Why:** Balance tweaks become one-line data edits the owner can make or review, with no risk of breaking code.

## D-005 — Saves are versioned JSON files, not SwiftData (2026-10-31) [Accepted]
**Decision:** The whole game state is encoded with `Codable` to one JSON file with a `version` number and explicit migrations.
**Why:** Simple, readable, diff-able, testable in Core, and works offline. SwiftData would tie the save format to Apple frameworks Core can't import and makes migrations harder to see.

## D-006 — Flow-field pathing toward the HQ (2026-10-31) [Accepted]
**Decision:** One shared cost grid toward the HQ; every zombie follows it. Walls are passable at high cost (zombies bash through).
**Why:** Cheap for hundreds of zombies (recomputed only when buildings change) and naturally makes zombies pile up at the weakest point, which is the core design hook.

## D-007 — No game over (2026-10-31) [Accepted]
**Decision:** If the HQ falls, the horde ends, the player loses a % of stored resources (in `Content/economy.json`), and destroyed buildings become repairable rubble.
**Why:** The game is meant to be relaxing to come back to; a setback keeps tension without wiping hours of progress.

## D-008 — Placeholder art by default (2026-10-31) [Accepted]
**Decision:** `ArtRegistry` draws a labeled colored shape when an image is missing; a correctly named PNG replaces it with no code change.
**Why:** The game is playable from day one, and art from ChatGPT can arrive in any order.

## D-009 — Horde size scales with built value, not stored resources (2026-10-31) [Proposed]
**Decision:** `townValue` for horde scaling = resources spent on standing buildings; stored food/scrap don't count, and the town factor is capped at 1.5x (`Content/hordes.json`).
**Why:** Hoarding shouldn't make hordes bigger, and the cap keeps growth from feeling punished. Offline rules got their own file (`Content/offline.json`) so time-factor tuning is in one place.

## D-010 — Core tests read the repo's Content/ folder (2026-10-31) [Accepted]
**Decision:** `ContentLoader.load(from:)` takes a folder URL; Core tests pass the repo's `Content/` (found from `#filePath`), and the App will pass its bundled copy.
**Why:** One copy of the JSON, no package-resource syncing, and tests always check the real files the owner edits.

## D-011 — 1A auto-staffs buildings, oldest first (2026-10-31) [Accepted]
**Decision:** Until job assignment arrives in 1C, survivors automatically fill worker slots of finished buildings in build order (`Systems/Economy/Staffing.swift`).
**Why:** Production depends on staffing (`productionPerMin × staffed / workers`), but manual jobs are 1C scope; a fixed order keeps it deterministic and easy to replace.

## D-012 — 1A construction has a build timer but no slots/builders (2026-10-31) [Accepted]
**Decision:** Placing pays the L1 cost and the building finishes after `buildSeconds`; construction slots, the queue, and borrowed builders (`buildings.json rules`) wait for 1C.
**Why:** 1C's plan owns "build queue limited by available builders"; a timer now means saves already hold build progress, so 1C adds limits without a save migration.

## D-013 — Frame-hitch cap in economy.json (2026-10-31) [Accepted]
**Decision:** `GameLoop.advance` simulates at most `economy.json maxFrameSeconds` (0.25 s) of real time per call; longer gaps are dropped.
**Why:** A hitch or a return from background must not jump the game ahead; real time away is handled on purpose by offline catch-up in 1D.


## D-014 — Xcode project created once by an agent, with XcodeGen (2026-10-31) [Accepted]
**Decision:** With the owner's one-time approval, an agent created `HighwayHoldout.xcodeproj` by running XcodeGen 2.46 from a spec kept outside the repo (not checked in). Settings: iOS app target `HighwayHoldout`, Swift 6, iOS/iPadOS 17.0, iPhone + iPad, landscape only, generated Info.plist, bundle id `com.highwayholdout.app`. `App/` is a synced (buildable) folder, the local package `Core` (`HoldoutCore`) is linked, and no app test target (Core tests cover the logic). The repo's `Content/` folder is added as a **folder reference** in Copy Bundle Resources, so the app has `HighwayHoldout.app/Content/` (with `maps/`), and `GameStore` passes `Bundle.main.url(forResource: "Content", withExtension: nil)` to `ContentLoader.load(from:)`.
**Why:** XcodeGen produces the same project Xcode would, with no clicking, and the spec isn't kept, so nobody regenerates or hand-edits the project later. A folder reference keeps `maps/` as a subfolder and picks up new JSON files with no project edit. From now on, agents never edit `project.pbxproj` (AGENTS.md).

## D-015 — Placeholder art is drawn at runtime (2026-10-31) [Accepted]
**Decision:** `ArtRegistry` draws a missing image into a texture once (category color + the art id written on it) and caches it. The same path serves SpriteKit sprites and SwiftUI icons. Sprite sizes always come from footprint × 32 pt, never from the image.
**Why:** Every placeholder, even each of the 1,200 ground tiles, is a labeled, cheap, batched sprite. Real art and placeholders can mix in any combination, and a PNG with the right name replaces its placeholder with no code change.

## D-016 — Two views (isometric + top-down), built in 1V before 1B (2026-10-31) [Accepted]
**Decision:** The normal view is isometric ("full Tropico style"); the game flips to top-down while placing/moving (and by a HUD button). Each view has its own art pack with the same filenames, set up in `Content/presentation.json`, with depth sorting, anchored tall sprites, and 3D placeholder blocks. The in-between 3/4 option was dropped by the owner. The pure projection math lives in Core (`Presentation/GridProjection.swift`, Foundation-only) so it can be unit-tested; Core's simulation never uses it.
**Why:** The owner wants a 3/4 "like Tropico" look and may change art style. 1B–1D add most of the drawing code (zombies, turrets, FX, bars), so doing this first avoids rewriting it. The simulation grid is unchanged. Plan: `docs/PHASE1-TASKS.md`.

## D-017 — Fresh Blender art study; abandon the pixel variant (2026-10-31) [Accepted]
**Decision:** At the owner's request, stop the 8-bit experiment and build a separate original 3D study in Blender, with reusable model collections, a diorama and ten transparent sprite samples. Keep the app's currently imported artwork in place while the new direction is evaluated.
**Why:** The owner rejected a pixelized version of the previous art and requested something completely different using the newly installed Blender. Retaining real 3D models allows later camera changes for D-016; the study does not choose the final projection or implement a gameplay milestone. The importer was run only in dry-run mode because its trim/refit behavior would change sprite pivots.

## D-018 — Art folders per view; unlabeled iso ground placeholders (2026-10-31) [Accepted]
**Decision:** Art lives in namespaced asset-catalog folders: `Art/TopDown/`, `Art/Iso/`, and `Art/UI/` (icons, shared by both views). `tools/import_art.py --view` picks the folder, and isometric art is never trimmed. Isometric ground-tile placeholders are plain colored diamonds without labels; every other placeholder still shows its id.
**Why:** Both views use the same filenames (`bld_farm`), so they need separate folders, and the game shows one view's art without mixing. Iso art depends on an exact ground point, so trimming would move it. 1,200 tile labels made the map unreadable, and tile colors already tell the ground types apart.

## D-019 — Isometric art rendered from the Blender study; UI kit adopted (2026-10-31) [Accepted]
**Decision:** The isometric view's art is rendered by `tools/blender/render_iso_sprites.py` from the Blender study's models, using the camera in `docs/graphics-spec-iso.md`. Buildings the study didn't have (scavenger, workshop, barracks, storage, scaffolds, rubble, ground tiles) got simple stand-in models in the study's style (`tools/blender/extra_models.py`). Menus use ChatGPT's `HighwayHoldout_UI_Kit` via `App/UI/KitStyle.swift`.
**Why:** The owner wanted real art in the 3D view, and no isometric sprites had been delivered. The study's hand-off said to re-render from its 3D source once the game picked a projection. Rendering from 3D gives exact 2:1 angles and anchors and makes facings easy. Any art-team PNG with the same name replaces a rendered one on the next import.

## D-020 — Repairing a damaged building is instant in 1B (2026-10-31) [Accepted]
**Decision:** Repairing a damaged building pays and restores full hp at once, and the building keeps working. Rubble still rebuilds on a construction timer.
**Why:** A repair timer marked the building unfinished, so a Storage under repair dropped the storage cap and the economy deleted stock above it. Timed repairs come back with 1C builders, using a separate repair state.

## D-021 — 1B rule interpretations (hordes and towers) (2026-10-31) [Accepted]
**Decision:** Horde budget = baseBudget + budgetPerDay × (day − 1) (per hordes.json notes). One zombie spawns per active edge every spawnIntervalSeconds. Edges are picked at the warning, and the mix at the start. Seeded picks use plain modulo. Repair cost rounds up, so small damage isn't free. Towers fire when (tick + buildingID) % max(1, round(tps / fireRate)) == 0, with no saved cooldown. Unknown `targeting` values act like `single_nearest`. Nearest-to-HQ uses the weight-1.0 flow field.
**Why:** These keep hordes and towers deterministic with no extra save fields, and match the content notes. Details: docs/features/hordes.md and combat.md.

## D-022 — Isometric placement becomes the normal build experience (2026-10-31) [Accepted; implemented 2026-10-31]
**Decision:** The owner approved improving placement in isometric with a ground grid, clear footprint/validity feedback, drag preview + Confirm, and temporary fading of obstructing buildings. Once verified on iPhone, disable automatic top-down switching. Keep the existing top-down mode manually available during testing; do not remove it yet.
**Why:** A continuous isometric view avoids the visual/style jump and reduces the need to maintain two polished art sets. Top-down remains a fallback until touch placement is proven.
**Scope/status:** Docs-only coordination in this pass; app behavior is unchanged. Supersedes D-016's automatic placement-switch requirement, not its view-independent projection architecture. Build order and acceptance checks: `PHASE1-TASKS.md` → Approved update — isometric placement first.

## D-023 — Starting walls fully enclose the HQ (2026-10-31) [Accepted]
**Decision:** A new game starts with a closed ring of 28 wood walls (x 20–28, y 16–22) around the HQ and watchtower, instead of two 6-wall rows. `buildings.json startingLayout` wall count 12 → 28 (under the HQ-1 cap of 40).
**Why:** The owner wants walls to matter from the first horde. With gaps, zombies walked around the walls. Now day 1 has to break through a wall to reach the HQ. Existing saves keep their own walls; only new games change.

## D-024 — Walls are drawn as lines and built all at once (2026-10-31) [Accepted]
**Decision:** Walls use a wall tool instead of the single-building ghost. You drag a line (straight or one-corner L), the bar shows the count and total cost, and Build places the whole line in one command (`Command.placeLine`). Blocked tiles, tiles past the limit, and existing walls are skipped and not charged. If you can't afford the whole line, nothing is built. Two-finger pan always moves the map, because one finger draws.
**Why:** The owner found wall building awkward and wanted to plan a wall and see its cost before committing. Building all-or-nothing avoids half-built lines when resources run out partway.

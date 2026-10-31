# STATUS — where we left off

_Update at the end of every work session. Keep it short; history belongs in feature-note change logs._

**Last updated:** 2026-10-31 (1B done; isometric placement done; next 1C)

## Current phase / milestone
- **Phase 1** — one base at a highway exit. Plan: `docs/PHASE1-PLAN.md`.
- **Milestone 1A — Foundation** — DONE (2026-10-31).
- **Milestone 1V — Two views** — DONE (2026-10-31).
- **Milestone 1B — Defense** — DONE (2026-10-31).
- **Isometric-first placement (D-022)** — DONE (2026-10-31). Next: **1C Depth**.
- Milestones: 1A Foundation → **1V Two views (owner: isometric + top-down for placing)** → 1B Defense → 1C Depth → 1D Time & alerts → 1E Art swap & playtest. Task breakdown: `docs/PHASE1-TASKS.md`.
  Don't start the next one until the current one's exit check passes.

## Last thing done
- **Zombies shamble instead of floating:** each step hops and leans left/right around the feet, faster for runners, stopped while bashing a wall (`ZombieNodeFactory.swift`). Built OK; not yet eyeballed in the simulator.
- **Wall tool:** walls are now drawn, not placed one by one. Drag a straight or L-shaped line, see how many walls and the total cost (skipped tiles shown red / "already built"), tap Build to place it all at once (nothing if you can't afford it all). Two fingers move the map. Core `planLine`/`placeLine` with 6 tests (119 pass). Checked in the simulator.
- Starting walls now fully enclose the HQ (D-023): 28-wall ring in `Content/maps/phase1_exit.json`. Headless run: day 1 breaks one wall then is held. New games only.
- **Isometric placement (D-022) done.** Placing/moving now stays in isometric: tile grid around the ghost (unbuildable tiles red), green/red footprint + reason, ghost held above the finger while dragging, buildings/trees in front of the ghost fade and restore. Checked on iPhone 18 Pro simulator: 1×1 (repeated walls at the map edge), 2×2 (shelter inside the walls, scavenger post behind the HQ), 3×3 (move HQ + Cancel = no change), invalid spots blocked with reasons, no view flip on Confirm/Cancel. Auto top-down turned off (`presentation.json`), old saved setting ignored (verified by forcing it on); manual top-down button kept. Also: 1×1 builds show a faded picture instead of the oversized 2×2 scaffold; selection bar fits on iPhone (no wrapped HP/Demolish). 113 tests pass.
- **1B Defense DONE (2026-10-31).** On-screen exit check passed in the simulator: zombies walked to a weakened wall in a walled town, broke through (rubble), poured in, the tower held ("Held!"); N–S walls draw mirrored correctly; repeated wall placement stays in placing mode; range ring shows as an ellipse; a day-40 horde (35 zombies, mostly brutes) ran at 60 fps / 1,416 nodes (simulator; 150 zombies isn't reachable with current content). Fixed the two review findings (4-facing wrap near east, test-first, via Core/Presentation/Facing.swift; metal-wall menu art). DEBUG builds now show FPS + node count. 113 tests pass. MAP reconciled with the 1B merge. Committed Codex's pending work and removed the merged agent worktrees.
- Zombie art detail pass: refined walker, runner and brute Blender models with distinct costumes, facial sculpt and surface detail; imported nine isometric sprites. Before/after: `HighwayHoldout_Iso_Art/zombie-review/comparison.png`. Sprite validation passed; review moving hordes at gameplay zoom next.
- Documentation coordination (2026-10-31): owner designated **Craft → Highway Holdout** as shared documentation for Claude/Codex in every project chat. Persisted the read/update workflow and known Craft project-page ID in `AGENTS.md` (also read by `CLAUDE.md`). Connector currently exposes the project page but no matching folder; use that page for the handoff until the folder is visible. Documentation-only change; no app tests needed.
- Owner approved isometric-first placement (D-022). Codex updated build/input/rendering docs before implementation: grid, footprint feedback, drag preview and occluder fading first; disable auto-top-down only after iPhone validation; retain manual top-down for testing. **Docs only; app behavior unchanged.**
- Art/repo review: verified GitHub main at 860232a; independently passed 110 Core tests and simulator build. Packaged 89-asset UI kit with source files and four previews. See `docs/reviews/2026-10-31-art-and-build-review.md` for facing-wrap and metal-wall thumbnail findings and next work.
- 1B Defense built (parallel agents, merged on main): pathing/flow field, zombie movement + wall bashing + traps, horde clock/composer/spawning/resolution/HQ fall, repair (+ cost preview), towers, App zombies/defenses/FX/horde HUD/banners/debug menu, iso art for 1B. 110 Core tests pass; app builds. Simulator: day-1 horde started, came down the north road, watchtower shot them, "Held!" (screenshots in shared notes app-1b-screenshots/). Headless probe: walled town → zombies from both edges target the weakened wall, breach it, tower holds.
- Isometric view now shows **real art**: rendered from the Blender study's 3D models with `tools/blender/render_iso_sprites.py` (HQ, shelter, farm, walls, watchtower + gunner, car wreck, tree, rubble, units with facings), plus Claude stand-in models in the same style for scavenger, workshop, barracks, storage, scaffolding, rubble and the 5 ground tiles (D-019). Menus use ChatGPT's **UI kit** (`HighwayHoldout_UI_Kit/`): dark resource chips, kit build cards with 3/4 pictures, kit buttons/panels/glyphs. Checked in the simulator (screenshots in the shared notes folder, app-iso-art-screenshots/). 52 Core tests pass.
- 1V Two views: the game opens in **isometric** (Tropico style, labeled 3D placeholder blocks until iso art exists) and flips to **top-down** (real art) while placing/moving, then back. HUD button (top right) flips by hand; long-press it to turn the auto-flip off. New `Content/presentation.json`; projection math in Core with 6 new tests (52 pass); depth sorting, roof taps, per-view camera bounds; `tools/import_art.py --view topdown|iso` (art now in `Art/TopDown`, `Art/Iso`, `Art/UI`); isometric art guide `docs/graphics-spec-iso.md` + diamond templates in `docs/art-templates/`.
- 1V exit check (iPhone 18 Pro): opened in iso on the 1A save, Build → flipped to top-down with the ghost, Confirm → flipped back with the new farm, roof tap selected the HQ, manual toggle both ways, Move → top-down, Cancel → back, zoomed out to the whole diamond.
- Art study: owner abandoned the 8-bit experiment. Built `HighwayHoldout_Blender_Study/` from fresh 3D geometry: editable Blender diorama, ten model collections, ten transparent PNG samples and Claude handoff. All 40 PNG checks passed; no app artwork or gameplay was changed. See D-017 and `renders/01_roadside_diorama.png` in the study folder.
- 1A App half: `HighwayHoldout.xcodeproj` (created once by an agent, D-014), SpriteKit map in SwiftUI, ArtRegistry with labeled placeholders (D-015), camera pan/zoom/bounds, ghost placement (snap, red when invalid, confirm), select/move/demolish, HUD resource bar, build menu, save on background + every 30 s, load on launch.
- Imported all 57 ChatGPT PNGs with `tools/import_art.py` (all of them are finished now).
- Exit check (iPhone 18 Pro simulator): placed a farm and a scavenger post, moved the farm, watched them build and food/scrap tick, then went home, force-quit, and relaunched. The town and its resources were back and still ticking. Also checked the red ghost, demolish with refund, and the HQ refusal.
- Build: `xcodebuild … build` succeeds with no code warnings; `cd Core && swift test` passes all 46 tests.
- Earlier: 1A Core half (`Core/` package; see `docs/features/core-api.md`), docs scaffolding, tuning pass.

## Next step
- Claude: read **Approved update — isometric placement first** at the top of `PHASE1-TASKS.md` before touching placement/view switching. Implement its staged checklist; preserve the pending 1B exit checks. No matching top-down art refresh is needed for this direction.
- **1C Depth** per `docs/PHASE1-TASKS.md` (upgrades, build queue + builders, jobs, defenders, scavenging runs, speed controls, research). Plan: Core contract first, then parallel agents like 1B.
- Art: isometric renders and the UI kit are integrated. Remaining menu thumbnails and real inventory/pause screens are recommended next; see the review and UI handoff.

## Decided
- The 8-bit art experiment is abandoned at the owner's request. The app uses the original pack for top-down, Blender-derived isometric sprites, and the new UI kit.
- Xcode project exists (D-014); `App/` is a synced folder; agents never edit `.pbxproj`.
- How to run: open `HighwayHoldout.xcodeproj`, pick an iPhone simulator, press Run (or the `xcodebuild` command in AGENTS.md).
- Toolchain: Xcode 27, Swift 6, minimum iOS/iPadOS 17.0 (see `docs/research/tech-findings.md`).
- Landscape only for Phase 1.
- Core tests read the repo's `Content/` folder; the App passes its bundled copy (D-010).

## Open questions (owner decides)
- **ZWALK-1** zombie limb animation: spec + paste-ready prompt in `docs/features/zombie-walk-animation.md` (Blender walk frames, ~36 sprites). Build when credits allow?
- View direction is decided in D-022 (implementation pending). Iso facings remain 4 for units/zombies and 8 for turrets; changing those is a separate choice.
- Final game name (Highway Holdout is a working title).
- Balance: should survivors eat food (upkeep), so food stays useful after ~60 min? (`resources.json foodUpkeepPerSurvivorPerMin`, currently 0; Core rejects non-zero until upkeep is built)
- Balance: should defenders/survivors ever die permanently? (currently knocked out for 2 min, `units.json`)
- Balance: Horde Alert ON by default? (`offline.json hordeAlert.defaultEnabled`, currently true; Time factor stays OFF)
- Art: `--view topdown` still trims and refits sprites (and caps a tile at 96 px @3x); `--view iso` doesn't trim. Should top-down stop trimming too before 1B's units/turrets? (Owner/1E call.)
- Art: `tools/import_art.py` also writes `App/AppIconLayers/*.png`, which end up as loose files in the app bundle. They're harmless and small; move them out of `App/` if that matters.


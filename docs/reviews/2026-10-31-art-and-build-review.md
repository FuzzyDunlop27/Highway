# Art and build review — 2026-10-31

## Baseline verified
Repository: https://github.com/FuzzyDunlop27/Highway, branch main. Local HEAD, origin/main and GitHub commit matched `860232ab3f3c217df60a73f10afcecd9619e4b4f` at review time. No push or app-code change was made by this review. Independently ran 110 Core tests (all passed) and a generic iOS Simulator xcodebuild (BUILD SUCCEEDED). No GitHub combined commit statuses were reported; there is no local .github workflow directory.

Claude has integrated the new UI kit, re-rendered the Blender study for the proper isometric camera, added stand-in models for missing structures, implemented two views and merged substantial 1B defense work. This is adaptation and integration of the earlier art, not a wholesale discard.

## Concrete findings
1. **P2 — four-direction facing wraps incorrectly near east.** `App/Rendering/DirectionalSprite.swift:25–29` reduces the rounded index modulo eight before calculating the angular difference. At -5° / 355°, that becomes index zero and a positive difference, selecting NE instead of the nearest SE diagonal. A standalone compiled probe reproduced NE for -20°, -5°, 340° and 355°. Add boundary tests before fixing the circular distance calculation. Core tests do not cover this App helper.
2. **P2 — metal-wall menu art shows wood.** `App/Rendering/ArtRegistry.swift:100–102` tries ui_build_wall for wall_metal before its correct isometric sprite. Only the wooden ui_build_wall thumbnail exists. Use exact-id variants or restrict the generic wood fallback to wall_wood.

## What to build next, in order
1. Finish 1B's existing visual exit checklist: wall breach on screen, north/south wall mirroring, repeated 1×1 defense placement, range rings and approximately 150 zombies at acceptable frame rate. These remain unverified by this review; tests/builds do not replace them.
2. Build the actual storage/resource inventory page using the delivered artwork: current quantities/caps, production explanation, selected-item details and empty/locked states. Start with existing resources; additional illustrated props do not authorize new gameplay resources.
3. In 1C, implement pause/1×/2× controls and the planned progression (upgrades, queues, jobs/training/garrison/scavenging/research). Use the pause mockup as a composition reference. Settings/notifications and offline work belong to 1D.
4. Finish visual coverage: exact menu thumbnails for remaining buildings/defenses, clear pressed/selected feedback, and small-screen/accessibility checks. Validate top-down padding/anchors before changing the importer; its trim-and-fit behavior differs from isometric imports. Assess tall-building occlusion while fighting behind HQ.
5. Add automated Core tests on pull requests and a macOS app build check. Complete 1E playtesting and art polish after milestone gates pass.

## Documentation drift
STATUS still described starting 1B and the Blender art as only proposed despite its own completion notes. Its current next-step summary is corrected in this pass. MAP still has unfinished combat/pathing entries requiring reconciliation with Claude's integration report. HUD notes said repair prices were unavailable although the app now displays a preview; renderer notes also contain older provisional-art statements. Treat actual code and latest milestone evidence as authoritative until these are reconciled.

## UI delivery
`HighwayHoldout_UI_Kit/` contains 89 PNGs, editable Blender/SVG sources, four previews, manifest, tokens and Claude handoff. `HighwayHoldout_UI_Kit.zip` is the portable handoff. Inventory and pause previews are designs, not claims that these screens run in the app.

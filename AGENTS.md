# AGENTS.md — rules for every AI agent working in this repo

**Highway Holdout:** an offline iPhone/iPad zombie town-builder + tower defense (no ads, no IAP).
Built by AI agents for a non-engineer owner, so keep changes small, explained, and easy to find.

## Look here first
Before the local docs below, check **Craft → Highway Holdout** for shared project documentation and the latest Claude/Codex handoff in every project chat. Read the relevant status, decisions, and task notes; at the end of each work session, record what changed, verification, blockers, and the next step there so both agents can track progress. Keep repo docs consistent with those updates. If Craft is unavailable or its folder cannot be found, say so explicitly; use the existing project page if accessible, and never claim a sync succeeded without checking it.

Known Craft project page: **Highway Holdout — Zombie TD Game**, root block ID `c6f9fd54-e7d4-463b-4d01-f2e85218f679`. Resolve the current folder through Craft rather than creating duplicate project pages or folders.

1. `docs/STATUS.md` — where we left off and the current milestone.
2. `docs/MAP.md` — what every folder/file is for, and "to change X, look in Y".
3. The one feature note for your task in `docs/features/` (if it exists).
4. Building a new milestone? Read only that milestone's section of `docs/PHASE1-PLAN.md`.
Do NOT scan the whole codebase. If MAP + the feature note aren't enough, MAP is wrong — fix it.

## Build chunks (so the owner can start fresh chats)
The owner avoids long-running chats. Work is split into **build chunks** tracked in `docs/BUILD-QUEUE.md`.
- **Labels show dependencies.** Number = wave, letter = track (e.g. 1A, 2A, 1B, 2B, 3B). Any chunk in wave 1 can be done at any time; a wave-2 chunk needs **all** wave-1 chunks done; wave 3 needs all of waves 1–2. If a different dependency is truly needed, write it in the chunk's "Needs" line. (Older "Milestone 1A–1E" names in `PHASE1-PLAN.md` are a separate, earlier scheme; say "chunk" vs "milestone" to avoid mixing them up.)
- **After finishing any chunk, always write up the next big chunk:** add or update its entry in `BUILD-QUEUE.md` with label, goal, needs, scope, what NOT to build, exit check, and a short start prompt the owner can paste, like "Implement chunk 2A" in a new chat.
- **When the owner asks "what's left?"** (any time), read `BUILD-QUEUE.md` and answer: done / ready now / blocked (and by which chunks).
- **Record status in Craft** (Highway Holdout page, see "Look here first") whenever a chunk is started, finished, or blocked, and keep `BUILD-QUEUE.md` the same. Verify the Craft write; never claim it synced unchecked.

## Architecture rules (never break these)
- `Core/` (Swift package `HoldoutCore`) is the game simulation. It imports only Foundation.
  Never import SpriteKit, SwiftUI, UIKit, or Observation in Core.
- Core is deterministic: fixed-timestep ticks (10/sec, from `Content/economy.json`), seeded random numbers only, no wall-clock reads
  inside systems. Time comes in from the App as input.
- `App/` (target `HighwayHoldout`) draws the game and handles touches. It never changes game
  state directly; it sends a `Command` to Core (e.g. place building, start horde).
- All tuning numbers (costs, speeds, health, ranges, timers, caps) live in `Content/*.json`.
  Never hardcode a tuning number in Swift. If a new number is needed, add a JSON field.
- Art is looked up by id through `App/Rendering/ArtRegistry.swift`. A missing image must draw
  a labeled colored placeholder, never crash.
- Saves are versioned JSON (`Core/Sources/HoldoutCore/Save/`). If you change saved data, add a migration.

## File rules
- One responsibility per file. Keep files under ~250 lines; split before you pass it.
- First line of every Swift file is a purpose comment pointing to its feature note:
  `// Purpose: Picks which zombie each tower shoots. Notes: docs/features/combat.md`
- Name files after what they do (`TargetingSystem.swift`, not `Helpers.swift`).

## How to work (every task)
1. Read STATUS → MAP → the one feature note.
2. Make the smallest change that does the job.
3. Update that feature note: files involved, rules, and a one-line change-log entry.
4. If you added, moved, renamed, or deleted a file, update `docs/MAP.md`.
5. If you made a non-obvious choice (a trade-off, a workaround), add an entry to `docs/DECISIONS.md`.
6. Update `docs/STATUS.md` (last thing done, next step) at the end of a work session.
7. In your summary to the owner, say what changed in plain English and how to check it.

## Testing
- Any change to Core logic needs a Swift Testing test (`import Testing`, `@Test`) in
  `Core/Tests/HoldoutCoreTests/`, in the folder that mirrors the source folder.
- Bug fix = first write a test that fails because of the bug, then fix it.
- A `ContentFilesTests` test must decode every `Content/*.json` file; keep it passing.
- App/UI changes: build the app and describe what to look at in the simulator.

## Build and test commands
<!-- TODO: fill in exact scheme/simulator names once the Xcode project exists. -->
```sh
# Core tests: fast, no Xcode needed (works on Mac or Linux, e.g. Codex cloud)
cd Core && swift test

# Full app build + tests: macOS with Xcode only
xcodebuild -scheme HighwayHoldout -destination 'platform=iOS Simulator,name=<iPhone model>' build
xcodebuild -scheme HighwayHoldout -destination 'platform=iOS Simulator,name=<iPhone model>' test
```
If you cannot run a command (e.g. no Xcode in your sandbox), say so; never claim it passed.

## Xcode project file
- The project uses Xcode buildable (synced) folders: adding or removing a file needs no project-file edit.
- Never edit `*.xcodeproj/project.pbxproj` unless the owner explicitly asks.
- Toolchain: Xcode 27, Swift 6, minimum iOS/iPadOS 18.0 (raised from 17 for RealityKit 3D, D-028).

## Phase discipline
- Build only the current milestone (`docs/STATUS.md` → milestone; scope in `docs/PHASE1-PLAN.md`,
  including "What NOT to build"). Future phases are "design for, don't build."
- Don't add features, libraries, or refactors nobody asked for. Suggest them in STATUS → Open questions.
- No third-party dependencies without a DECISIONS entry approved by the owner.

## Art
- New PNGs from ChatGPT: put them in a folder and run `python3 tools/import_art.py <folder>`.
  It resizes them into `App/Assets.xcassets/Art/`. Filenames must match `docs/graphics-spec-phase1.md`.

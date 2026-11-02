# Feature: Save / load

## Purpose
The whole game is saved as one versioned JSON blob so the town is still there after a force-quit.

## Files involved
- `Core/Sources/HoldoutCore/Save/SaveCodec.swift` — `encode(GameState) -> Data`, `decode(Data) -> GameState`, `SaveError`.
- `Core/Sources/HoldoutCore/Save/SaveMigrations.swift` — the migration hook (one step per old version).
- `Core/Sources/HoldoutCore/Model/*.swift` — everything saved is `Codable`.
- `App/Platform/SaveFileStore.swift` — reads/writes `Application Support/HighwayHoldout/save.json` (atomic write); renames an unreadable save to `save.broken-<time>.json`; DEBUG Start new town renames the current one to `save.old-<time>.json` (`setAside(as:)`).
- `App/Platform/AppLifecycle.swift` — saves when the app leaves the foreground and every `autosaveSeconds` of real frame time.
- `App/GameStore.swift` — on launch: load the save, or start a new game if there is none (or it can't be read; the player sees a notice).
- Tests: `Core/Tests/HoldoutCoreTests/Save/SaveCodecTests.swift`

## Data files
- `Content/economy.json` → `autosaveSeconds` (the App's autosave timer).

## Key rules
- Format: `{ "version": 6, "state": { ... } }`, sorted keys. Core never touches the disk.
- Content (costs, map tiles) is NOT saved; only ids. Changing a JSON number changes old saves' future behavior, not their past.
- Random state is saved as a string (a UInt64 doesn't fit a JSON number exactly).
- Loading a newer version throws `newerVersion`; an older one runs `SaveMigrations.steps` from its version up, then decodes.
- **When you change saved data:** bump `SaveCodec.currentVersion`, add a step `oldVersion: { json in ... }` to `SaveMigrations.steps`, and add a test that decodes an old-version sample.
- The fractional tick time inside `GameLoop` isn't saved (always under one tick).
- App saves when the scene phase leaves `.active` (home, app switcher, lock) and every 30 s; a force-quit loses at most ~30 s.

## Known issues
- (none yet)

## Change log
- 2026-10-31 — Version 1 save codec + migration hook (1A).
- 2026-10-31 — App side: save file store, save on background + autosave, load on launch (1A App half).
- 2026-11-01 — v3 (chunk CORE-001): `Base.jobs` (build queue); a v2 half-built building becomes a running, already-paid job.
- 2026-11-02 — v6 (ticket CORE-010): `Building.facing` (old buildings get "south" and keep their origin; the five that are now 2×1 just cover the top row of their old 2×2 spot). Test decodes a v5 sample.
- 2026-11-01 — v4 (chunk CORE-002): `Base.defenders`, `nextDefenderID`, `training`; `Building.assignedWorkers` (absent = full staffing). v5 (chunk CORE-003): `Base.runs`, `Base.research`, `Building.heldReward` (absent = none); `Group.knowledge` was already saved. Tests decode a v3 and a v4 sample.

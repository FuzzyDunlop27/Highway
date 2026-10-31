# Phase 1 Build Plan — Highway Holdout

**Phase 1 goal:** prove the core loop on one map. Growing the town is fun, and watching it hold off a horde is thrilling.
**Phase 1 is done when:** a 30-minute playtest leaves you wanting to keep going, and closing the app for 4 hours (time factor on) then coming back feels rewarding.

Read with: `docs/GAME-DESIGN.md` (what), `AGENTS.md` (how to work), `Content/*.json` (numbers), `docs/STATUS.md` (where we are).

---

## Stack (and why)
| Layer | Choice | Why |
|---|---|---|
| Language | Swift 6 | Apple's current language; strict concurrency catches threading bugs early. |
| Game world | SpriteKit inside SwiftUI (`SpriteView`) | Native 2D engine, free, fully offline, smooth on iPhone 15+. Agents write it well. |
| UI / HUD / menus | SwiftUI + `@Observable` | Modern Apple UI. Menus and HUD stay out of the game scene. |
| Simulation | Local Swift Package `HoldoutCore` | Pure Swift, no graphics. Testable. Reused for offline catch-up. Bugs split cleanly into "logic" vs "drawing". |
| Content / tuning | JSON files in `Content/` | Change numbers without touching code or burning tokens. |
| Saves | Codable JSON file, versioned | Simple, inspectable, easy to migrate. SwiftData is overkill for one game-state snapshot. |
| Notifications | UserNotifications (local only) | Horde Alerts work offline; no server. |
| Tests | Swift Testing | Locks down economy, catch-up, and pathing rules. |
| Project file | Create once in Xcode 27 with buildable folders (the default since Xcode 16); agents never edit `.pbxproj` | Agents can add/remove Swift files without touching the fragile project file. XcodeGen is a fallback only. |
| Toolchain | Xcode 27, Swift 6.4, minimum iOS/iPadOS 17.0 | iOS 17 is iPhone 15's launch OS and the floor for `@Observable`. App Store uploads need the iOS 27 SDK from April 2027. Sources: docs/research/tech-findings.md |
| Agent ↔ Xcode | `xcodebuild` from the terminal; optionally Xcode's MCP bridge (`xcrun mcpbridge`) | Lets Codex/Claude Code build and run tests themselves. Needs a Mac with Xcode open. |

**Mac reality check:** the iOS app only builds on a Mac. Cloud/Linux agents can still run `swift test` on `HoldoutCore`, which is why the simulation lives there.

**Orientation:** landscape only for Phase 1 (simplest HUD layout, best map view). Portrait is a later decision.
**Devices:** iPhone 15 and newer, iPad. The camera and HUD scale to screen size; no iPad-specific layout in Phase 1.

## Architecture in one picture
```
HighwayHoldout (app)                 HoldoutCore (Swift package, no graphics)
├─ UI/        SwiftUI HUD, menus     ├─ Model/      GameState, Base, Group, entities
├─ Rendering/ SpriteKit scene,       ├─ Systems/    Economy, Construction, Jobs,
│             node factories,        │              Pathing, Combat, Hordes,
│             ArtRegistry            │              Research, OfflineCatchUp
├─ Input/     camera, placement      ├─ Content/    JSON loaders + typed defs
└─ Platform/  save IO, notifications,└─ Save/       Codable snapshot + migrations
              app lifecycle
Content/*.json  (tuning)   Assets.xcassets  (art, swapped in from ChatGPT)
```
- The app reads `GameState` and draws it. The app sends commands (`placeBuilding`, `upgrade`, `engageHorde`) to Core. Core never imports SpriteKit or UIKit.
- **Fixed tick:** Core advances in fixed steps (10 per second). Speed 2x = two steps per frame window. Pause = no steps.
- **Group vs Base:** `Group` owns Knowledge (research), survivors' skills, and later the travel inventory. `Base` owns the map, buildings, and stored resources. Phase 1 has one Base, but the model supports many, so the travel phases don't need a rewrite.

## Milestones
Each milestone ends with something playable. Don't start the next one until the exit check passes. Each has a kickoff prompt for Codex / Claude Code at the end of this file.

### 1A — Foundation: "a town that persists"
- Xcode project, `HoldoutCore` package, folder layout per `docs/MAP.md`.
- Content loader (reads all `Content/*.json`, fails loudly on bad data).
- Grid map (about 40×30 tiles) with a highway along one edge, ramps, and a couple of side roads. Map defined in a JSON file.
- Camera: pan, pinch zoom, bounds.
- ArtRegistry + placeholder renderer (colored shapes with labels; real PNG used if present).
- Place, move, and demolish buildings with valid/invalid footprint preview.
- Economy tick: Farm makes food, Scavenger Post makes scrap, Shelters raise survivor cap, storage caps.
- HUD: resource bar, build menu.
- Save on background and every 30 seconds; load on launch.
- **Exit check:** build a small town, force-quit, relaunch, and it's all there with resources still ticking.

### 1V — Two views: "Tropico to look at, top-down to build" (added 2026-10-31)
- Owner decision: the normal view is full isometric (Tropico style), and it flips to top-down while placing/moving for easy placement. Done before 1B so zombies/turrets/FX are drawn view-independently.
- Projections + per-view art packs in `Content/presentation.json`; depth sorting; anchored tall sprites; 3D placeholder blocks; tap picking; auto-flip + HUD toggle; art import per view; isometric art spec.
- **Exit check:** opens in iso; Build flips to top-down; Confirm flips back; draw order, roof taps, and camera bounds are right in both.
- Tasks: `docs/PHASE1-TASKS.md`.

### 1B — Defense: "watch it hold"
- Zombies: walker, runner, brute from `Content/zombies.json`.
- Flow-field pathing toward the HQ; walls passable at high cost, so zombies bash through weak points. Field rebuilds when walls change.
- Defenses: walls, watchtower, MG nest, spikes, barbed wire. Tower targeting (nearest-to-HQ first).
- Combat: projectiles/tracers, hit flashes, goo splats, health bars.
- Horde clock (in-game, app-open only) with a visible countdown and spawn-edge warning arrows.
- HQ fall = setback: horde ends, lose a share of stored resources, destroyed buildings become rubble with a repair cost.
- **Exit check:** a horde arrives, piles up at the weakest wall, breaks through or doesn't, and it's fun to watch.

### 1C — Depth: "a 30-minute session feels like progress"
- Upgrades (levels 1–3) shown by badge + tint.
- Survivors as workers: build queue limited by available builders; job assignment (farm, scavenge, build).
- Barracks trains defenders; defenders garrison towers (boost) or hold a spot.
- Scavenging runs: send survivors out on a timer for scrap/food; risk of losses later (not Phase 1).
- Live building during hordes (already allowed; make sure UI works mid-fight).
- Speed controls: pause, 1x, 2x.
- Research stub at Workshop (3 items), stored on `Group`.
- **Exit check:** a 30-minute session from a fresh start hits HQ level 2–3 and faces brutes.

### 1D — Time & alerts: "come back to something"
- Settings screen: Time Factor toggle (default off), Horde Alerts toggle.
- Offline catch-up: on launch, compute elapsed real time, cap it, run the economy/construction/training/research math with no combat. Same Core systems, run in bulk.
- Welcome-back summary sheet ("While you were away: +340 food, Shelter finished...").
- Horde Alert: on backgrounding, schedule one local notification in a random window. On next launch, a bonus horde waits at a map edge, frozen. The player taps Engage when ready. It never expires and never attacks on its own.
- Clock tamper guard: if the device clock went backwards, grant nothing; cap forward jumps.
- **Exit check:** queue work, close the app for 4 hours, reopen, and the summary feels good; ignoring an alert costs nothing.

### 1E — Art swap & playtest
- Run `tools/import_art.py` on ChatGPT's PNGs; fix any that look off.
- Balance pass using `docs/features/balance.md` knobs.
- Simple sound hooks (optional placeholders).
- TestFlight build for yourself.
- **Exit check:** the Phase 1 "done when" line at the top.

## Rules that keep fixes cheap (breadcrumbs)
- Start every agent session with: "Read AGENTS.md, docs/STATUS.md, then only the feature note for this task."
- One feature note per system in `docs/features/`. Agents update it when they change that system.
- `docs/MAP.md` is the file map plus a "change X → look in Y" table.
- `docs/STATUS.md` is updated at the end of every session: last done, next step, open issues. This is your token-outage insurance.
- All numbers live in `Content/*.json`. "Make zombies slower" is a one-line JSON edit, not a code task.
- Commit after every working step with a clear message. Use GitHub once the repo exists, so you can always roll back.

## What NOT to build in Phase 1
- Travel, multiple maps, convoys, base takeovers, attack mode.
- Animated sprite sheets, music, iCloud sync, Game Center.
- Portrait mode, iPad-specific layout.
- A full research tree (3 stub items only).

## Phase roadmap after this
- **Phase 2:** second map + the highway map between bases; choose when to leave; Knowledge carries over.
- **Phase 3:** travel — pack the convoy (fuel, food, ammo, people), defend en route, arrive and build.
- **Phase 4:** take over occupied bases (outcome depends on supplies brought), attack mode.
- **Open design question for Phase 2:** how much of the old base's value comes with you, so leaving never feels like starting over.

---

## Kickoff prompts (paste one per session)

**1A**
> Read AGENTS.md, docs/STATUS.md, docs/PHASE1-PLAN.md (milestone 1A only), docs/MAP.md, and Content/. Build milestone 1A exactly as listed, using placeholder shapes for all art. Don't build anything from later milestones. Add Swift Testing tests for the economy tick and save/load. When done, update docs/STATUS.md, docs/MAP.md, and create docs/features/ notes for each system you built. Tell me how to run it in the simulator.

**1B**
> Read AGENTS.md, docs/STATUS.md, docs/PHASE1-PLAN.md (milestone 1B only), docs/MAP.md, and the feature notes for anything you'll touch. Build milestone 1B. All stats come from Content/zombies.json, buildings.json, and hordes.json. Add tests for flow-field pathing (zombies choose the weakest wall) and the HQ-fall setback. Update STATUS, MAP, and feature notes when done.

**1C / 1D / 1E**
> Same pattern: read AGENTS.md, STATUS, the milestone section, MAP, relevant feature notes → build only that milestone → tests for Core logic → update STATUS, MAP, feature notes.

**Small fix template**
> Read AGENTS.md and docs/STATUS.md. Bug: [what happens, what should happen]. Check docs/MAP.md to find the right files and read only those plus their feature note. Fix it, add a test if it's Core logic, and add one line to the feature note's change log.

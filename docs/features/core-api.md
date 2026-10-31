# Feature: Core API (what the App calls)

_The App-facing surface of the `HoldoutCore` package. Keep this in sync when public API changes._

## Purpose
One small, documented entry point so the SpriteKit/SwiftUI App can load content, run the simulation, send player actions, and read what to draw — without touching game rules.

## App-facing API
```swift
import HoldoutCore

// 1. Load content (fails loudly: throws ContentError naming the file + problem)
let content = try ContentLoader.load(from: bundledContentFolderURL)   // folder with *.json and maps/

// 2. Create or load a game
var state = try GameState.newGame(content: content, mapId: "phase1_exit", seed: someUInt64)
// or: state = try SaveCodec.decode(dataReadFromDisk)                  // throws SaveError
let loop = try GameLoop(content: content, state: state)              // use on the main actor only

// 3. Every frame
loop.advance(realSeconds: frameDelta)   // applies speed, caps hitches (economy.json maxFrameSeconds)

// 4. Player actions (nothing changes on failure)
loop.send(.placeBuilding(defId: "farm", at: GridPoint(x: 8, y: 20)))  // -> .success(.placed(id))
loop.send(.moveBuilding(id: id, to: p)) ; loop.send(.demolish(id: id)) ; loop.send(.setSpeed(0 / 1 / 2))

// 5. Ghost preview: "is this spot valid?"
let check = loop.checkPlacement(defId: "farm", at: tile)  // .isValid, .problem, .badTiles (draw red)
let moveCheck = loop.checkMove(id: id, to: tile)          // ground only; nil if id unknown

// 6. Read state to draw / show in the HUD
loop.resources            // ResourceSnapshot: food/foodCap, scrap/scrapCap, survivors/housing, idle, per-min rates
loop.state.base.buildings // [Building]: defId, level, origin (top-left), isComplete, constructionProgress, staffed
loop.map                  // MapDef: width, height, tile(at:) -> TileDef(tile art id, buildable), decorations
loop.building(at: tile)   // tap-to-select
content.allBuildingDefs   // build menu: displayName, sprite, footprint, levels[0].cost
content.presentation      // presentation.json: views, tile sizes, art folders (App only)
GridProjection(kind:tileWidth:tileHeight:mapWidth:mapHeight:)  // tile <-> screen math for both views

// 7. Save (App writes the Data to disk; autosave every economy.json autosaveSeconds + on background)
let data = try SaveCodec.encode(loop.state)
```
- Grid: `x` right, `y` **down**, (0,0) = top-left tile. SpriteKit's y is up, so the App flips it.
- A building's `origin` is its top-left tile; its size is `content.buildingDef(defId)!.footprint`.
- `PlacementProblem` cases map to messages: `offMap`, `blockedTerrain`, `occupied`, `limitReached(max:)`, `needsHqLevel`, `needsBuilding`, `needsResearch`, `notEnoughResources(needed:)`, `unknownBuilding`.

## Files involved
- `Core/Package.swift` — package definition (iOS 17 / macOS 14, Swift 6).
- `Core/Sources/HoldoutCore/Simulation/GameLoop.swift` — the entry point above.
- `Core/Sources/HoldoutCore/Simulation/Command.swift` — `Command`, `CommandOutcome`, `CommandError`.
- `Core/Sources/HoldoutCore/Simulation/SeededRandom.swift` — the only randomness (saved in state).
- `Core/Sources/HoldoutCore/Content/ContentLoader.swift`, `ContentValidator.swift`, `GameContent.swift`, `*Defs.swift`, `MapDef.swift`.
- `Core/Sources/HoldoutCore/Model/GameState.swift`, `NewGame.swift`, `Base.swift`, `Group.swift`, `Building.swift`, `GridPoint.swift`.
- Tests: `Core/Tests/HoldoutCoreTests/Content/ContentFilesTests.swift`, `Simulation/GameLoopTests.swift`, `TestSupport.swift`.

## Key rules
- Core reads no clock; time only enters through `advance(realSeconds:)` / `step(ticks:)`.
- Content for zombies, units, hordes, research, offline is decoded and validated now but not used until 1B–1D.
- Tests read the repo's `Content/` via `#filePath` (D-010); the App passes its bundled copy.

## Known issues
- (none yet)

## Change log
- 2026-10-31 — Added `presentation.json` decoding (`GameContent.presentation`) and `Presentation/GridProjection` (1V; not used by the simulation).
- 2026-10-31 — Created for milestone 1A (Core half).

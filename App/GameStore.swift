// Purpose: Bridge between the UI and Core: owns the GameLoop, ticks it from frame time, sends Commands, saves. Notes: docs/features/hud-ui.md
import Foundation
import Observation
import HoldoutCore

@MainActor @Observable
final class GameStore {
    /// Phase 1 has one map; a new game always starts here.
    static let startingMapId = "phase1_exit"

    /// The running simulation (nil if content failed to load). Read it; change it only through `send`.
    private(set) var loop: GameLoop?
    /// Why the game couldn't start (shown full screen instead of the game).
    private(set) var loadError: String?
    /// Latest resource numbers for the HUD (only reassigned when they change).
    private(set) var resources: ResourceSnapshot?
    /// Horde day, countdown, warned edges, zombies left (reassigned only when the HUD would show something different).
    private(set) var hordeStatus: HordeStatus?
    /// Horde start / held / HQ fell message shown over the map (HordeBannerView hides it after a few seconds).
    private(set) var banner: HordeBanner?
    @ObservationIgnored private var bannerCount = 0
    /// The selected building as of the last frame (for the selection bar's live progress).
    private(set) var selectedBuilding: Building?
    /// A short message for the player, e.g. why demolishing failed. The UI clears it.
    var notice: String?

    let placement = PlacementController()
    @ObservationIgnored let lifecycle = AppLifecycle()
    /// True while something covers the game and time must not pass (the DEBUG 3D spike). Checked by GameTicker.
    @ObservationIgnored var isClockPaused = false
    /// Ground tile at the middle of the screen; the 3D view updates it so new ghosts appear in view.
    @ObservationIgnored var viewCenterTile = GridPoint(x: 0, y: 0)
    @ObservationIgnored private let saveStore: SaveFileStore

    init(saveStore: SaveFileStore = SaveFileStore()) {
        self.saveStore = saveStore
        start()
    }

    var content: GameContent? { loop?.content }

    // MARK: Start and save

    /// Loads the bundled Content folder, then the save file (or a new game if there is none).
    private func start() {
        guard let contentURL = Bundle.main.url(forResource: "Content", withExtension: nil) else {
            loadError = "The Content folder is missing from the app bundle."
            return
        }
        do {
            let content = try ContentLoader.load(from: contentURL)
            let state: GameState
            if let data = saveStore.read() {
                do {
                    state = try SaveCodec.decode(data)
                } catch {
                    saveStore.setAsideBroken()
                    notice = "Your save couldn't be read, so a new town was started. The old file was kept."
                    state = try Self.newGame(content)
                }
            } else {
                state = try Self.newGame(content)
            }
            loop = try GameLoop(content: content, state: state)
            Self.forgetRetiredViewSettings()
            lifecycle.configure(autosaveSeconds: content.economy.autosaveSeconds)
            refresh()
        } catch {
            loadError = "\(error)"
        }
    }

    private static func newGame(_ content: GameContent) throws -> GameState {
        try GameState.newGame(content: content, mapId: startingMapId, seed: UInt64.random(in: 0...UInt64.max))
    }

    /// Writes the current state to disk. Called on background and by the autosave clock.
    func save() {
        guard let loop else { return }
        do {
            try saveStore.write(SaveCodec.encode(loop.state))
        } catch {
            notice = "Saving failed: \(error.localizedDescription)"
        }
    }

    /// Settings from the retired 2D views (D-030) are no longer read; tidy them out of UserDefaults.
    private static func forgetRetiredViewSettings() {
        for key in ["view.preferred", "view.autoTopDownWhilePlacing", "view.autoTopDownWhilePlacing.v2", "debugRenderer"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: Every frame

    /// Called by GameTicker once per screen frame with real seconds since the last frame. Returns what happened in Core
    /// since the last frame (the 3D view will draw these as effects, chunk 4R); banner-worthy events also set `banner`.
    @discardableResult
    func advance(realSeconds: Double) -> [SimEvent] {
        guard let loop else { return [] }
        loop.advance(realSeconds: realSeconds)
        let events = loop.drainEvents()
        for event in events {
            if let next = HordeBanner(event: event, id: bannerCount + 1) {
                bannerCount += 1
                banner = next
            }
        }
        refresh()
        if lifecycle.autosaveDue(afterRealSeconds: realSeconds) { save() }
        return events
    }

    func dismissBanner(id: Int) {
        if banner?.id == id { banner = nil }
    }

    private func refresh() {
        guard let loop else { return }
        let snapshot = loop.resources
        if snapshot != resources { resources = snapshot }
        let horde = loop.hordeStatus
        if !horde.looksSameOnHUD(as: hordeStatus) { hordeStatus = horde }
        placement.refresh(loop: loop)
        let selected: Building? = if case .selected(let id) = placement.mode { loop.state.base.building(id) } else { nil }
        if selected != selectedBuilding { selectedBuilding = selected }
    }

    // MARK: Player actions (all go through Core Commands)

    @discardableResult
    private func send(_ command: Command) -> Result<CommandOutcome, CommandError>? {
        guard let loop else { return nil }
        let result = loop.send(command)
        if case .failure(let error) = result, let content {
            notice = PlacementMessages.text(for: error, content: content)
        }
        refresh()
        return result
    }

    /// `drawnBuilding`: the building whose picture was tapped (isometric roofs), checked before the ground tile.
    func tapped(tile: GridPoint, drawnBuilding: BuildingID? = nil) {
        guard let loop else { return }
        if placement.isDrawingLine {
            placement.setLine(from: tile, to: tile, loop: loop)  // a tap is a one-wall line; drag for more
        } else if placement.isPositioning {
            placement.moveGhost(centeredOn: tile, loop: loop)
        } else {
            placement.select(drawnBuilding ?? loop.building(at: tile)?.id)
        }
        refresh()
    }

    func beginPlacing(defId: String) {
        guard let loop, let def = loop.content.buildingDef(defId) else { return }
        if PlacementController.usesLineTool(def) {
            placement.beginLine(defId: defId)  // walls: drag out a line, see the cost, then Build
        } else {
            placement.beginPlacing(defId: defId, around: viewCenterTile, loop: loop)
        }
    }

    func beginMoving() {
        guard let loop else { return }
        placement.beginMoving(loop: loop)
    }

    func confirmPlacement() {
        guard let command = placement.pendingCommand else { return }
        if case .success(let outcome) = send(command) {
            if case .placedLine = outcome {
                placement.clearLine()  // stay in the wall tool for the next line
            } else if case .placed(let id) = outcome {
                // 1×1 defenses keep the ghost so a line of walls is quick to lay; anything else selects what was placed.
                if let content, !placement.staysPlacingAfterConfirm(content: content) { placement.select(id) }
            } else {
                placement.cancel()
            }
            refresh()
        }
    }

    func cancelPlacement() {
        placement.cancel()
        refresh()
    }

    func demolishSelected() {
        guard case .selected(let id) = placement.mode else { return }
        if case .success = send(.demolish(id: id)) {
            placement.select(nil)
            refresh()
        }
    }

    /// Repairs the selected building, or rebuilds it if it is rubble (cost and time come from Core).
    func repairSelected() {
        guard case .selected(let id) = placement.mode else { return }
        send(.repair(id: id))
    }

    #if DEBUG
    /// Testing commands from the debug menu (DEBUG builds only).
    func sendDebug(_ command: Command) {
        send(command)
    }
    #endif

    func deselect() {
        placement.select(nil)
        refresh()
    }
}

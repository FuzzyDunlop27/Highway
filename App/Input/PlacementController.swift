// Purpose: Tracks what the player is placing, moving, or has selected, and whether the ghost's spot is valid. Notes: docs/features/input.md
import Foundation
import Observation
import HoldoutCore

@MainActor @Observable
final class PlacementController {
    enum Mode: Equatable {
        case idle
        case selected(BuildingID)
        case placing(defId: String)
        case moving(BuildingID)
    }

    private(set) var mode: Mode = .idle
    /// Top-left tile of the ghost preview (only meaningful while placing or moving).
    private(set) var ghostOrigin = GridPoint(x: 0, y: 0)
    /// Which building type the ghost shows, or nil when there is no ghost.
    private(set) var ghostDefId: String?
    /// Core's answer for the ghost's current spot (problem + red tiles).
    private(set) var check: PlacementCheck?
    /// Finger tile minus ghost origin while dragging the ghost, so it doesn't jump under the finger.
    @ObservationIgnored private var dragOffset: GridPoint?

    var isPositioning: Bool { ghostDefId != nil }

    /// The Command that "Confirm" would send, if the ghost is showing.
    var pendingCommand: Command? {
        switch mode {
        case .placing(let defId): .placeBuilding(defId: defId, at: ghostOrigin)
        case .moving(let id): .moveBuilding(id: id, to: ghostOrigin)
        default: nil
        }
    }

    // MARK: Mode changes

    func beginPlacing(defId: String, around tile: GridPoint, loop: GameLoop) {
        guard let def = loop.content.buildingDef(defId) else { return }
        mode = .placing(defId: defId)
        ghostDefId = defId
        ghostOrigin = Self.clamped(Self.origin(centeredOn: tile, def: def), def: def, map: loop.map)
        refresh(loop: loop)
    }

    /// Starts moving the selected building; the ghost begins where the building is.
    func beginMoving(loop: GameLoop) {
        guard case .selected(let id) = mode, let building = loop.state.base.building(id) else { return }
        mode = .moving(id)
        ghostDefId = building.defId
        ghostOrigin = building.origin
        refresh(loop: loop)
    }

    func select(_ id: BuildingID?) {
        mode = id.map { .selected($0) } ?? .idle
        ghostDefId = nil
        check = nil
        dragOffset = nil
    }

    /// Cancel goes back to the building that was being moved, or to nothing.
    func cancel() {
        if case .moving(let id) = mode { select(id) } else { select(nil) }
    }

    // MARK: Ghost position

    func moveGhost(centeredOn tile: GridPoint, loop: GameLoop) {
        guard let defId = ghostDefId, let def = loop.content.buildingDef(defId) else { return }
        setGhostOrigin(Self.origin(centeredOn: tile, def: def), def: def, loop: loop)
    }

    /// True if `tile` is under the ghost (a drag starting there moves the ghost, not the camera).
    func ghostCovers(_ tile: GridPoint, loop: GameLoop) -> Bool {
        guard let defId = ghostDefId, let def = loop.content.buildingDef(defId) else { return false }
        return ghostOrigin.footprintTiles(width: def.width, height: def.height).contains(tile)
    }

    func beginDrag(at tile: GridPoint) {
        dragOffset = GridPoint(x: tile.x - ghostOrigin.x, y: tile.y - ghostOrigin.y)
    }

    func drag(to tile: GridPoint, loop: GameLoop) {
        guard let offset = dragOffset, let defId = ghostDefId, let def = loop.content.buildingDef(defId) else { return }
        setGhostOrigin(GridPoint(x: tile.x - offset.x, y: tile.y - offset.y), def: def, loop: loop)
    }

    func endDrag() { dragOffset = nil }

    private func setGhostOrigin(_ origin: GridPoint, def: BuildingDef, loop: GameLoop) {
        let clamped = Self.clamped(origin, def: def, map: loop.map)
        if clamped != ghostOrigin { ghostOrigin = clamped }
        refresh(loop: loop)
    }

    // MARK: Validity

    /// Re-asks Core whether the ghost spot is valid (resources change every tick, so this runs every frame).
    func refresh(loop: GameLoop) {
        let newCheck: PlacementCheck?
        switch mode {
        case .placing(let defId):
            newCheck = loop.checkPlacement(defId: defId, at: ghostOrigin)
        case .moving(let id):
            guard let moveCheck = loop.checkMove(id: id, to: ghostOrigin) else { select(nil); return }
            newCheck = moveCheck
        case .selected(let id):
            if loop.state.base.building(id) == nil { select(nil) }
            return
        case .idle:
            return
        }
        if newCheck != check { check = newCheck }
    }

    // MARK: Helpers

    /// Origin that puts the footprint's middle on `tile` (2×2: tile is top-left; 3×3: tile is the center).
    static func origin(centeredOn tile: GridPoint, def: BuildingDef) -> GridPoint {
        GridPoint(x: tile.x - (def.width - 1) / 2, y: tile.y - (def.height - 1) / 2)
    }

    /// Keeps the whole ghost on the map so it can never be lost off-screen.
    static func clamped(_ origin: GridPoint, def: BuildingDef, map: MapDef) -> GridPoint {
        GridPoint(x: min(max(origin.x, 0), max(0, map.width - def.width)),
                  y: min(max(origin.y, 0), max(0, map.height - def.height)))
    }
}

// Purpose: Finds the nearest spot where a building fits on the ground (the placement ghost opens there). Notes: docs/features/construction.md
import Foundation

enum SpotFinder {
    /// The top-left tile, within `rules.suggestSpotRadiusTiles` of `near`, whose footprint middle is closest to `near`
    /// and whose ground is free (map, terrain, decorations, other buildings except `ignoring`). Ties go to the
    /// lower row, then the lower column, so the answer never changes for the same town. Nil if nothing fits.
    static func nearest(defId: String, facing: Facing, near: GridPoint, ignoring: BuildingID?,
                        state: GameState, content: GameContent) -> GridPoint? {
        guard let def = content.buildingDef(defId), let map = content.maps[state.base.mapId] else { return nil }
        let size = def.size(facing: facing)
        let ground = GroundTiles(base: state.base, map: map, content: content, ignoring: ignoring)
        let radius = max(0, content.buildings.rules.suggestSpotRadiusTiles)
        // Work in half tiles so the footprint middle stays a whole number.
        let halfW = size.width - 1, halfH = size.height - 1
        var best: (distance: Int, origin: GridPoint)?
        for y in (near.y - radius)...(near.y + radius) {
            for x in (near.x - radius)...(near.x + radius) {
                let origin = GridPoint(x: x - halfW / 2, y: y - halfH / 2)
                let dx = 2 * origin.x + halfW - 2 * near.x, dy = 2 * origin.y + halfH - 2 * near.y
                let distance = dx * dx + dy * dy
                if let best, best.distance < distance || (best.distance == distance && isBefore(best.origin, origin)) {
                    continue
                }
                let tiles = def.footprintTiles(at: origin, facing: facing)
                if ground.problem(tiles: tiles, map: map).0 == nil { best = (distance, origin) }
            }
        }
        return best?.origin
    }

    private static func isBefore(_ a: GridPoint, _ b: GridPoint) -> Bool { a.y != b.y ? a.y < b.y : a.x < b.x }
}

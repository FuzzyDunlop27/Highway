// Purpose: Which models each DEBUG spike scene places, and where (1R study town, free-asset lineup). Notes: docs/research/free-assets.md
#if DEBUG
import Foundation

/// The spike can show our own Blender study town (1R) or the free CC0 asset lineup (free-asset spike).
enum Spike3DScene: String, CaseIterable {
    case study = "Study models"
    case freeAssets = "Free assets"

    /// One placed model. Position in tiles (x east, y up, z south). `unitMetres` = how many real metres one model
    /// unit is (Poly Haven/Quaternius 1, Kenney cells 3); 0 = study model, already 1 tile = 1 m.
    struct Placement {
        let id: String
        let x, y, z, turn, unitMetres: Float
    }

    var layout: [Placement] {
        switch self {
        case .study: [
            .study("bld_hq", 0, 0), .study("bld_shelter", -4, -0.5), .study("bld_farm", 4, -0.5),
            .study("def_watchtower_base", 2.5, 3), .study("dec_car_wreck", -2, 5.5, turn: 0.3),
            .study("def_wall_wood", -1, 2.5), .study("def_wall_wood", 0, 2.5), .study("def_wall_wood", 1, 2.5),
            .study("def_wall_wood", -2.5, 1, turn: .pi / 2), .study("def_wall_wood", -2.5, 0, turn: .pi / 2),
        ]
        case .freeAssets: Self.polyHaven + Self.kenney + Self.quaternius
        }
    }

    /// Realistic props (real metres).
    private static let polyHaven: [Placement] = [
        .init(id: "fa_ph_covered_car", x: -1.5, y: 0, z: 5.4, turn: 1.3, unitMetres: 1),
        .init(id: "fa_ph_covered_car", x: 2.5, y: 0, z: 5.7, turn: 1.7, unitMetres: 1),
        .init(id: "fa_ph_road_barrier", x: -1, y: 0, z: 2.5, turn: 0, unitMetres: 1),
        .init(id: "fa_ph_road_barrier", x: -0.35, y: 0, z: 2.5, turn: 0, unitMetres: 1),
        .init(id: "fa_ph_road_barrier", x: 0.3, y: 0, z: 2.5, turn: 0, unitMetres: 1),
        .init(id: "fa_ph_road_barrier", x: 0.95, y: 0, z: 2.5, turn: 0, unitMetres: 1),
        .init(id: "fa_ph_trash_can", x: -0.5, y: 0, z: -0.8, turn: 0, unitMetres: 1),
        .init(id: "fa_ph_barrel", x: 1.4, y: 0, z: 0.4, turn: 0, unitMetres: 1),
        .init(id: "fa_ph_barrel", x: 1.65, y: 0, z: 0.55, turn: 0.8, unitMetres: 1),
        .init(id: "fa_ph_barrel", x: 1.5, y: 0, z: 0.75, turn: 2, unitMetres: 1),
        .init(id: "fa_ph_old_tyre", x: 0.6, y: 0, z: 1.2, turn: 0.4, unitMetres: 1),
        .init(id: "fa_ph_old_tyre", x: 0.75, y: 0, z: 1.3, turn: 1.9, unitMetres: 1),
    ]

    /// Low-poly Kenney cells: a two-cell shop (door + window, roof on top), a truck and a dumpster, west of the props.
    private static let kenney: [Placement] = {
        let cell: Float = 3 * 0.41  // one Kenney cell ≈ 3 m ≈ 1.23 tiles (keep in step with freeAssets.metresToTiles)
        return [
            .init(id: "fa_kn_wall_door", x: -4, y: 0, z: -1.5, turn: 0, unitMetres: 3),
            .init(id: "fa_kn_wall_window", x: -4 + cell, y: 0, z: -1.5, turn: 0, unitMetres: 3),
            .init(id: "fa_kn_roof", x: -4, y: cell, z: -1.5, turn: 0, unitMetres: 3),
            .init(id: "fa_kn_roof", x: -4 + cell, y: cell, z: -1.5, turn: 0, unitMetres: 3),
            .init(id: "fa_kn_truck", x: -4.5, y: 0, z: 1.5, turn: 0.4, unitMetres: 3),
            .init(id: "fa_kn_dumpster", x: -2.4, y: 0, z: -0.2, turn: 0, unitMetres: 3),
        ]
    }()

    /// Quaternius: a 6 × 6 m two-storey shop assembled from modular pieces (the chosen direction, D-036), east of the
    /// props, and the prebuilt city block (12 × 15 × 17 m) beyond the walker rings to the north, for comparison.
    private static let quaternius: [Placement] = [
        .init(id: "fa_qt_shop", x: 4.2, y: 0, z: -1.5, turn: 0, unitMetres: 1),
        .init(id: "fa_qt_shop_512", x: 4.2, y: 0, z: 2.2, turn: 0, unitMetres: 1),  // same shop, 512 px textures
        .init(id: "fa_qt_building_small", x: 1, y: 0, z: -16.5, turn: 0, unitMetres: 1),
    ]
}

private extension Spike3DScene.Placement {
    static func study(_ id: String, _ x: Float, _ z: Float, turn: Float = 0) -> Self {
        .init(id: id, x: x, y: 0, z: z, turn: turn, unitMetres: 0)
    }
}
#endif

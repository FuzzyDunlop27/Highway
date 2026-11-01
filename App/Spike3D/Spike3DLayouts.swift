// Purpose: Which models each DEBUG spike scene places, and where (1R study town, free-asset lineup). Notes: docs/research/free-assets.md
#if DEBUG
import Foundation

/// The spike can show our own Blender study town (1R) or the free CC0 asset lineup (free-asset spike).
enum Spike3DScene: String, CaseIterable {
    case study = "Study models"
    case freeAssets = "Free assets"

    /// Models placed at tile positions (x east, z south), metres. `realScale` = model is in real metres
    /// (free assets) and gets `freeAssets.metresToTiles`; study models are already 1 tile = 1 m.
    var layout: [(id: String, x: Float, z: Float, turn: Float, realScale: Bool)] {
        switch self {
        case .study: [
            ("bld_hq", 0, 0, 0, false), ("bld_shelter", -4, -0.5, 0, false), ("bld_farm", 4, -0.5, 0, false),
            ("def_watchtower_base", 2.5, 3, 0, false), ("dec_car_wreck", -2, 5.5, 0.3, false),
            ("def_wall_wood", -1, 2.5, 0, false), ("def_wall_wood", 0, 2.5, 0, false), ("def_wall_wood", 1, 2.5, 0, false),
            ("def_wall_wood", -2.5, 1, .pi / 2, false), ("def_wall_wood", -2.5, 0, .pi / 2, false),
        ]
        case .freeAssets: [
            // Kenney / Quaternius buildings join here once downloaded (fa_kn_*, fa_qt_*); missing ones are listed on screen.
            ("fa_kn_building", -3.5, -2, 0, true), ("fa_qt_building", 3.5, -2.5, 0, true),
            ("fa_ph_covered_car", -1.5, 5.4, 1.3, true), ("fa_ph_covered_car", 2.5, 5.7, 1.7, true),
            ("fa_ph_road_barrier", -1, 2.5, 0, true), ("fa_ph_road_barrier", -0.35, 2.5, 0, true),
            ("fa_ph_road_barrier", 0.3, 2.5, 0, true), ("fa_ph_road_barrier", 0.95, 2.5, 0, true),
            ("fa_ph_trash_can", -0.5, -0.8, 0, true),
            ("fa_ph_barrel", 1.4, 0.4, 0, true), ("fa_ph_barrel", 1.65, 0.55, 0.8, true), ("fa_ph_barrel", 1.5, 0.75, 2, true),
            ("fa_ph_old_tyre", 0.6, 1.2, 0.4, true), ("fa_ph_old_tyre", 0.75, 1.3, 1.9, true),
        ]
        }
    }
}
#endif

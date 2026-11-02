# Feature: The Chicago block map (`phase1_chicago`)

_Owner request 2026-11-01 (D-044). New games start here; a town saved on the old highway map (`phase1_exit`) keeps that map._

## Purpose
The first map feels like a lived-in Chicago neighborhood: a 4-lane street with storefronts, a 2-lane side street, an alley behind houses and garages, vacant lots, a community garden and a parking lot. The town starts inside a closed barricade of 28 Chain Fence sections (D-023 ring, fence since D-044), so you never start from nothing.

## Layout (40 × 30 tiles, y = 0 is north)
- **Main street** (rows 4–8, east–west): parking lane, dashed lane line, double yellow, dashed lane line, parking lane; sidewalks on rows 3 and 9; not buildable. Zombies enter at both ends.
- **Side street** (columns 25–27, north–south, double yellow in column 26) with sidewalks in columns 24 and 28; buildable (you can barricade it). Zombies enter at the top and bottom.
- **North of the main street:** storefronts, a 3-storey mixed-use block, a 4-storey walk-up and two taverns, with a fenced vacant lot.
- **South of the main street:** parkway trees (row 10); an old gas-station lot with wrecks (west); the **starting compound** on a concrete pad: chain-link fence x 13–21, y 14–20, HQ at (15,16), watchtower (19,17), with cars and junk dragged against it; a vacant lot and dirt patch west of it; a corner store and a courtyard apartment building facing the main street (east) and a weedy vacant lot behind them.
- **Alley** (row 22, gravel) with trash cans; **garages** on the alley; **houses** (two-flats, three-flats, bungalows, a cottage) facing the street beyond the south edge; an overgrown lot and a community garden between them.
- Street lights, hydrants, abandoned cars on the side street.
- Spawn edge ids are the old ones (`highway_onramp_west`, `highway_offramp_east`, `side_road_north`, `side_road_south`) because `hordes.json` lists them; they now sit at the ends of the main street and the side street.

## Swapping looks (placeholders)
- **Ground:** every tile id has a texture slot in `Content/presentation.json` → `reality3d.groundTextures` (file, `repeatTiles`, `tint`). Files are in `App/Textures/Ground/`. Replace a file with the same name, or point `file` at a new image. A missing image draws the flat placeholder colour; a content test fails if a map uses a tile id with no slot.

  | Tile id | Used for | File now |
  |---|---|---|
  | `tile_grass` | lawns, parkway | `grass_ground_diff.jpg` (Poly Haven) |
  | `tile_lot` | vacant / overgrown lots | `vacant_lot_diff.jpg` (Poly Haven brown_mud_leaves_01) |
  | `tile_dirt` | dirt patches | `muddy_tracks_diff.jpg` |
  | `tile_gravel` | alleys | `concrete_rock_path_diff.jpg`, lightened |
  | `tile_sidewalk` | sidewalks | `cracked_concrete_02_diff.jpg`, lightened |
  | `tile_concrete` | parking lots, compound pad, garage aprons | `cracked_concrete_02_diff.jpg` |
  | `tile_soil` | community garden | `garden_soil_diff.jpg` (Poly Haven farm_soil) |
  | `tile_road` | asphalt | `road_asphalt.jpg` — **placeholder** (darkened stone, no real asphalt yet) |
  | `tile_road_lane_ew` | dashed white lane line | `road_lane_ew.jpg` — **placeholder** |
  | `tile_road_center_ew` / `tile_road_center_ns` | double yellow | `road_center_ew.jpg` / `road_center_ns.jpg` — **placeholder** |

  The `road_*` images are made by `tools/blender/make_ground_textures.py` (lines at 1/4 and 3/4 of the image = the middle of each tile, since they repeat every 2 tiles). With a real asphalt download, point the script at it and re-run, or paint your own.
- **Houses:** wall texture per house in `tools/blender/recipes_neighborhood.py` → `FACADES` (two-flat yellow brick, three-flat and bungalow red brick, cottage wood, courtyard yellow brick, garage corrugated metal). Change the name, then re-export that art id (command at the top of that file).
- **Storefronts:** Quaternius kit pieces named in `tools/blender/recipes_storefronts.py`.
- **Any building or prop:** each has its own art id (`dec_bld_*`, `dec_garage`, `dec_streetlight`, …). A missing or broken `App/Models/<id>.usdz` draws a labelled box, so a model can be replaced (same file name) or deleted without breaking the game.

## Files involved
- `Content/maps/phase1_chicago.json` — the map (rows, legend, decorations with `faces`, spawn edges, starting barricade).
- `Content/presentation.json` → `reality3d.groundTextures` — the ground texture slots.
- `App/GameStore.swift` → `startingMapId`; DEBUG `startNewTown()` (old save kept as `save.old-<time>.json`); `townNumber` rebuilds the 3D view (`GameRootView`).
- `App/Rendering/GroundMesh3D.swift` — draws decorations turned by `faces`.
- `Core/Sources/HoldoutCore/Content/MapDef.swift` (`DecorationDef.faces`, `quarterTurns`), `ContentValidator.swift` (checks `faces`).
- Models: `tools/blender/recipes_neighborhood.py`, `recipes_storefronts.py`, `building_kit.py`; ground images `tools/blender/make_ground_textures.py`.
- Tests: `Core/Tests/HoldoutCoreTests/Content/ChicagoMapTests.swift`.
- Pictures: `docs/plans/chicago-map/overview.jpg`, `compound.jpg`, `fence-barricade.jpg`; model sheets `docs/plans/models-2m/dec_*.jpg`.

## Rules
- Decorations block building and zombies (like before). `faces` is look only; `footprint` is what the decoration covers on the map **after** turning (a 3 × 4 house facing east covers [4, 3]).
- Every spawn edge must be able to reach the HQ (test). Keep roads open when moving decorations.
- Core tests still use `phase1_exit` as their fixture map; `ChicagoMapTests` covers this one.

## Known issues / not done
- Frame rate with ~80 decorations not measured (no fps readout until RND-005); looked smooth in the simulator.
- No real asphalt, sidewalk curb, crosswalk or street-sign art yet; trees are the dead-tree model only (no live trees downloaded).
- Houses and garages are simple textured boxes (windows, bays, stoops, hipped roofs), not detailed models.

## Change log
- 2026-11-01 — Starting barricade switched to the Chain Fence model (owner).
- 2026-11-01 — Created: Chicago block map, 15 new neighborhood models, road line textures, `faces` for decorations, DEBUG "Start new town" (D-044).

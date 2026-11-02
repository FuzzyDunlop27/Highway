# Purpose: Map dressing recipes: small piles of Poly Haven props and weeds placed around the map as decorations. Notes: docs/features/models-3d.md
# One tile ≈ 2.44 m; origin at the footprint's ground centre, front towards -Y. Decorations block building and zombies
# (MapDef.decorationTiles), so these are only placed where that does no harm (see Content/maps/phase1_exit.json).
import math

from blend_parts import blend_part
from model_kit import material, prop


def fuel_cache():
    """Gas bottles and fuel cans left by the roadside."""
    prop('small_lpg_tank', -0.45, 0.25, 0, turn=0.3)
    prop('propane_tank', 0.35, 0.45, 0, turn=1.1)
    prop('plastic_jerrycan', 0.45, -0.35, 0, turn=-0.4)
    prop('metal_jerrycan_green', -0.2, -0.5, 0, turn=0.9)
    prop('metal_jerrycan_green', 0.9, 0.0, 0, turn=0.2, tilt=(math.pi / 2, 0))  # one knocked over


def supply_crates():
    """A pair of old military crates with a wooden crate and ammo boxes on top."""
    prop('old_military_crate', 0, 0.2, 0, scale=0.8, turn=0.1)
    prop('wooden_crate_01', -0.6, -0.65, 0, turn=0.4)
    prop('ammo_box', 0.5, -0.55, 0, scale=2.0, turn=-0.3)
    prop('ammo_box', 0.55, -0.6, 0.18, scale=2.0, turn=0.2)


def camp():
    """An abandoned camp: picnic table, barrel stove and a crate (two tiles along X)."""
    table = prop('wooden_picnic_table', -0.9, 0.0, 0, turn=math.pi / 2 + 0.1, scale=0.6)  # the scan is oversized
    table.data.materials.clear()  # the 1k download has no textures; plain planks instead
    table.data.materials.append(material('brown_planks_05', metres=1.2))
    prop('barrel_stove', 1.3, 0.2, 0)
    prop('plastic_crate_02', 1.9, -0.5, 0, turn=0.5)
    prop('Barrel_02', 2.0, 0.6, 0, turn=0.8)


def junk_pile():
    """Rusty barrels, a trash can and a stack of tyres."""
    prop('Barrel_02', -0.4, 0.4, 0, turn=0.2)
    prop('Barrel_01', 0.3, 0.55, 0, turn=1.4)
    prop('metal_trash_can', 0.6, -0.35, 0, turn=0.5)
    for i in range(3):
        prop('old_tyre', -0.5, -0.5, 0.08 + i * 0.16, turn=i * 0.4, tilt=(math.pi / 2, 0))


WEEDS = [  # (x, y, turn, object): grass clumps and dandelions, scaled up a little so they read at game zoom
    (-0.7, 0.6, 0.3, 'grass_medium_02_e'), (0.5, 0.7, 1.9, 'grass_medium_02_d'), (0.0, -0.1, 0.8, 'grass_medium_02_e'),
    (-0.6, -0.6, 2.6, 'grass_medium_02_c'), (0.7, -0.5, 4.0, 'grass_medium_02_d'), (0.2, 0.3, 5.1, 'grass_medium_02_b'),
    (-0.2, -0.8, 1.2, 'grass_medium_02_c'), (0.9, 0.2, 3.3, 'grass_medium_02_c'),
]
DANDELIONS = [(-0.3, 0.3, 0.4, 'dandelion_01_a_LOD2'), (0.4, -0.2, 2.0, 'dandelion_01_b_LOD2'),
              (-0.8, -0.1, 3.5, 'dandelion_01_a_LOD2'), (0.6, 0.4, 1.1, 'dandelion_01_c_LOD2')]
WEED_SCALE = 3.0


def weeds():
    """A patch of tall grass and dandelions."""
    for x, y, turn, name in WEEDS:
        blend_part('grass_medium_02', name, x, y, 0, turn=turn, scale=WEED_SCALE, cutout=True)
    for x, y, turn, name in DANDELIONS:
        blend_part('dandelion_01', name, x, y, 0, turn=turn, scale=WEED_SCALE, cutout=True)


# art id: (recipe, footprint tiles w × h)
RECIPES = {
    'dec_fuel_cache': (fuel_cache, (1, 1)), 'dec_supply_crates': (supply_crates, (1, 1)),
    'dec_camp': (camp, (2, 1)), 'dec_junk_pile': (junk_pile, (1, 1)), 'dec_weeds': (weeds, (1, 1)),
}

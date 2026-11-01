# Purpose: Chunk 2M recipes for every building, construction site and rubble model (Quaternius kit + Poly Haven props). Notes: docs/features/models-3d.md
# Real metres; 1 tile ≈ 2.44 m, so a 2×2 footprint is ~4.9 m (shell 4 × 4 m) and the 3×3 HQ ~7.3 m (shell 6 × 6 m).
import math

from model_kit import flat_roof, piece, prop, sandbag_row, wall_ring

BRICK = 'Brick_Plain_3'
SHOP = 'Metal_FirstFloor_Window'
SHOP_WALL = 'Metal_FirstFloor_Wall'


def _cornice(half, z, name='Cornice_Brick_Center'):
    n = round(half)
    wall_ring(half, half, z, {s: [name] * n for s in ('front', 'back', 'left', 'right')})


def hq():
    """Two-storey corner shop turned HQ: glass shopfront, brick upstairs, sandbagged roof lookout, supplies by the door."""
    h = 3.0
    wall_ring(h, h, 0, {'front': [SHOP, 'DoorFrame_Metal_Single', SHOP], 'left': [SHOP_WALL, SHOP, SHOP_WALL],
                        'right': [SHOP_WALL] * 3, 'back': [SHOP_WALL] * 3})
    wall_ring(h, h, 3, {'front': ['Brick_Window_Trim_Single'] * 3,
                        'left': [BRICK, 'Brick_Window_Square_Single', BRICK],
                        'right': [BRICK, 'Brick_Window_Square_Single', BRICK], 'back': [BRICK] * 3})
    _cornice(h, 6)
    flat_roof(h, h, 6.4)
    sandbag_row(-1.4, 1.4, -2.2, 6.4)
    piece('Prop_ACUnit', 1.6, 1.4, 6.4)
    for i, x in enumerate((-2.6, -2.0)):
        prop('Barrel_01', x, -3.4, 0, turn=i)
    prop('metal_jerrycan_green', 2.2, -3.3, 0, turn=0.3)
    prop('wooden_crate_01', 2.9, -3.35, 0, turn=0.1)


def shelter():
    """Two-storey brick apartment: windows on every side, a wooden door."""
    h = 2.0
    wall_ring(h, h, 0, {'front': ['Brick_Window_Square_Single', 'DoorFrame_Wooden'], 'back': [BRICK, 'Brick_Window_Square_Single'],
                        'left': ['Brick_Window_Square_Single', BRICK], 'right': [BRICK, 'Brick_Window_Square_Single']})
    wall_ring(h, h, 3, {'front': ['Brick_Window_CurvedDouble'], 'back': ['Brick_RedWhite_DoubleWindow'],
                        'left': ['Brick_Window_Square_Single', BRICK], 'right': [BRICK, 'Brick_Window_Square_Single']})
    _cornice(h, 6)
    flat_roof(h, h, 6.4)
    prop('plastic_crate_02', -2.2, -2.3, 0, turn=0.2)


def farm():
    """Raised garden beds behind a low brick wall, compost bags in the corner."""
    wall_ring(2.0, 2.0, 0, {'back': ['Brick_Plain_1'] * 2, 'left': ['Brick_Plain_1'] * 2})
    for row, y in enumerate((-1.3, -0.1, 1.1)):
        prop('planter_box_02', -0.9, y, 0, turn=0)
        prop('planter_box_01' if row % 2 else 'planter_box_02', 0.8, y, 0, turn=math.pi if row % 2 else 0)
    prop('compost_bags', 1.0, 2.0, 0, turn=math.pi, scale=0.8)


def scavenger():
    """One-storey metal garage: run supplies, tyres and fuel stacked out front."""
    h = 2.0
    wall_ring(h, h, 0, {'front': [SHOP, 'DoorFrame_Metal_Single'], 'back': [SHOP_WALL] * 2,
                        'left': [SHOP_WALL] * 2, 'right': [SHOP_WALL, SHOP]})
    _cornice(h, 3, 'Cornice_Metal_Center')
    flat_roof(h, h, 3.4)
    prop('hand_truck', -1.6, -2.2, 0, turn=0.5)
    for i in range(3):  # a stack of tyres lying flat
        prop('old_tyre', -0.6, -2.0, 0.08 + i * 0.16, tilt=(math.pi / 2, 0))  # tilting swings it 0.3 m south
    prop('metal_jerrycan_green', 1.9, -2.3, 0, turn=0.2)
    prop('metal_jerrycan_green', 2.3, -2.25, 0, turn=-0.3)


def workshop():
    """One-storey brick workshop with a wide glazed door, tools and gas bottles outside."""
    h = 2.0
    wall_ring(h, h, 0, {'front': ['DoorFrame_Metal_Single', 'Brick_Window_Square_Single'], 'back': [BRICK] * 2,
                        'left': ['Brick_Window_Square_Single', BRICK], 'right': [BRICK] * 2})
    _cornice(h, 3)
    flat_roof(h, h, 3.4)
    piece('Prop_ACUnit', 0.8, 0.6, 3.4)
    prop('metal_toolbox', 1.6, -2.3, 0, turn=0.2)
    prop('propane_tank', 2.2, -2.3, 0)
    prop('propane_tank', 2.2, -1.9, 0)
    prop('bench_vice_01', -2.3, -1.0, 0, turn=math.pi / 2, scale=0.6)


def barracks():
    """One-storey brick block behind a sandbag wall, ammo and military crates by the door."""
    h = 2.0
    wall_ring(h, h, 0, {'front': ['Brick_Window_Square_Single', 'DoorFrame_Metal_Single'], 'back': [BRICK] * 2,
                        'left': ['Brick_Window_Square_Single', BRICK], 'right': [BRICK, 'Brick_Window_Square_Single']})
    _cornice(h, 3)
    flat_roof(h, h, 3.4)
    for z in (0, 0.18):
        sandbag_row(-2.3, -0.6, -2.4, z)
    prop('old_military_crate', 1.4, -2.4, 0, scale=0.7)
    prop('ammo_box', -0.2, -2.35, 0, scale=2.0)


def storage():
    """One-storey metal warehouse, crates and pallets of salvage stacked against it."""
    h = 2.0
    wall_ring(h, h, 0, {'front': [SHOP_WALL, 'DoorFrame_Metal_Single'], 'back': ['Metal_Plain_3'] * 2,
                        'left': ['Metal_Plain_3'] * 2, 'right': ['Metal_Plain_3'] * 2})
    _cornice(h, 3, 'Cornice_Metal_Center')
    flat_roof(h, h, 3.4)
    prop('wooden_crate_02', -1.4, -2.2, 0, turn=math.pi / 2)
    prop('wooden_crate_01', -1.4, -2.2, 0.46, turn=math.pi / 2 + 0.1)
    prop('plastic_crate_02', 2.2, -0.8, 0, turn=0.4)
    prop('plastic_crate_02', 2.2, -0.8, 0.25, turn=0.1)


def construction(half):
    """Building site: first course of brick, bare metal columns at the corners, cement bags and a crate."""
    n = round(half)
    wall_ring(half, half, 0, {'front': ['Brick_Plain_1'] * n, 'left': ['Brick_Plain_1'] * n, 'back': [BRICK] * n})
    for sx in (-1, 1):
        for sy in (-1, 1):
            for z, part in ((0, 'Metal_Column_Small_Bottom'), (3, 'Metal_Column_Small_Top')):
                piece(part, sx * (half - 0.15), sy * (half - 0.15), z)
    for i in range(3):
        prop('cement_bag', 0.4 + i * 0.5, -half - 0.5, 0, turn=math.pi / 2 + i * 0.1)
    prop('cement_bag', 0.65, -half - 0.5, 0.18, turn=math.pi / 2)
    prop('wooden_crate_02', -half + 0.8, 0.4, 0, turn=0.3)


def rubble(scale):
    """Collapsed walls: broken brick slabs lying at angles, a fallen cornice, scattered bags."""
    s = scale
    k = min(1.0, s)  # kit slabs are 2 m wide; shrink them for the 1-tile pile
    piece('Brick_Plain_1', -0.6 * s, -0.3 * s, 0.0, turn=0.3, tilt=(math.radians(-80), 0), scale=k)
    piece('Brick_Plain_1', 0.5 * s, 0.4 * s, 0.0, turn=-0.9, tilt=(math.radians(-70), math.radians(10)), scale=k)
    piece('Cornice_Brick_Center', 0.2 * s, -0.8 * s, 0.0, turn=1.9, tilt=(math.radians(-90), 0), scale=k)
    if s > 1:
        piece('Brick_Plain_1', -0.4 * s, 0.8 * s, 0.0, turn=2.4, tilt=(math.radians(-85), 0), scale=k)
        prop('cement_bag', 0.9 * s, -0.4 * s, 0, turn=0.7)
    prop('wooden_crate_02', -1.0 * s, 0.1 * s, 0, turn=1.2, tilt=(0, math.radians(14)), scale=0.6)


# art id: (recipe, footprint tiles w × h)
RECIPES = {
    'bld_hq': (hq, (3, 3)), 'bld_shelter': (shelter, (2, 2)), 'bld_farm': (farm, (2, 2)),
    'bld_scavenger': (scavenger, (2, 2)), 'bld_workshop': (workshop, (2, 2)), 'bld_barracks': (barracks, (2, 2)),
    'bld_storage': (storage, (2, 2)),
    'bld_construction_2x2': (lambda: construction(2.0), (2, 2)), 'bld_construction_3x3': (lambda: construction(3.0), (3, 3)),
    'bld_rubble_2x2': (lambda: rubble(1.6), (2, 2)), 'dec_rubble': (lambda: rubble(0.55), (1, 1)),
}

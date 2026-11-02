# Purpose: Chicago commercial-street buildings for the phase1_chicago map (Quaternius kit pieces; map decorations, look only). Notes: docs/features/models-3d.md
# One tile ≈ 2.44 m; kit wall pieces are 2 m wide × 3 m tall, so a 4 × 3-tile lot gets an 8 × 6 m shell. Front towards -Y.
# These use the kit's own brick and glass; to change their look swap the kit piece names below and re-export.
import math

from model_kit import flat_roof, piece, prop, wall_ring

BRICK = 'Brick_Plain_3'
SHOP = 'Metal_FirstFloor_Window'
SHOP_WALL = 'Metal_FirstFloor_Wall'


def _ring(half_x, half_y, z, front, side, back):
    """One storey of kit pieces: `front` list along -Y, the same `side` piece on left and right, `back` piece."""
    nx, ny = round(half_x), round(half_y)
    wall_ring(half_x, half_y, z, {'front': front, 'left': [side] * ny, 'right': [side] * ny, 'back': [back] * nx})


def _top(half_x, half_y, z, cornice='Cornice_Brick_Center'):
    nx, ny = round(half_x), round(half_y)
    wall_ring(half_x, half_y, z, {'front': [cornice] * nx, 'back': [cornice] * nx, 'left': [cornice] * ny, 'right': [cornice] * ny})
    flat_roof(half_x, half_y, z + 0.4)


def storefront():
    """Two-storey shop: glass shopfront and door below, apartment windows above (4 × 3 tiles)."""
    hx, hy = 4, 3
    _ring(hx, hy, 0, [SHOP, 'DoorFrame_Metal_Single', SHOP, SHOP], SHOP_WALL, SHOP_WALL)
    _ring(hx, hy, 3, ['Brick_Window_Trim_Single'] * 4, BRICK, BRICK)
    _top(hx, hy, 6)
    piece('Prop_ACUnit', 2.0, 1.2, 6.4)
    prop('plastic_crate_02', -3.2, -3.6, 0, turn=0.4)


def mixed_use():
    """Three-storey mixed-use block: two shops below, two floors of flats above (5 × 3 tiles)."""
    hx, hy = 5, 3
    _ring(hx, hy, 0, [SHOP, SHOP, 'DoorFrame_Metal_Single', SHOP, SHOP], SHOP_WALL, SHOP_WALL)
    for z in (3, 6):
        _ring(hx, hy, z, ['Brick_Window_Square_Single', 'Brick_Window_Trim_Single', BRICK, 'Brick_Window_Trim_Single',
                          'Brick_Window_Square_Single'], 'Brick_Window_Square_Single', BRICK)
    _top(hx, hy, 9)
    piece('Prop_ACUnit', -3.0, 1.5, 9.4)
    piece('Prop_ACUnit', 2.5, 1.0, 9.4)


def tall():
    """Four-storey brick walk-up with arched double windows and a metal cornice (4 × 3 tiles)."""
    hx, hy = 4, 3
    _ring(hx, hy, 0, ['Brick_Inset', 'DoorFrame_Trim', BRICK], BRICK, BRICK)
    for z in (3, 6, 9):
        _ring(hx, hy, z, ['Brick_Window_CurvedDouble', 'Brick_Window_CurvedDouble'], 'Brick_Window_Square_Single', BRICK)
    _top(hx, hy, 12, 'Cornice_Metal_Center')


def tavern():
    """Corner tavern: arched ground-floor windows, wooden door, one floor of flats above (4 × 3 tiles)."""
    hx, hy = 4, 3
    _ring(hx, hy, 0, ['Brick_Inset_Window_Curved', 'DoorFrame_Wooden', 'Brick_Inset_Window_Curved', BRICK],
          'Brick_Inset_Window_Curved', BRICK)
    _ring(hx, hy, 3, ['Brick_Window_Square_Single'] * 4, 'Brick_Window_Square_Single', BRICK)
    _top(hx, hy, 6, 'Cornice_Trim_Center')
    prop('Barrel_01', 3.4, -3.2, 0)


def corner_store():
    """Two-storey corner store: shop windows on the front and the left (corner) side, flats above (4 × 4 tiles)."""
    hx, hy = 4, 4
    wall_ring(hx, hy, 0, {'front': [SHOP, 'DoorFrame_Metal_Single', SHOP, SHOP], 'left': [SHOP] * 4,
                          'right': [SHOP_WALL] * 4, 'back': [SHOP_WALL] * 4})
    wall_ring(hx, hy, 3, {'front': ['Brick_Window_Trim_Single'] * 4, 'left': ['Brick_Window_Trim_Single'] * 4,
                          'right': [BRICK, 'Brick_Window_Square_Single', 'Brick_Window_Square_Single', BRICK],
                          'back': [BRICK] * 4})
    _top(hx, hy, 6)
    for x in (-3.0, -2.2):
        prop('metal_trash_can', x, -4.3, 0, turn=x)
    piece('Prop_Bollard', 3.6, -4.3, 0)


# art id: (recipe, footprint tiles w × h, as modelled = facing south)
RECIPES = {
    'dec_bld_storefront': (storefront, (4, 3)), 'dec_bld_mixed_use': (mixed_use, (5, 3)),
    'dec_bld_tall': (tall, (4, 3)), 'dec_bld_tavern': (tavern, (4, 3)), 'dec_bld_corner_store': (corner_store, (4, 4)),
}

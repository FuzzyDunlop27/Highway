# Purpose: Chicago neighborhood houses and street props for the phase1_chicago map (map decorations, look only). Notes: docs/features/models-3d.md
# One tile ≈ 2.44 m. Real metres, front towards -Y (south); the map turns a decoration with its "faces" field.
# SWAP A LOOK: change the texture name in FACADES (any Poly Haven texture in free-assets/polyhaven/textures/), then
# re-export that art id: Blender -b -P tools/blender/export_usdz.py -- only=<art id>
import math

from building_kit import STOREY, bay, block, door, facade, hip_roof, stoop, windows
from model_kit import box, material, prop

TILE = 2.44

# Wall texture per house (texture slot). Chicago common brick is yellow; red brick for three-flats and bungalows.
FACADES = {
    'dec_bld_two_flat': 'yellow_brick',
    'dec_bld_three_flat': 'stacked_brick_wall',
    'dec_bld_bungalow': 'stacked_brick_wall',
    'dec_bld_cottage': 'brown_planks_05',
    'dec_bld_courtyard': 'yellow_brick',
    'dec_garage': 'corrugated_iron_02',
}


def _wall(art_id, metres=1.6):
    return facade(FACADES[art_id], metres)


def two_flat():
    """Two-flat: two storeys of yellow brick, a bay window, raised front door with a stone stoop (3 × 4 tiles)."""
    w, d, h = 6.4, 7.8, 2 * STOREY + 0.6
    wall = _wall('dec_bld_two_flat')
    block(w, d, h, wall)
    bay(-1.5, d, 2.6, 2, wall)
    windows('front', w, d, [1.7], [1])
    door(1.7, d, z=0.8)
    stoop(1.7, d, 0.8)
    for side in ('left', 'right'):
        windows(side, w, d, [-2.2, 0.3, 2.6], [0, 1])
    windows('back', w, d, [-1.6, 1.6], [0, 1])


def three_flat():
    """Three-flat: three storeys of red brick, a full-height bay, stone stoop (3 × 4 tiles)."""
    w, d, h = 6.6, 7.8, 3 * STOREY + 0.6
    wall = _wall('dec_bld_three_flat')
    block(w, d, h, wall)
    bay(1.5, d, 2.6, 3, wall)
    windows('front', w, d, [-1.8], [1, 2])
    door(-1.8, d, z=0.8)
    stoop(-1.8, d, 0.8)
    for side in ('left', 'right'):
        windows(side, w, d, [-2.2, 0.3, 2.6], [0, 1, 2])
    windows('back', w, d, [-1.6, 1.6], [0, 1, 2])


def bungalow():
    """Brick bungalow: one storey, wide front windows, hipped roof, small stoop (3 × 3 tiles)."""
    w, d, h = 6.2, 6.4, STOREY + 0.6
    wall = _wall('dec_bld_bungalow')
    block(w, d, h, wall, cornice=False)
    hip_roof(w, d, h, 2.2)
    windows('front', w, d, [-1.9, 1.9], [0], size=(1.6, 1.5))
    door(0, d, z=0.5)
    stoop(0, d, 0.5)
    for side in ('left', 'right'):
        windows(side, w, d, [-1.6, 1.6], [0])


def cottage():
    """Worker's cottage: small wooden house, two front windows, hipped roof (3 × 3 tiles)."""
    w, d, h = 5.4, 6.4, STOREY + 0.3
    wall = _wall('dec_bld_cottage', metres=1.2)
    block(w, d, h, wall, cornice=False)
    hip_roof(w, d, h, 2.6, material(None, tint=(0.22, 0.2, 0.18), roughness=1.0))
    windows('front', w, d, [-1.5], [0])
    door(1.3, d, z=0.4)
    stoop(1.3, d, 0.4, width=1.2)
    for side in ('left', 'right'):
        windows(side, w, d, [-1.4, 1.4], [0])


def courtyard():
    """Courtyard apartments: a U of three-storey yellow brick wings around a front garden (6 × 5 tiles)."""
    wall = _wall('dec_bld_courtyard')
    h = 3 * STOREY + 0.6
    back = (13.6, 4.2, 0.0, 3.6)  # w, d, x, y of each wing
    wings = [back, (4.2, 7.4, -4.7, -2.2), (4.2, 7.4, 4.7, -2.2)]
    for w, d, x, y in wings:
        block(w, d, h, wall, x=x, y=y)
    windows('front', 13.6, 4.2, [-1.2, 1.2], [0, 1, 2], y0=3.6)
    door(0, 4.2, y0=3.6)
    for x in (-4.7, 4.7):
        windows('front', 4.2, 7.4, [-0.9, 0.9], [0, 1, 2], x0=x, y0=-2.2)
    for side, x in (('left', -4.7), ('right', 4.7)):
        windows(side, 4.2, 7.4, [-2.6, 0, 2.6], [0, 1, 2], x0=x, y0=-2.2)
        windows('right' if side == 'left' else 'left', 4.2, 7.4, [-2.0, 1.0], [0, 1, 2], x0=x, y0=-2.2)
    for x in (-1.5, 1.5):
        prop('planter_box_01', x, -1.0, 0, turn=math.pi / 2)


def garage():
    """Alley garage: corrugated metal shed with a wide rusty door on its front (3 × 2 tiles; the map turns it to the alley)."""
    w, d, h = 6.2, 4.4, 2.8
    block(w, d, h, _wall('dec_garage', metres=1.0), cornice=False)
    box((2.8, 0.06, 2.2), (-0.9, -d / 2 - 0.03, 0), material('rusty_corrugated_iron', metres=1.0, roughness=0.7, metallic=0.4))
    box((0.9, 0.06, 2.0), (1.9, -d / 2 - 0.03, 0), material(None, tint=(0.25, 0.22, 0.2)))


def _steel():
    return material(None, tint=(0.18, 0.19, 0.2), roughness=0.5, metallic=0.7)


def streetlight():
    """Chicago 'cobra head' street light on a steel pole, arm reaching over the street (towards -Y)."""
    box((0.16, 0.16, 6.5), (0, 0.6, 0), _steel())
    box((0.1, 1.6, 0.1), (0, -0.2, 6.3), _steel())
    box((0.35, 0.6, 0.15), (0, -1.0, 6.2), material(None, tint=(0.95, 0.85, 0.6), roughness=0.4))


def hydrant():
    """Fire hydrant on the sidewalk edge."""
    red = material(None, tint=(0.62, 0.08, 0.06), roughness=0.6)
    box((0.32, 0.32, 0.7), (0, 0, 0), red)
    box((0.42, 0.42, 0.08), (0, 0, 0.7), red)
    box((0.5, 0.14, 0.14), (0, 0, 0.45), red)


def garden_beds():
    """Community garden: rows of raised planters, compost and a water barrel (3 × 3 tiles)."""
    for row, y in enumerate((-2.0, 0.0, 2.0)):
        for x in (-1.6, 1.6):
            prop('planter_box_02' if (row + round(x)) % 2 else 'planter_box_01', x, y, 0, turn=math.pi / 2 * row)
    prop('compost_bags', -2.2, 2.4, 0, scale=0.8)
    prop('Barrel_02', 2.4, 2.4, 0)


def alley_bins():
    """Trash cans and a crate in the alley."""
    prop('metal_trash_can', -0.4, 0.2, 0, turn=0.3)
    prop('metal_trash_can', 0.35, 0.3, 0, turn=1.7)
    prop('plastic_crate_02', 0.1, -0.5, 0, turn=0.6)


# art id: (recipe, footprint tiles w × h, as modelled = facing south)
RECIPES = {
    'dec_bld_two_flat': (two_flat, (3, 4)), 'dec_bld_three_flat': (three_flat, (3, 4)),
    'dec_bld_bungalow': (bungalow, (3, 3)), 'dec_bld_cottage': (cottage, (3, 3)),
    'dec_bld_courtyard': (courtyard, (6, 5)), 'dec_garage': (garage, (3, 2)),
    'dec_streetlight': (streetlight, (1, 1)), 'dec_hydrant': (hydrant, (1, 1)),
    'dec_garden_beds': (garden_beds, (3, 3)), 'dec_alley_bins': (alley_bins, (1, 1)),
}

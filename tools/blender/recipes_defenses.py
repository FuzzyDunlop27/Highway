# Purpose: Chunk 2M recipes for walls, towers, traps and map decorations (simple textured shapes + Poly Haven props). Notes: docs/features/models-3d.md
# One tile ≈ 2.44 m. Walls run along X (the game turns north–south walls itself).
import math

from model_kit import box, coil, material, prop, sandbag_row, stake

TILE = 2.44


def _wood():
    return material('brown_planks_05', metres=1.2)


def _rust():
    return material('rusty_metal_02', metres=1.0, roughness=0.8, metallic=0.4)


def wall_wood():
    """Plank barricade between two posts, with a diagonal brace."""
    wood = _wood()
    for x in (-1.08, 1.08):
        box((0.14, 0.14, 1.95), (x, 0, 0), wood)
    for i, z in enumerate((0.15, 0.48, 0.81, 1.14, 1.47)):
        box((TILE - 0.02, 0.05, 0.28), (0, -0.09, z), wood, tilt=(0, math.radians((-1.5, 1, -0.5, 2, -1)[i])))
    box((0.12, 0.05, 2.5), (0, 0.06, 0.15), wood, tilt=(0, math.radians(55)))


def wall_metal():
    """Rusty corrugated sheets bolted to steel posts: taller and stronger-looking than the wood wall."""
    sheet = material('rusty_corrugated_iron', metres=1.0, roughness=0.7, metallic=0.5)
    for x in (-1.1, 0, 1.1):
        box((0.1, 0.1, 2.3), (x, 0.06, 0), _rust())
    for x, lean in ((-0.6, -1.0), (0.6, 1.2)):
        box((1.25, 0.04, 2.15), (x, -0.03, 0.05), sheet, tilt=(0, math.radians(lean)))


def watchtower():
    """Wooden tower: four legs with braces, a sandbagged platform at 4.2 m and a tin roof."""
    wood, tin = _wood(), material('corrugated_iron_02', metres=1.0, roughness=0.6, metallic=0.5)
    leg, top = 0.9, 4.2
    for sx in (-1, 1):
        for sy in (-1, 1):
            box((0.16, 0.16, top), (sx * leg, sy * leg, 0), wood)
            box((0.08, 0.08, 2.0), (sx * leg * 0.92, sy * leg * 0.92, top), wood)
    for sy in (-1, 1):
        box((0.08, 0.06, 2.5), (0, sy * leg, 0.6), wood, tilt=(0, math.radians(52)))
        box((2.5, 0.06, 0.08), (0, sy * leg, 2.2), wood)
    box((2.3, 2.3, 0.14), (0, 0, top), wood)
    for z in (top + 0.14, top + 0.32):
        sandbag_row(-1.0, 1.0, -1.05, z)
        sandbag_row(-1.0, 1.0, 1.05, z)
        sandbag_row(-0.7, 0.7, -1.05, z, turn_row=math.pi / 2)
        sandbag_row(-0.7, 0.7, 1.05, z, turn_row=math.pi / 2)
    box((2.6, 2.6, 0.05), (0, 0, top + 2.0), tin, tilt=(math.radians(6), 0))
    for z in (0.5, 1.1, 1.7, 2.3, 2.9, 3.5, 4.1):  # ladder rungs up the front
        box((0.5, 0.04, 0.04), (0, -leg - 0.1, z), wood)
    for x in (-0.25, 0.25):
        box((0.05, 0.05, top + 0.2), (x, -leg - 0.1, 0), wood)


def mg_nest():
    """Machine-gun nest: a three-high sandbag ring open at the back, ammo inside."""
    for layer in range(3):
        z = layer * 0.18
        sandbag_row(-1.0, 1.0, -1.0, z)
        sandbag_row(-0.8, 0.5, -1.0, z, turn_row=math.pi / 2)
        sandbag_row(-0.8, 0.5, 1.0, z, turn_row=math.pi / 2)
    prop('ammo_box', 0.3, 0.2, 0, scale=2.2, turn=0.4)
    prop('ammo_box', -0.4, 0.4, 0, scale=2.2, turn=-0.2)


def spikes():
    """Rows of sharpened stakes crossed in X shapes."""
    bark = material('bark_brown_02', metres=0.6)
    for row, y in enumerate((-0.6, 0.4)):
        for i, x in enumerate((-0.8, 0.0, 0.8)):
            for lean in (-35, 35):
                stake((x + row * 0.2, y, 0), 1.1, 0.05, bark, tilt=(math.radians(lean), math.radians(10 * (i - 1))))


def barbwire():
    """Barbed-wire coil strung along three steel posts."""
    rust = _rust()
    for x in (-1.0, 0.0, 1.0):
        box((0.05, 0.05, 0.95), (x, 0, 0), rust, tilt=(math.radians(4 * x), 0))
    coil(-TILE / 2, TILE / 2, 0, 0.38, 0.34, 14, 0.012, rust)
    coil(-TILE / 2, TILE / 2, 0.05, 0.30, 0.24, 11, 0.01, rust)


def car_wreck():
    """Abandoned car under a dusty cover, lying along the 2-tile side."""
    prop('covered_car', 0, 0, 0, turn=math.pi / 2 + 0.06)


def tree_dead():
    """Dead tree trunk with dry branches piled at its foot."""
    prop('dead_quiver_trunk', 0, 0, 0, scale=2.2, turn=0.5)
    prop('dry_branches_medium_01', 0.3, 0.2, 0, scale=0.9, turn=1.2)


# art id: (recipe, footprint tiles w × h)
RECIPES = {
    'def_wall_wood': (wall_wood, (1, 1)), 'def_wall_metal': (wall_metal, (1, 1)),
    'def_watchtower_base': (watchtower, (1, 1)), 'def_mg_nest_base': (mg_nest, (1, 1)),
    'def_spikes': (spikes, (1, 1)), 'def_barbwire': (barbwire, (1, 1)),
    'dec_car_wreck': (car_wreck, (2, 1)), 'dec_tree_dead': (tree_dead, (1, 1)),
}

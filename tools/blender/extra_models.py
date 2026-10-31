# Purpose: Stand-in 3D models for phase 1 buildings the Blender study doesn't have yet, built with its own helpers. Spec: docs/graphics-spec-iso.md
"""Simple models in the study's miniature style (same palette and bevel helpers), so the isometric view has art for
every 1A building. Replace any of them with the art team's models when those exist. Sizes are in study units
(about 1.55 per map tile); render_iso_sprites.py scales them to their footprint."""
import math
from geometry import box, cyl, beam, roof
from buildings import sandbag, crate, barrel
from props import car, rubble


def scaffold(tiles):
    """Wooden scaffolding with a tarp, shown while any `tiles`x`tiles` building is under construction."""
    half = tiles * 0.72
    height = 1.1 + 0.45 * tiles
    box('scaffold ground boards', (0, 0, .05), (half * 2, half * 2, .1), 'wood_dark', .03)
    for x in (-half, half):
        for y in (-half, half):
            box('scaffold post', (x * .92, y * .92, height / 2), (.12, .12, height), 'wood', .02)
    for z in (height * .45, height * .95):
        for y in (-half, half):
            box('scaffold rail', (0, y * .92, z), (half * 1.9, .09, .09), 'wood_light', .015)
        for x in (-half, half):
            box('scaffold rail', (x * .92, 0, z), (.09, half * 1.9, .09), 'wood_light', .015)
    beam('scaffold brace', (-half * .9, -half * .92, .15), (half * .9, -half * .92, height * .9), .08, 'wood_dark')
    box('half-built wall', (0, half * .3, .45), (half * 1.4, half * .9, .8), 'cream', .05)
    box('blue tarp', (-.1, half * .25, height * .98), (half * 1.5, half * 1.1, .06), 'teal_light', .05, (.08, -.06, 0))
    crate(half * .55, -half * .55, scale=.8)
    for i in range(3):
        box('lumber pile', (-half * .55, -half * .62, .07 + i * .09), (1.0, .14, .08), 'wood_light', .01, (0, 0, .1 * i))


def rubble_2x2():
    """Collapsed building remains."""
    box('cracked slab', (0, 0, .06), (2.8, 2.7, .12), 'stone', .08)
    box('broken wall stub', (-.8, .7, .45), (1.2, .25, .8), 'cream', .06, (0, 0, .1))
    box('fallen wall piece', (.5, .4, .25), (1.1, .22, .5), 'cream', .05, (0, 1.1, .4))
    box('snapped beam', (.2, -.4, .3), (1.6, .14, .14), 'wood_dark', .02, (0, .3, .7))
    for x, y in ((-.6, -.6), (.6, -.3), (0, .9), (.8, .8)):
        rubble(x, y)


def rubble_1x1():
    for x, y in ((-.15, -.1), (.2, .15)):
        rubble(x, y)


def scavenger():
    """Garage with a pickup and scrap piles."""
    box('concrete pad', (0, 0, .07), (2.9, 2.8, .14), 'stone', .08)
    box('garage back wall', (0, .95, .85), (2.6, .3, 1.55), 'plaster', .06)
    for x in (-1.2, 1.2):
        box('garage side wall', (x, .35, .85), (.22, 1.4, 1.55), 'plaster', .05)
    box('sloped tin roof', (0, .4, 1.72), (2.85, 1.75, .1), 'rust', .03, (.12, 0, 0))
    for x in (-.8, -.25, .3, .85):
        box('roof rib', (x, .4, 1.79), (.05, 1.75, .04), 'iron', .01, (.12, 0, 0))
    old_scale = .62
    import bpy
    before = set(bpy.data.objects)
    car()
    for o in set(bpy.data.objects) - before:
        o.location = (o.location.x * old_scale - .1, o.location.y * old_scale - .55, o.location.z * old_scale + .14)
        o.scale = (old_scale,) * 3
    rubble(.9, -.9)
    rubble(-.95, -1.0)
    barrel(1.0, .1)
    crate(-.95, .1, .14, .8)


def workshop():
    """Open-front shed with a workbench and a welding glow."""
    box('workshop slab', (0, 0, .07), (2.8, 2.7, .14), 'stone', .08)
    for x in (-1.15, 1.15):
        for y in (-.9, .95):
            box('shed post', (x, y, .9), (.15, .15, 1.6), 'wood', .02)
    box('back plank wall', (0, 1.0, .85), (2.4, .12, 1.5), 'wood_dark', .03)
    roof('shed roof', 2.75, 2.4, 1.7, .55, 'teal')
    box('workbench top', (0, .55, .62), (1.7, .55, .08), 'wood_light', .02)
    for x in (-.75, .75):
        box('bench leg', (x, .55, .3), (.08, .5, .58), 'wood_dark', .01)
    box('vise', (.5, .45, .72), (.18, .14, .14), 'iron', .02)
    box('welding glow', (-.4, .5, .74), (.14, .14, .1), 'glow', .02)
    cyl('gas bottle', (1.0, .6, .45), .13, .75, 'coral', 12)
    crate(-.95, -.7, .14, .7)
    barrel(.9, -.75)


def barracks():
    """Canvas tent inside a sandbag ring, with a weapon rack."""
    box('trampled ground', (0, 0, .03), (2.9, 2.8, .06), 'dirt', .05)
    roof('canvas tent', 1.9, 1.7, .08, 1.25, 'paper')
    box('tent door flap', (0, -.86, .5), (.5, .03, .8), 'soil', .01)
    for i in range(10):
        a = i / 10 * 2 * math.pi
        if 4.4 < a < 5.1:
            continue  # gap for the entrance
        sandbag(1.25 * math.cos(a), 1.2 * math.sin(a), .13, a + math.pi / 2)
    beam('rack rail', (.9, -.9, .7), (.9, -.2, .7), .07, 'wood')
    for y in (-.85, -.25):
        box('rack post', (.9, y, .38), (.08, .08, .75), 'wood_dark', .01)
    for y in (-.7, -.55, -.4):
        beam('rifle', (.85, y, .15), (.95, y, .8), .04, 'iron')


def storage():
    """Two stacked shipping containers."""
    box('gravel pad', (0, 0, .05), (2.9, 2.7, .1), 'stone', .06)
    box('lower container', (0, 0, .62), (2.6, 1.15, 1.05), 'teal', .05)
    box('upper container', (.15, .05, 1.68), (2.4, 1.1, 1.0), 'rust', .05, (0, 0, .05))
    for z, w in ((.62, 2.6), (1.68, 2.4)):
        for x in (-.9, -.45, 0, .45, .9):
            box('corrugation', (x * w / 2.6, -.59, z), (.06, .03, .9), 'iron', .005)
    box('container doors', (1.31, 0, .62), (.03, 1.0, .9), 'steel', .01)
    crate(-1.0, -1.0, .1, .7)
    barrel(1.05, -1.0)


def ground_tile(material, detail=None):
    """One map tile of ground (1.55 units square, slightly oversized so neighbors overlap and no seams show)."""
    import random
    size = 1.55 * 1.03
    box('ground', (0, 0, -.05), (size, size, .1), material, 0)
    rng = random.Random(7)
    if detail == 'grass':
        from props import grass
        for _ in range(5):
            grass(rng.uniform(-.6, .6), rng.uniform(-.6, .6), 0, rng.uniform(.5, .8))
    elif detail == 'pebbles':
        for _ in range(6):
            box('pebble', (rng.uniform(-.6, .6), rng.uniform(-.6, .6), .015), (.07, .06, .03), 'soil', .01)
    elif detail == 'lane':
        for x in (-.45, .45):
            box('faded lane dash', (x, 0, .003), (.5, .07, .01), 'roadpaint', 0)
    elif detail == 'cracks':
        box('expansion joint', (0, 0, .002), (size, .025, .006), 'iron', 0)
        box('crack', (.25, .3, .002), (.4, .015, .006), 'iron', 0, (0, 0, .5))

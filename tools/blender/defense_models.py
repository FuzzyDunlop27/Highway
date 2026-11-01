# Purpose: 3D models for the milestone 1B defenses (metal wall, MG nest, spikes, barbed wire) in the study's style.
"""Built with the Blender study's helpers and palette. Sizes are in study units (about 1.55 per map tile);
the 2M exporter scales them to their 1x1 footprint. Walls run along X like props.wall(), so wood and metal
walls line up. The MG gun is its own model whose origin is the pivot, so it turns in place on top of the nest."""
import math
import bpy
from mathutils import Vector
from geometry import box, cyl, beam, rod, curve, finish

MG_PIVOT_Z = .62  # height of the tripod head in the nest base = where the gun layer sits (model units)


def cone(name, a, b, r, mat, vertices=6):
    """A pointed tip from a (base) to b (point)."""
    a, b = Vector(a), Vector(b)
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r, radius2=0, depth=(b - a).length, location=(a + b) / 2)
    o = bpy.context.object
    o.rotation_euler = (b - a).to_track_quat('Z', 'Y').to_euler()
    return finish(o, name, mat, .008)


def bag(x, y, z, angle):
    """Same look as buildings.sandbag(), but the stitching turns with the bag (outer face)."""
    box('stitched canvas sandbag', (x, y, z), (.58, .31, .25), 'soil', .09, (0, 0, angle))
    out = Vector((math.sin(angle), -math.cos(angle), 0)) * .15
    along = Vector((math.cos(angle), math.sin(angle), 0)) * .18
    c = Vector((x, y, z + .05)) + out
    beam('bag stitching', c - along, c + along, .018, 'wood_light')


def wall_metal():
    """Corrugated sheet-metal barricade on steel posts, strapped with rusty rebar. Same size as props.wall()."""
    for x in (-.67, .67):
        box('steel post', (x, .02, .58), (.17, .22, 1.16), 'iron', .03)
        box('post cap', (x, .02, 1.18), (.21, .26, .07), 'steel', .02)
        box('post foot', (x, .02, .05), (.27, .3, .1), 'stone', .02)
    sheets = (('teal', -.825, .06, .12, 1.06, .02), ('steel', -.12, .825, .1, 1.1, -.015), ('rust', -.36, .2, .5, 1.0, .03))
    for mat, x0, x1, z0, z1, tilt in sheets:
        y = -.03 if mat != 'rust' else -.085
        box('corrugated sheet', ((x0 + x1) / 2, y, (z0 + z1) / 2), (x1 - x0, .06, z1 - z0), mat, .015, (0, tilt, 0))
        ribs = int((x1 - x0) / .09)
        for i in range(ribs):
            rx = x0 + (i + .5) * (x1 - x0) / ribs
            dz = (rx - (x0 + x1) / 2) * math.sin(tilt)
            rod('corrugation ridge', (rx, y - .025, z0 + .02 - dz), (rx, y - .025, z1 - .02 - dz), .022, mat)
    for x in (-.5, .3, .62):
        cyl('rivet', (x, -.11, .95), .03, .03, 'iron', 8, (math.pi / 2, 0, 0), 0)
    for z in (.32, .86):
        rod('rebar rail', (-.8, -.13, z), (.8, -.13, z), .03, 'rust')
        for x in (-.67, .67):
            box('wire tie', (x, -.15, z), (.2, .03, .07), 'steel', .01)
    rod('rebar brace', (-.6, -.16, .32), (.6, -.16, .86), .03, 'rust')
    for x, lean in ((-.45, -.1), (-.05, .06), (.4, .1)):
        rod('rebar spike', (x, -.06, .95), (x + lean, -.06, 1.32), .024, 'rust')


def mg_nest_base():
    """Two rings of sandbags with an opening at the front-left, and the gun's tripod in the middle."""
    cyl('trampled dirt floor', (0, 0, .02), .74, .04, 'dirt', 24, bevel=.02)
    for layer, (z, offset) in enumerate(((.13, 0), (.37, 18))):
        for k in range(10):
            a = offset + 36 * k
            if 240 < a < 300:
                continue  # entrance on the -Y side (screen lower-left)
            r = math.radians(a)
            bag(.6 * math.cos(r), .6 * math.sin(r), z, r + math.pi / 2 + layer * .05)
    head = (0, 0, MG_PIVOT_Z - .06)
    for a in (40, 160, 280):
        r = math.radians(a)
        beam('tripod leg', head, (.34 * math.cos(r), .34 * math.sin(r), .04), .05, 'iron')
        box('tripod foot', (.34 * math.cos(r), .34 * math.sin(r), .04), (.1, .1, .04), 'steel', .01)
    cyl('pivot head', (0, 0, MG_PIVOT_Z - .04), .07, .08, 'steel', 12)
    box('ammo crate', (-.28, .3, .12), (.3, .2, .2), 'teal', .025, (0, 0, .4))
    box('ammo crate lid', (-.28, .3, .23), (.31, .21, .03), 'teal_dark', .01, (0, 0, .4))
    for i, (x, y) in enumerate(((.2, -.25), (.26, -.2), (.15, -.32), (.3, -.3))):
        cyl('spent casing', (x, y, .06), .018, .07, 'yellow', 6, (math.pi / 2, 0, i), 0)


def mg_gun():
    """Mounted machine gun with a small shield, barrel along +X. Origin = the pivot on top of the tripod."""
    box('swivel yoke', (0, 0, .04), (.14, .18, .08), 'iron', .02)
    box('receiver', (-.02, 0, .16), (.42, .15, .16), 'iron', .025)
    box('feed cover', (-.04, 0, .26), (.3, .13, .05), 'steel', .015)
    rod('cooling jacket', (.18, 0, .18), (.6, 0, .18), .05, 'teal_dark', 10)
    for x in (.28, .4, .52):
        cyl('jacket ring', (x, 0, .18), .056, .025, 'iron', 10, (0, math.pi / 2, 0), 0)
    rod('barrel', (.6, 0, .18), (.8, 0, .18), .024, 'black')
    cyl('muzzle', (.81, 0, .18), .034, .05, 'steel', 8, (0, math.pi / 2, 0), .005)
    box('gun shield', (.16, 0, .2), (.045, .44, .32), 'teal', .03, (0, -.12, 0))
    box('shield rim', (.17, 0, .37), (.06, .46, .05), 'coral', .015, (0, -.12, 0))
    for y in (-.07, .07):
        box('spade grip', (-.27, y, .15), (.06, .04, .12), 'wood', .015)
    box('ammo box', (-.02, .15, .12), (.17, .1, .14), 'coral', .02)
    for i in range(4):
        box('brass belt round', (-.08 + i * .04, .095, .2), (.025, .03, .06), 'yellow', .005)


def spikes():
    """Low floor trap: a plank base with outward-leaning sharpened stakes and a nail board in the middle."""
    for x in (-.55, .55):
        box('cross batten', (x, 0, .05), (.14, 1.4, .1), 'wood_dark', .02)
    for y, mat in ((-.47, 'wood'), (0, 'wood_light'), (.47, 'wood')):
        box('base plank', (0, y, .14), (1.45, .42, .08), mat, .02)
    for x in (-.55, .55):
        for y in (-.47, .47):
            cyl('plank nail', (x, y, .185), .025, .02, 'iron', 6, bevel=0)
    for side in (-1, 1):
        for i, x in enumerate((-.52, -.17, .17, .52)):
            y = side * (.47 + (.04 if i % 2 else -.04))
            foot = (x, y, .16)
            tip_base = (x + (.03 if i % 2 else -.03), y + side * .14, .4)
            rod('stake shaft', foot, tip_base, .045, 'wood', 6)
            tip = (tip_base[0] + .01, tip_base[1] + side * .07, tip_base[2] + .15)
            cone('carved stake point', tip_base, tip, .045, 'paper')
    box('nail board', (0, 0, .2), (1.0, .3, .05), 'wood_dark', .015)
    for x in (-.4, -.2, 0, .2, .4):
        for y in (-.08, .08):
            rod('upturned nail', (x, y + (.02 if x > 0 else 0), .22), (x, y, .36), .016, 'steel', 6)


def barbwire():
    """Two low coils of barbed wire strung along X, tied to a row of short wooden posts between them."""
    for x in (-.62, 0, .62):
        box('wire post', (x, 0, .27), (.09, .09, .54), 'wood_dark', .015)
        box('post foot', (x, 0, .03), (.18, .18, .06), 'stone', .015)
        box('wire tie', (x, 0, .48), (.11, .11, .04), 'steel', .005)
    rod('top strand', (-.74, 0, .5), (.74, 0, .5), .011, 'iron', 4)
    for yc, phase in ((-.33, 0), (.33, 1.6)):
        coil(yc, phase)


def coil(yc, phase, turns=5, x0=-.72, x1=.72, r=.2, zc=.22):
    pts, n = [], int(turns * 14)
    for i in range(n + 1):
        t = i / n
        a = t * turns * 2 * math.pi + phase
        pts.append((x0 + t * (x1 - x0), yc + r * math.sin(a), zc + r * math.cos(a)))
    wire = curve('barbed wire coil', pts, 'steel', .015)
    bpy.ops.object.select_all(action='DESELECT')
    bpy.context.view_layer.objects.active = wire
    wire.select_set(True)
    bpy.ops.object.convert(target='MESH')  # the iso renderer measures mesh objects only
    for i in range(0, n, 3):
        p = Vector(pts[i])
        rod('barb', p + Vector((-.045, .035, .03)), p + Vector((.045, -.035, -.03)), .01, 'iron', 4)
        rod('barb', p + Vector((-.045, -.035, -.03)), p + Vector((.045, .035, .03)), .01, 'iron', 4)
    for x in (-.62, 0, .62):
        rod('tie wire', (x, 0, .3), (x, yc * .7, zc + r * .6), .01, 'iron', 4)

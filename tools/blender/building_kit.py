# Purpose: Textured-box parts for the Chicago neighborhood houses: walls, windows, bay windows, stoops, roofs. Notes: docs/features/models-3d.md
# Real metres, Blender Z-up, front towards -Y (south), origin at the footprint's ground middle (same rules as model_kit).
# Walls take a photo texture by name (recipes_neighborhood.FACADES), so a house's look can be swapped with one line.
import math

import bpy

import model_kit
from model_kit import box, material

STOREY = 3.0  # metres per floor
WINDOW = (1.0, 1.5)  # width, height
SILL = 0.9  # window bottom above each floor


def facade(texture, metres=1.6):
    """Wall material from a Poly Haven texture name (one repeat covers `metres`)."""
    return material(texture, metres=metres, roughness=0.95)


def glass():
    return material(None, tint=(0.04, 0.05, 0.06), roughness=0.25, metallic=0.2)


def stone():
    """Pale limestone for cornices, sills and steps."""
    return material(None, tint=(0.6, 0.58, 0.53), roughness=0.9)


def roofing():
    return material(None, tint=(0.09, 0.09, 0.09), roughness=1.0)


def door_wood():
    return material(None, tint=(0.17, 0.09, 0.05), roughness=0.8)


def block(w, d, h, wall, x=0.0, y=0.0, cornice=True):
    """A solid building block w × d × h with a stone cornice and a dark flat roof."""
    box((w, d, h), (x, y, 0), wall)
    if cornice:
        box((w + 0.25, d + 0.25, 0.3), (x, y, h), stone())
        box((w - 0.2, d - 0.2, 0.04), (x, y, h + 0.3), roofing())
    else:
        box((w - 0.1, d - 0.1, 0.04), (x, y, h), roofing())


def _pane(side, w, d, x0, y0, along, z, size):
    """One window (dark glass + stone sill) on the `side` face of a w × d block centred at (x0, y0)."""
    sx, sz = size
    if side in ('front', 'back'):
        y = y0 + (-d / 2 - 0.02 if side == 'front' else d / 2 + 0.02)
        box((sx, 0.06, sz), (x0 + along, y, z), glass())
        box((sx + 0.2, 0.16, 0.1), (x0 + along, y, z - 0.1), stone())
    else:
        x = x0 + (-w / 2 - 0.02 if side == 'left' else w / 2 + 0.02)
        box((0.06, sx, sz), (x, y0 + along, z), glass())
        box((0.16, sx + 0.2, 0.1), (x, y0 + along, z - 0.1), stone())


def windows(side, w, d, positions, floors, x0=0.0, y0=0.0, size=WINDOW):
    """Windows on one face: `positions` along the face (metres from its middle), on each floor index in `floors`."""
    for f in floors:
        for along in positions:
            _pane(side, w, d, x0, y0, along, f * STOREY + SILL, size)


def door(x, d, y0=0.0, z=0.0, width=1.0, height=2.2):
    """A front door on the -Y face, `z` = its threshold height."""
    box((width, 0.08, height), (x, y0 - d / 2 - 0.03, z), door_wood())
    box((width + 0.3, 0.1, 0.25), (x, y0 - d / 2 - 0.04, z + height), stone())


def stoop(x, d, height, y0=0.0, width=1.4):
    """Front steps up to a raised door: one stone box per step, stepping down towards -Y."""
    steps = max(1, round(height / 0.2))
    for i in range(steps):
        top = height - i * height / steps
        box((width, 0.3, top), (x, y0 - d / 2 - 0.15 - i * 0.3, 0), stone())


def bay(x, d, width, floors, wall, y0=0.0, depth=0.8):
    """Chicago bay window: a box standing out from the -Y face, windows on its front and both sides."""
    h = floors * STOREY
    y = y0 - d / 2 - depth / 2
    box((width, depth, h), (x, y, 0), wall)
    box((width + 0.15, depth + 0.15, 0.2), (x, y, h), stone())
    for f in range(floors):
        z = f * STOREY + SILL
        _pane('front', width, depth, x, y, 0, z, (width - 0.8, WINDOW[1]))
        _pane('left', width, depth, x, y, 0, z, (depth * 0.6, WINDOW[1]))
        _pane('right', width, depth, x, y, 0, z, (depth * 0.6, WINDOW[1]))


def hip_roof(w, d, z, height, mat=None):
    """A four-sided pitched roof over a w × d block whose walls end at `z`."""
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=math.sqrt(2) / 2, radius2=0, depth=1,
                                    location=(0, 0, 0.5), rotation=(0, 0, math.pi / 4))
    obj = bpy.context.active_object
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=False)
    obj.scale = (w + 0.6, d + 0.6, height)
    obj.location = (0, 0, z)
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=True)
    mat = mat or material(None, tint=(0.16, 0.14, 0.13), roughness=1.0)
    return model_kit._finish_shape(obj, mat, mat['metres'])

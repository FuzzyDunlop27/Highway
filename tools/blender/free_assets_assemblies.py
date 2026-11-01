# Purpose: Free-asset spike: builds small buildings from Quaternius Downtown City MegaKit modular pieces. Notes: docs/research/free-assets.md
# Kit grid: wall pieces are 2 m wide, 3 m tall, face along X with the outside towards -Y. Used by free_assets_spike_export.py.
import math
import os

import bpy

KIT = 'quaternius/Exports/glTF (Godot)'
HALF = 3.0  # 6 x 6 m footprint = 3 pieces per side (about 2.5 tiles at the spike's 0.41 tiles per metre)
SLOTS = (-2.0, 0.0, 2.0)  # piece centres along a side

# Sides: (outside direction, rotation about Z). Rotating +90° turns the -Y outside to +X.
SIDES = {'front': ((0, -1), 0.0), 'back': ((0, 1), math.pi), 'left': ((-1, 0), -math.pi / 2), 'right': ((1, 0), math.pi / 2)}


def _template(src, name, import_any, cache):
    """Imports a kit piece once and joins it into one mesh object; later uses share its mesh data."""
    if name in cache:
        return cache[name]
    before = set(bpy.data.objects)
    import_any(os.path.join(src, KIT, name + '.gltf'))
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == 'MESH']
    for o in meshes:
        world = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = world
    for o in new:
        if o.type != 'MESH':
            bpy.data.objects.remove(o)
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    piece = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    piece.name = 'tpl_' + name
    piece.hide_render = piece.hide_viewport = True
    cache[name] = piece
    return piece


def _place(tpl, x, y, z, turn):
    copy = tpl.copy()
    copy.hide_render = copy.hide_viewport = False
    bpy.context.scene.collection.objects.link(copy)
    copy.location = (x, y, z)
    copy.rotation_mode = 'XYZ'  # the glTF importer leaves objects in quaternion mode, which ignores rotation_euler
    copy.rotation_euler = (0, 0, turn)


def _side(src, import_any, cache, side, z, pieces):
    (ox, oy), turn = SIDES[side]
    for slot, name in zip(SLOTS, pieces):
        # Along-side axis is perpendicular to the outside direction; keep left-to-right as seen from outside.
        ax, ay = math.cos(turn), math.sin(turn)
        _place(_template(src, name, import_any, cache), ox * HALF + ax * slot, oy * HALF + ay * slot, z, turn)


def build_shop(src, import_any):
    """Two-storey corner shop: metal-and-glass shopfront below, brick with windows above, brick cornice, flat roof."""
    cache = {}
    ground = {'front': ['Metal_FirstFloor_Window', 'DoorFrame_Metal_Single', 'Metal_FirstFloor_Window'],
              'left': ['Metal_FirstFloor_Wall', 'Metal_FirstFloor_Window', 'Metal_FirstFloor_Wall'],
              'right': ['Metal_FirstFloor_Wall'] * 3, 'back': ['Metal_FirstFloor_Wall'] * 3}
    upper = {'front': ['Brick_Window_Trim_Single'] * 3,
             'left': ['Brick_Plain_3', 'Brick_Window_Square_Single', 'Brick_Plain_3'],
             'right': ['Brick_Plain_3', 'Brick_Window_Square_Single', 'Brick_Plain_3'], 'back': ['Brick_Plain_3'] * 3}
    for side in SIDES:
        _side(src, import_any, cache, side, 0.0, ground[side])
        _side(src, import_any, cache, side, 3.0, upper[side])
        _side(src, import_any, cache, side, 6.0, ['Cornice_Brick_Center'] * 3)
    roof = _template(src, 'Roof_2x2', import_any, cache)
    for x in SLOTS:
        for y in SLOTS:
            _place(roof, x, y, 6.6, 0)
    _place(_template(src, 'Prop_ACUnit', import_any, cache), 1.2, 1.0, 6.4, 0)
    for tpl in cache.values():
        bpy.data.objects.remove(tpl)  # copies keep the shared mesh data


ASSEMBLIES = {'fa_qt_shop': build_shop}

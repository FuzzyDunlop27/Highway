# Purpose: Chunk 2M building blocks for model recipes: Quaternius kit pieces, Poly Haven props, simple textured shapes. Notes: docs/features/models-3d.md
# Everything is built in real metres, Blender Z-up, front (the side facing the camera at the start) towards -Y = south
# in the game, origin at the footprint's ground centre. export_usdz.py scales metres to tiles when it exports.
import math
import os

import bmesh
import bpy

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, 'HighwayHoldout_3D_Sources', 'free-assets')
KIT = os.path.join(SRC, 'quaternius', 'Exports', 'glTF (Godot)')
POLYHAVEN = os.path.join(SRC, 'polyhaven')
TEXTURES = os.path.join(POLYHAVEN, 'textures')
PROP_MAX_TRIS = 1500  # props are small on screen; heavier Poly Haven scans are decimated down to about this

# Wall sides: outside direction and turn about Z (a kit piece's outside faces -Y at turn 0).
SIDES = {'front': ((0, -1), 0.0), 'back': ((0, 1), math.pi), 'left': ((-1, 0), -math.pi / 2), 'right': ((1, 0), math.pi / 2)}

# Kit wall pieces wider than the usual 2 m (measured; centred on their origin like the rest).
WIDE_PIECES = {'Brick_Window_CurvedDouble': 4.0, 'Brick_Inset_Window': 4.0, 'Brick_RedWhite_DoubleWindow': 4.0, 'Brick_Inset': 4.0}

_templates = {}
_materials = {}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _templates.clear()
    _materials.clear()


def _import_joined(key, path, max_tris=None, ground_centre=False):
    """Imports a glTF once, joins its meshes into one hidden template object (shared mesh data for every copy)."""
    if key in _templates:
        return _templates[key]
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
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
    obj = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    if max_tris and tris > max_tris:
        mod = obj.modifiers.new('decimate', 'DECIMATE')
        mod.ratio = max_tris / tris
        bpy.ops.object.modifier_apply(modifier=mod.name)
    if ground_centre:  # props: origin at the middle of their footprint, on the ground
        xs, ys, zs = zip(*(v.co for v in obj.data.vertices))
        shift = ((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, min(zs))
        for v in obj.data.vertices:
            v.co.x -= shift[0]
            v.co.y -= shift[1]
            v.co.z -= shift[2]
    obj.name = 'tpl_' + key
    obj.hide_render = obj.hide_viewport = True
    _templates[key] = obj
    return obj


def place(template, x=0.0, y=0.0, z=0.0, turn=0.0, scale=1.0, tilt=(0.0, 0.0)):
    obj = template.copy()
    obj.name = template.name[len('tpl_'):]  # export_usdz removes every 'tpl_' object before exporting
    obj.hide_render = obj.hide_viewport = False
    bpy.context.scene.collection.objects.link(obj)
    obj.location = (x, y, z)
    obj.rotation_mode = 'XYZ'  # the glTF importer leaves quaternion mode, which ignores rotation_euler
    obj.rotation_euler = (tilt[0], tilt[1], turn)
    obj.scale = (scale,) * 3 if isinstance(scale, (int, float)) else scale
    return obj


def piece(name, x=0.0, y=0.0, z=0.0, turn=0.0, scale=1.0, tilt=(0.0, 0.0)):
    """One Quaternius Downtown City MegaKit piece (wall pieces: 2 m wide, 3 m tall, outside towards -Y)."""
    return place(_import_joined('kit_' + name, os.path.join(KIT, name + '.gltf')), x, y, z, turn, scale, tilt)


def prop(name, x=0.0, y=0.0, z=0.0, turn=0.0, scale=1.0, tilt=(0.0, 0.0)):
    """One Poly Haven model (real metres), decimated to about PROP_MAX_TRIS, origin at its footprint's ground middle."""
    folder = os.path.join(POLYHAVEN, name)
    path = next(os.path.join(folder, f) for f in os.listdir(folder) if f.endswith('.gltf'))
    return place(_import_joined('ph_' + name, path, PROP_MAX_TRIS, ground_centre=True), x, y, z, turn, scale, tilt)


def wall_ring(half_x, half_y, z, sides):
    """Kit wall pieces around a rectangle. `sides` maps front/back/left/right to piece names, laid side by side
    (2 m each, or their WIDE_PIECES width) and centred on that side."""
    for side, names in sides.items():
        (ox, oy), turn = SIDES[side]
        widths = [WIDE_PIECES.get(n, 2.0) for n in names]
        start = -sum(widths) / 2
        for name, width in zip(names, widths):
            slot = start + width / 2
            start += width
            ax, ay = math.cos(turn), math.sin(turn)
            piece(name, ox * half_x + ax * slot, oy * half_y + ay * slot, z, turn)


def flat_roof(half_x, half_y, z):
    """Kit Roof_2x2 tiles covering the rectangle (the piece sits 0.2 m below its own origin)."""
    nx, ny = round(half_x), round(half_y)
    for ix in range(nx):
        for iy in range(ny):
            piece('Roof_2x2', -half_x + 1 + 2 * ix, -half_y + 1 + 2 * iy, z + 0.2)


# MARK: Simple textured shapes (barricades, posts, wire) for things the free packs don't have

def material(texture, metres=1.0, roughness=0.9, metallic=0.0, tint=None):
    """Principled material from a Poly Haven diffuse texture; `metres` = how many metres one texture repeat covers."""
    key = (texture, metres, roughness, metallic, tint)
    if key in _materials:
        return _materials[key]
    mat = bpy.data.materials.new(f'{texture}_{len(_materials)}')
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes['Principled BSDF']
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    if texture:
        image = nodes.new('ShaderNodeTexImage')
        image.image = bpy.data.images.load(os.path.join(TEXTURES, texture + '_diff_1k.jpg'), check_existing=True)
        links.new(image.outputs['Color'], bsdf.inputs['Base Color'])
    if tint:
        bsdf.inputs['Base Color'].default_value = (*tint, 1)
    mat['metres'] = metres
    _materials[key] = mat
    return mat


def _finish_shape(obj, mat, metres):
    obj.data.materials.append(mat)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    uv = bm.loops.layers.uv.verify()
    for face in bm.faces:  # box-projected UVs in metres, so textures keep their real size on long planks
        n = face.normal
        axes = (1, 2) if abs(n.x) >= max(abs(n.y), abs(n.z)) else (0, 2) if abs(n.y) >= abs(n.z) else (0, 1)
        for loop in face.loops:
            co = obj.matrix_world @ loop.vert.co
            loop[uv].uv = (co[axes[0]] / metres, co[axes[1]] / metres)
    bm.to_mesh(obj.data)
    bm.free()
    return obj


def box(size, at, mat, turn=0.0, tilt=(0.0, 0.0)):
    """A textured box: `size` (x, y, z) metres, `at` = centre of its bottom face."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=(at[0], at[1], at[2] + size[2] / 2))
    obj = bpy.context.active_object
    obj.scale = size
    obj.rotation_euler = (tilt[0], tilt[1], turn)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return _finish_shape(obj, mat, mat['metres'])


def stake(at, length, radius, mat, tilt=(0.0, 0.0), turn=0.0):
    """A sharpened wooden stake: a cylinder ending in a point, standing on `at` before tilting."""
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=radius, radius2=0, depth=length, location=(0, 0, length / 2))
    obj = bpy.context.active_object
    obj.rotation_euler = (tilt[0], tilt[1], turn)
    obj.location = at
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return _finish_shape(obj, mat, mat['metres'])


def coil(start_x, end_x, y, z, radius, turns, wire, mat):
    """Barbed-wire style helix along X (a thin tube)."""
    curve = bpy.data.curves.new('coil', 'CURVE')
    curve.dimensions = '3D'
    curve.bevel_depth = wire
    curve.bevel_resolution = 1
    spline = curve.splines.new('POLY')
    steps = turns * 10
    spline.points.add(steps)
    for i in range(steps + 1):
        t = i / steps
        a = t * turns * 2 * math.pi
        spline.points[i].co = (start_x + (end_x - start_x) * t, y + radius * math.cos(a), z + radius * math.sin(a), 1)
    obj = bpy.data.objects.new('coil', curve)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.ops.object.convert(target='MESH')
    return _finish_shape(bpy.context.active_object, mat, mat['metres'])


def sandbag_row(x0, x1, y, z, turn_row=0.0):
    """Sandbags laid end to end from x0 to x1 along X at depth y (turn_row turns the whole row about the origin)."""
    count = max(1, round((x1 - x0) / 0.68))
    step = (x1 - x0) / count
    for i in range(count):
        cx = x0 + step * (i + 0.5)
        if turn_row:
            px, py = cx * math.cos(turn_row) - y * math.sin(turn_row), cx * math.sin(turn_row) + y * math.cos(turn_row)
        else:
            px, py = cx, y
        place(_sandbag(), px, py, z, turn=turn_row + math.pi / 2 + (0.08 if i % 2 else -0.06))


SANDBAG_TRIS = 200  # sandbags come in rows of dozens
SANDBAG_COLOUR = (0.16, 0.12, 0.07)  # burlap; the Poly Haven cement bag's printed label is too loud


def _sandbag():
    """The Poly Haven cement bag, simplified and re-coloured plain burlap."""
    if 'sandbag' not in _templates:
        folder = os.path.join(POLYHAVEN, 'cement_bag')
        path = next(os.path.join(folder, f) for f in os.listdir(folder) if f.endswith('.gltf'))
        bag = _import_joined('sandbag', path, SANDBAG_TRIS, ground_centre=True)
        bag.data.materials.clear()
        bag.data.materials.append(material(None, tint=SANDBAG_COLOUR, roughness=1.0))
    return _templates['sandbag']

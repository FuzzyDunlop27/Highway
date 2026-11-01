# Purpose: One-off chunk 1R spike export: a few study models + the Mixamo walker to USDZ. Notes: docs/plans/3d-spike-1R-results.md
# Not the 2M pipeline. Rules: 1 tile = 1 metre, origin at the footprint's ground centre, Y-up for RealityKit.
# Run: /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/spike_export_usdz.py -- <out dir>
import math
import os
import sys

import bpy
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
STUDY = os.path.join(ROOT, 'HighwayHoldout_Blender_Study', 'models')
WALKER_FBX = os.path.join(ROOT, 'HighwayHoldout_Iso_Art', 'walker-mixamo', 'source', 'walker_walk_inplace.fbx')
TILE_UNITS = 1.55  # same as render_iso_sprites.py
FIT = 0.97
# name: (footprint w, footprint h, optional (top model, scale vs base, deck height in base units))
MODELS = {
    'bld_hq': (3, 3, None), 'bld_shelter': (2, 2, None), 'bld_farm': (2, 2, None),
    'dec_car_wreck': (2, 1, None), 'def_wall_wood': (1, 1, None),
    'def_watchtower_base': (1, 1, ('def_watchtower_gunner', 0.725, 2.08)),
}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def append_collection(name):
    with bpy.data.libraries.load(os.path.join(STUDY, name + '.blend')) as (src, dst):
        dst.collections = [name]
    col = dst.collections[0]
    bpy.context.scene.collection.children.link(col)
    bpy.context.view_layer.update()
    return col


def make_real(col):
    """Curves become meshes so RealityKit sees them; returns the collection's mesh objects."""
    for ob in list(col.all_objects):
        if ob.type == 'CURVE':
            bpy.ops.object.select_all(action='DESELECT')
            bpy.context.view_layer.objects.active = ob
            ob.select_set(True)
            bpy.ops.object.convert(target='MESH')
    bpy.context.view_layer.update()
    return [o for o in col.all_objects if o.type == 'MESH']


def bounds(objs):
    pts = [o.matrix_world @ Vector(v) for o in objs for v in o.bound_box]
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi = Vector([max(p[i] for p in pts) for i in range(3)])
    return lo, hi


def parent_under(col, loc, scale):
    root = bpy.data.objects.new('root_' + col.name, None)
    bpy.context.scene.collection.objects.link(root)
    for ob in col.all_objects:
        if ob.parent is None:
            ob.parent = root
    root.location, root.scale = loc, (scale,) * 3
    bpy.context.view_layer.update()


def export(path, animation=False):
    bpy.ops.wm.usd_export(filepath=path, export_animation=animation, export_materials=True,
                          generate_preview_surface=True, export_lights=False, export_cameras=False,
                          convert_orientation=True, export_global_forward_selection='NEGATIVE_Z',
                          export_global_up_selection='Y', evaluation_mode='RENDER', triangulate_meshes=True,
                          usdz_downscale_size='1024')


def export_model(name, w, h, top, out):
    reset()
    col = append_collection(name)
    lo, hi = bounds(make_real(col))
    scale = min(1 / TILE_UNITS, FIT * w / (hi.x - lo.x), FIT * h / (hi.y - lo.y))
    center = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, 0))
    parent_under(col, -center * scale, scale)
    if top:
        top_name, rel, deck = top
        gcol = append_collection(top_name)
        make_real(gcol)
        parent_under(gcol, -center * scale + Vector((0, 0, deck * scale)), scale * rel)
    export(os.path.join(out, name + '.usdz'))
    print(f'EXPORTED {name} footprint {w}x{h} scale {scale:.4f} size {(hi - lo) * scale}')


def export_walker(out):
    reset()
    bpy.ops.import_scene.fbx(filepath=WALKER_FBX)
    arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    act = arm.animation_data.action
    start, end = (int(v) for v in act.frame_range)
    bpy.context.scene.frame_start, bpy.context.scene.frame_end = start, end - 1  # last frame duplicates the first
    bpy.context.scene.render.fps = 30
    export(os.path.join(out, 'zmb_walker_mixamo.usdz'), animation=True)
    print(f'EXPORTED walker frames {start}-{end - 1} meshes {[o.name for o in bpy.data.objects if o.type == "MESH"]}')


def main():
    out = sys.argv[sys.argv.index('--') + 1]
    os.makedirs(out, exist_ok=True)
    for name, (w, h, top) in MODELS.items():
        export_model(name, w, h, top, out)
    export_walker(out)


main()

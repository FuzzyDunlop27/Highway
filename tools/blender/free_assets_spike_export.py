# Purpose: Free-asset spike: converts downloaded CC0 models (glTF/GLB/FBX/OBJ) to USDZ for the DEBUG 3D spike. Notes: docs/research/free-assets.md
# Not the 2M pipeline. Keeps real-world metres (the spike scales them at runtime), origin at the footprint's ground
# centre, Y-up for RealityKit, textures shrunk to 1024. Prints triangles + file size per model.
# Run: /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/free_assets_spike_export.py -- <out dir> [fa_name=path ...]
import glob
import os
import sys

import bpy
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, 'HighwayHoldout_3D_Sources', 'free-assets')
# Output name: source file (glob, relative to SRC). Missing sources are skipped and reported.
PICKS = {
    'fa_ph_covered_car': 'polyhaven/covered_car/*.gltf',
    'fa_ph_road_barrier': 'polyhaven/concrete_road_barrier_02/*.gltf',
    'fa_ph_trash_can': 'polyhaven/metal_trash_can/*.gltf',
    'fa_ph_barrel': 'polyhaven/Barrel_01/*.gltf',
    'fa_ph_old_tyre': 'polyhaven/old_tyre/*.gltf',
}


def import_any(path):
    ext = os.path.splitext(path)[1].lower()
    if ext in ('.gltf', '.glb'):
        bpy.ops.import_scene.gltf(filepath=path)
    elif ext == '.fbx':
        bpy.ops.import_scene.fbx(filepath=path)
    elif ext == '.obj':
        bpy.ops.wm.obj_import(filepath=path)
    else:
        raise ValueError(f'unsupported file type {ext}')


def convert(name, path, out):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    import_any(path)
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    pts = [o.matrix_world @ Vector(v) for o in meshes for v in o.bound_box]
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi = Vector([max(p[i] for p in pts) for i in range(3)])
    root = bpy.data.objects.new('root_' + name, None)
    bpy.context.scene.collection.objects.link(root)
    for ob in bpy.data.objects:
        if ob.parent is None and ob is not root:
            ob.parent = root
    root.location = (-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -lo.z)
    bpy.context.view_layer.update()
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in meshes)
    target = os.path.join(out, name + '.usdz')
    bpy.ops.wm.usd_export(filepath=target, export_materials=True, generate_preview_surface=True,
                          export_lights=False, export_cameras=False, convert_orientation=True,
                          export_global_forward_selection='NEGATIVE_Z', export_global_up_selection='Y',
                          evaluation_mode='RENDER', triangulate_meshes=True, usdz_downscale_size='1024')
    size = hi - lo
    print(f'FREEASSET {name} tris={tris} size_m={size.x:.2f}x{size.y:.2f}x{size.z:.2f} '
          f'usdz_mb={os.path.getsize(target) / 1e6:.2f} src={os.path.relpath(path, ROOT)}')


def main():
    args = sys.argv[sys.argv.index('--') + 1:]
    out = args[0]
    os.makedirs(out, exist_ok=True)
    picks = dict(PICKS)
    picks.update(a.split('=', 1) for a in args[1:])
    for name, pattern in picks.items():
        found = sorted(glob.glob(os.path.join(SRC, pattern), recursive=True))
        if not found:
            print(f'FREEASSET {name} SKIPPED: nothing matches {pattern}')
            continue
        convert(name, found[0], out)


main()

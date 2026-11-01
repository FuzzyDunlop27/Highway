# Purpose: Free-asset spike: converts downloaded CC0 models (glTF/GLB/FBX/OBJ) to USDZ for the DEBUG 3D spike. Notes: docs/research/free-assets.md
# Also assembles small buildings from modular kit pieces (free_assets_assemblies.py). Not the 2M pipeline. Keeps real-world metres (the spike scales them at runtime), origin at the footprint's ground
# centre, Y-up for RealityKit, textures shrunk to 1024. Prints triangles + file size per model.
# Run: /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/free_assets_spike_export.py -- <out dir> [fa_name=path ...] [textures=512] [only=fa_name]
import glob
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import free_assets_assemblies  # noqa: E402  (Blender runs this file directly)

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, 'HighwayHoldout_3D_Sources', 'free-assets')
# Output name: source file (glob, relative to SRC). Missing sources are skipped and reported.
TEXTURES = ['1024']  # longest texture side; 'textures=512' on the command line changes it
PICKS = {
    'fa_ph_covered_car': 'polyhaven/covered_car/*.gltf',
    'fa_ph_road_barrier': 'polyhaven/concrete_road_barrier_02/*.gltf',
    'fa_ph_trash_can': 'polyhaven/metal_trash_can/*.gltf',
    'fa_ph_barrel': 'polyhaven/Barrel_01/*.gltf',
    'fa_ph_old_tyre': 'polyhaven/old_tyre/*.gltf',
    # Kenney Retro Urban Kit: low-poly, 1 unit = 1 cell (not metres); the spike scales these separately.
    'fa_kn_truck': 'kenney/Models/GLB format/truck-grey-cargo.glb',
    'fa_kn_dumpster': 'kenney/Models/GLB format/detail-dumpster-open.glb',
    'fa_kn_wall_window': 'kenney/Models/GLB format/wall-a-window.glb',
    'fa_kn_wall_door': 'kenney/Models/GLB format/wall-a-door.glb',
    'fa_kn_roof': 'kenney/Models/GLB format/wall-a-roof.glb',
    # Quaternius Downtown City MegaKit: a prebuilt 5-storey block (~12 x 15 x 17 m).
    'fa_qt_building_small': 'quaternius/**/Building_Small_1.gltf',
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


def fix_unlit(mat):
    """Kenney's glTF uses unlit (emission) materials, which USD export drops; rebuild as a textured Principled BSDF."""
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    image = next((n for n in nodes if n.type == 'TEX_IMAGE'), None)
    if image is None or any(n.type == 'BSDF_PRINCIPLED' for n in nodes):
        return
    output = next(n for n in nodes if n.type == 'OUTPUT_MATERIAL')
    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.inputs['Roughness'].default_value = 0.9
    links.new(image.outputs['Color'], bsdf.inputs['Base Color'])
    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])


def convert(name, path, out):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    import_any(path)
    export_scene(name, out, os.path.relpath(path, ROOT))


def export_scene(name, out, source):
    """Exports everything in the scene as one model, origin at the footprint's ground centre."""
    for mat in bpy.data.materials:
        if mat.use_nodes:
            fix_unlit(mat)
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
                          evaluation_mode='RENDER', triangulate_meshes=True, usdz_downscale_size=TEXTURES[0])
    size = hi - lo
    print(f'FREEASSET {name} tris={tris} size_m={size.x:.2f}x{size.y:.2f}x{size.z:.2f} '
          f'usdz_mb={os.path.getsize(target) / 1e6:.2f} src={source}')


def main():
    args = sys.argv[sys.argv.index('--') + 1:]
    out = args[0]
    os.makedirs(out, exist_ok=True)
    picks = dict(PICKS)
    picks.update(a.split('=', 1) for a in args[1:])
    TEXTURES[0] = picks.pop('textures', TEXTURES[0])
    only = picks.pop('only', None)
    picks = {k: v for k, v in picks.items() if only in (None, k)}
    for name, pattern in picks.items():
        found = sorted(glob.glob(os.path.join(SRC, pattern), recursive=True))
        if not found:
            print(f'FREEASSET {name} SKIPPED: nothing matches {pattern}')
            continue
        convert(name, found[0], out)
    for name, build in free_assets_assemblies.ASSEMBLIES.items():
        if only not in (None, name):
            continue
        bpy.ops.wm.read_factory_settings(use_empty=True)
        build(SRC, import_any)
        export_scene(name, out, 'assembled from modular pieces')


main()

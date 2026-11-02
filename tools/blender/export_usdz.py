# Purpose: Chunk 2M model pipeline: builds every building/defense/decoration from its recipe and exports <artId>.usdz. Notes: docs/features/models-3d.md
# Rules: models are built in real metres and exported at TILES_PER_METRE (the game draws 1 model unit = 1 tile), origin at
# the footprint's ground centre, Y-up for RealityKit, textures shrunk (512 px default), normal maps dropped by default.
# Run:  /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/export_usdz.py -- [out=App/Models] [only=bld_hq]
#       [textures=1024] [normals=on] [review=<folder>]   (review = also render one 4-angle picture per model)
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import model_kit  # noqa: E402  (Blender runs this file directly)
import recipes_buildings  # noqa: E402
import recipes_defenses  # noqa: E402
import recipes_dressing  # noqa: E402

TILES_PER_METRE = 0.41  # a 1.8 m person ≈ 0.74 tiles, the size of the game's walker
RECIPES = {**recipes_buildings.RECIPES, **recipes_defenses.RECIPES, **recipes_dressing.RECIPES}


def fix_unlit(mat):
    """Unlit (emission) glTF materials don't survive USD export; rebuild them as a textured Principled BSDF."""
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    image = next((n for n in nodes if n.type == 'TEX_IMAGE'), None)
    if image is None or any(n.type == 'BSDF_PRINCIPLED' for n in nodes):
        return
    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    links.new(image.outputs['Color'], bsdf.inputs['Base Color'])
    links.new(bsdf.outputs['BSDF'], next(n for n in nodes if n.type == 'OUTPUT_MATERIAL').inputs['Surface'])


def drop_normal_maps(mat):
    """Normal maps are ~40% of the file size and invisible at game zoom (free-asset spike)."""
    nodes = mat.node_tree.nodes
    for node in [n for n in nodes if n.type == 'NORMAL_MAP']:
        for link in list(node.outputs['Normal'].links):
            mat.node_tree.links.remove(link)


def build(art_id):
    """Runs the recipe, then scales everything about the origin to tiles. Returns (meshes, footprint)."""
    model_kit.reset()
    recipe, footprint = RECIPES[art_id]
    recipe()
    for obj in [o for o in bpy.data.objects if o.name.startswith('tpl_')]:
        bpy.data.objects.remove(obj)  # templates; copies keep the shared mesh data
    root = bpy.data.objects.new('root_' + art_id, None)
    bpy.context.scene.collection.objects.link(root)
    for obj in bpy.data.objects:
        if obj.parent is None and obj is not root:
            obj.parent = root
    root.scale = (TILES_PER_METRE,) * 3
    bpy.context.view_layer.update()
    return [o for o in bpy.data.objects if o.type == 'MESH'], footprint


def export(art_id, out, textures, normals):
    meshes, footprint = build(art_id)
    for mat in bpy.data.materials:
        if mat.use_nodes:
            fix_unlit(mat)
            if not normals:
                drop_normal_maps(mat)
    pts = [o.matrix_world @ Vector(v) for o in meshes for v in o.bound_box]
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi = Vector([max(p[i] for p in pts) for i in range(3)])
    slack = 0.15  # tiles; a crate poking a little into the next tile is fine
    over = max(abs(lo.x), hi.x) > footprint[0] / 2 + slack or max(abs(lo.y), hi.y) > footprint[1] / 2 + slack
    target = os.path.join(out, art_id + '.usdz')
    bpy.ops.wm.usd_export(filepath=target, export_materials=True, generate_preview_surface=True,
                          export_lights=False, export_cameras=False, convert_orientation=True,
                          export_global_forward_selection='NEGATIVE_Z', export_global_up_selection='Y',
                          evaluation_mode='RENDER', triangulate_meshes=True, usdz_downscale_size=textures)
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in meshes)
    print(f'MODEL {art_id} tris={tris} tiles={hi.x - lo.x:.2f}x{hi.y - lo.y:.2f}x{hi.z:.2f} '
          f'mb={os.path.getsize(target) / 1e6:.2f}{"  WARNING: wider than its footprint" if over else ""}')


def review(art_id, folder):
    """One picture: the model from the game's 4 snapped camera angles (D-029), side by side, at the start pitch."""
    meshes, footprint = build(art_id)
    root = next(o for o in bpy.data.objects if o.name.startswith('root_'))
    span = max(footprint) + 0.8
    copies = [root]
    for i in range(1, 4):
        dup = root.copy()
        bpy.context.scene.collection.objects.link(dup)
        for child in root.children:
            c = child.copy()
            bpy.context.scene.collection.objects.link(c)
            c.parent = dup
        copies.append(dup)
    for i, r in enumerate(copies):  # turning the model by -90° per step = the camera stepping round it
        r.location = ((i - 1.5) * span, 0, 0)
        r.rotation_euler = (0, 0, -i * math.pi / 2)
    scene = bpy.context.scene
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam'))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = span * 4.2
    pitch = math.radians(40)
    cam.location = (0, -30 * math.cos(pitch), 30 * math.sin(pitch) + 1)
    cam.rotation_euler = (math.pi / 2 - pitch, 0, 0)
    sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN'))
    scene.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(55), 0, math.radians(35))
    sun.data.energy = 3.5
    scene.world = bpy.data.worlds.new('w')
    scene.world.color = (0.42, 0.38, 0.33)
    scene.render.resolution_x, scene.render.resolution_y = 1600, 520
    scene.render.filepath = os.path.join(folder, art_id + '.png')
    bpy.ops.render.render(write_still=True)


def main():
    opts = dict(a.split('=', 1) for a in sys.argv[sys.argv.index('--') + 1:])
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    out = os.path.join(root, opts.get('out', 'App/Models'))
    os.makedirs(out, exist_ok=True)
    ids = [opts['only']] if 'only' in opts else list(RECIPES)
    for art_id in ids:
        export(art_id, out, opts.get('textures', '512'), opts.get('normals') == 'on')
        if 'review' in opts:
            os.makedirs(opts['review'], exist_ok=True)
            review(art_id, opts['review'])


main()

# Purpose: Build the town-life spec's farmer survivor and portable review assets. Notes: docs/features/characters-3d.md
"""blender --background --python <this file> -- <farmer_source.fbx> <output_folder>"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix

sys.path.insert(0, str(Path(__file__).parent))
from blacksmith_geometry import assign, material
from character_review import finish


def main():
    args = sys.argv[sys.argv.index('--') + 1:]
    source, output = Path(args[0]).resolve(), Path(args[1]).resolve()
    output.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(source), use_custom_normals=False)
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    assert len(meshes) >= 5, 'Expected body, eyes, workwear, shoes and hair'
    minimum = min((obj.matrix_world @ v.co).z for obj in meshes for v in obj.data.vertices)
    for obj in meshes:
        world = obj.matrix_world.copy()
        for v in obj.data.vertices:
            v.co = world @ v.co
            v.co.z -= minimum
        obj.matrix_world = Matrix.Identity(4)
        obj.data.update()
        if obj.data.uv_layers:
            obj.data.uv_layers[0].name = 'SourceUV'
        for p in obj.data.polygons:
            p.use_smooth = True
        # Rebuild diffuse-only materials: imported MakeHuman normal/specular
        # wiring is unsuitable for both the portable bake and the game target.
        candidates = [n.image for slot in obj.material_slots if slot.material
                      for n in slot.material.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image]
        candidates = [img for img in candidates if 'normal' not in img.filepath.lower()
                      and '_ao' not in img.filepath.lower()]
        if 'short02' in obj.name.lower():
            mat = material('Farmer short brown hair', (.009, .004, .002), (.050, .026, .012), 55)
        else:
            if not candidates:
                raise RuntimeError('No diffuse map for ' + obj.name)
            old = candidates[0]
            img = bpy.data.images.load(bpy.path.abspath(old.filepath), check_existing=False)
            img.colorspace_settings.name = 'sRGB'
            mat = material('Farmer ' + obj.name, (.3, .3, .3))
            nodes, links = mat.node_tree.nodes, mat.node_tree.links
            uv = nodes.new('ShaderNodeUVMap')
            uv.uv_map = 'SourceUV'
            tex = nodes.new('ShaderNodeTexImage')
            tex.image = img
            links.new(uv.outputs['UV'], tex.inputs['Vector'])
            color = tex.outputs['Color']
            if 'worksuit' in obj.name.lower():
                # Faded blue overalls retain the original fitted seams/pockets.
                # A mild grey tint also takes the bright white out of the T-shirt.
                tint = nodes.new('ShaderNodeMixRGB')
                tint.blend_type = 'MULTIPLY'
                tint.inputs[0].default_value = 1
                tint.inputs[2].default_value = (.68, .72, .75, 1)
                links.new(color, tint.inputs[1])
                color = tint.outputs[0]
            links.new(color, nodes.get('Principled BSDF').inputs['Base Color'])
        assign(obj, mat)
    body = next(o for o in meshes if 'farmer_source' in o.name.lower())
    for obj in meshes:
        obj.data.calc_loop_triangles()
    before = sum(len(o.data.loop_triangles) for o in meshes)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes:
        obj.select_set(True)
        count = len(obj.data.loop_triangles)
        name = obj.name.lower()
        target = 4000 if obj == body else (3100 if 'worksuit' in name else (1100 if 'short02' in name else 500))
        if count > target:
            bpy.context.view_layer.objects.active = obj
            mod = obj.modifiers.new('Farmer mesh budget', 'DECIMATE')
            mod.ratio = target / count
            bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    body.name = 'Farmer_Adult_Woman_Draft'
    body.data.calc_loop_triangles()
    count = len(body.data.loop_triangles)
    if count > 10000:
        mod = body.modifiers.new('Final mesh cap', 'DECIMATE')
        mod.ratio = 9700 / count
        bpy.ops.object.modifier_apply(modifier=mod.name)
    body.data.calc_loop_triangles()
    count = len(body.data.loop_triangles)
    assert count <= 10000
    assert all(math.isfinite(c) for v in body.data.vertices for c in v.co)
    source_report = json.loads((source.parent / 'farmer_source.json').read_text())
    report = {'role': 'farmer survivor', 'spec': 'docs/plans/town-life-plan.md section 3b',
              'source_fbx': str(source), 'source_settings': source_report,
              'triangles_before_optimization': before, 'triangle_count': count,
              'max_triangle_budget': 10000, 'rigged': False, 'animated': False,
              'look_status': 'adult woman farmer in faded denim overalls, grey shirt, boots and short brown hair',
              'front': '-Y in Blender; not game-converted', 'source_licence': 'Bundled MakeHuman system assets CC0',
              'still_pending': ['rig/deformation and task-animation checks', 'fine hand/face detail',
                                'RealityKit integration, animated size and real-device performance']}
    finish(body, output, report, slug='farmer', label='Farmer survivor')


main()

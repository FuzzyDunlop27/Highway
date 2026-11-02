# Purpose: Assemble and optimize the clothed blacksmith source for review. Notes: docs/features/characters-3d.md
"""blender --background --python <this file> -- <dressed_source.fbx> <output_folder>"""
import json
import math
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).parent))
from blacksmith_geometry import apron, assign, beard, material
from blacksmith_review import finish


def main():
    args = sys.argv[sys.argv.index('--') + 1:]
    source, output = Path(args[0]).resolve(), Path(args[1]).resolve()
    output.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(source), use_custom_normals=False)
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    # Make all mesh vertices world-local, then ground the complete clothed source.
    minimum = min((o.matrix_world @ v.co).z for o in meshes for v in o.data.vertices)
    for obj in meshes:
        for v in obj.data.vertices:
            v.co = obj.matrix_world @ v.co
            v.co.z -= minimum
        obj.matrix_world.identity()
        obj.data.update()
        for poly in obj.data.polygons:
            poly.use_smooth = True
    body = next(o for o in meshes if 'blacksmith_dressed' in o.name.lower())
    height = max(v.co.z for v in body.data.vertices)
    shirt = next(o for o in meshes if 'casual' in o.name.lower())
    linen = material('Undyed worn linen', (.18, .15, .10), (.40, .35, .23), 85)
    trousers = material('Charcoal wool', (.025, .028, .027), (.065, .060, .051), 95)
    leather = material('Worn umber apron', (.035, .013, .005), (.15, .069, .020), 20)
    strap = material('Oiled leather straps', (.018, .008, .003), (.052, .027, .009), 40)
    hair = material('Dark brown with grey', (.006, .004, .003), (.060, .052, .043), 65)
    boots = material('Soot brown boots', (.018, .010, .006), (.055, .035, .022), 35)
    assign(shirt, linen)
    shirt.data.materials.append(trousers)
    # The suit is a connected mesh. Cut an exact waistband before assigning the
    # wool material, keeping a straight boundary hidden under the leather belt.
    bm = bmesh.new()
    bm.from_mesh(shirt.data)
    bmesh.ops.bisect_plane(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
                          dist=.00001, plane_co=(0, 0, height * .61), plane_no=(0, 0, 1))
    bm.to_mesh(shirt.data)
    bm.free()
    shirt.data.update()
    for poly in shirt.data.polygons:
        if poly.center.z < height * .61:
            poly.material_index = 1
    for obj in meshes:
        lower = obj.name.lower()
        if 'shoe' in lower:
            assign(obj, boots)
        if 'short04' in lower:
            assign(obj, hair)
    # MakeHuman FBX maps its diffuse image into a normal input and may import
    # metallic parameters. Rebuild skin/eyes explicitly for a reliable diffuse bake.
    for obj, fragment in [(body, 'middleage_lightskinned_male_diffuse'),
                           (next(o for o in meshes if 'high-poly' in o.name.lower()), 'brown_eye')]:
        old = next(img for img in bpy.data.images if fragment in img.filepath)
        image = bpy.data.images.load(bpy.path.abspath(old.filepath), check_existing=False)
        image.colorspace_settings.name = 'sRGB'
        mat = material('Weathered skin' if obj == body else 'Brown eyes', (.25, .15, .10))
        nodes, links = mat.node_tree.nodes, mat.node_tree.links
        tex = nodes.new('ShaderNodeTexImage')
        tex.image = image
        uv = nodes.new('ShaderNodeUVMap')
        uv.uv_map = 'SourceUV'
        links.new(uv.outputs['UV'], tex.inputs['Vector'])
        if obj == body:
            tint = nodes.new('ShaderNodeMixRGB')
            tint.blend_type = 'MULTIPLY'
            tint.inputs[0].default_value = 1
            tint.inputs[2].default_value = (.72, .56, .42, 1)
            links.new(tex.outputs['Color'], tint.inputs[1])
            links.new(tint.outputs[0], nodes.get('Principled BSDF').inputs['Base Color'])
        else:
            links.new(tex.outputs['Color'], nodes.get('Principled BSDF').inputs['Base Color'])
        assign(obj, mat)
    apron([body, shirt], height, leather, strap)
    beard(body, height, hair)
    # Exported skin/eye image textures use their original UVs during atlas bake.
    for obj in meshes:
        if not obj.data.uv_layers:
            continue
        obj.data.uv_layers[0].name = 'SourceUV'
        for mat in obj.data.materials:
            if not mat or not mat.use_nodes:
                continue
            nodes = mat.node_tree.nodes
            uv = nodes.new('ShaderNodeUVMap')
            uv.uv_map = 'SourceUV'
            for node in list(nodes):
                if node.type == 'TEX_IMAGE' and not node.inputs['Vector'].is_linked:
                    mat.node_tree.links.new(uv.outputs['UV'], node.inputs['Vector'])
            bsdf = nodes.get('Principled BSDF')
            if bsdf:
                bsdf.inputs['Roughness'].default_value = .85
    # Preserve the unoptimized assembly in a separate source file.
    bpy.ops.object.select_all(action='DESELECT')
    objects = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.wm.save_as_mainfile(filepath=str(output / 'blacksmith_assembly.blend'))
    before = sum(len(o.data.loop_triangles) for o in objects)
    for obj in objects:
        obj.data.calc_loop_triangles()
    before = sum(len(o.data.loop_triangles) for o in objects)
    # Keep a larger share of detail in exposed face/hands than in hidden clothing surfaces.
    for obj in objects:
        count = len(obj.data.loop_triangles)
        target = 3800 if obj == body else (2200 if obj == shirt else (1000 if 'short04' in obj.name.lower() else 500))
        if count > target:
            bpy.context.view_layer.objects.active = obj
            decimate = obj.modifiers.new('Review mesh budget', 'DECIMATE')
            decimate.ratio = target / count
            bpy.ops.object.modifier_apply(modifier=decimate.name)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    body.name = 'Harlan_Blacksmith_Draft'
    body.data.calc_loop_triangles()
    triangles = len(body.data.loop_triangles)
    if triangles > 10000:
        decimate = body.modifiers.new('Final budget cap', 'DECIMATE')
        decimate.ratio = 9700 / triangles
        bpy.ops.object.modifier_apply(modifier=decimate.name)
    body.data.calc_loop_triangles()
    if len(body.data.loop_triangles) > 10000:
        raise RuntimeError('Mesh budget exceeded')
    if not all(math.isfinite(c) for v in body.data.vertices for c in v.co):
        raise RuntimeError('Invalid vertex position')
    report = {'source_fbx': str(source), 'source_dressed_settings': json.loads((source.parent / 'dressed_source.json').read_text()),
              'triangles_before_optimization': before, 'triangle_count': len(body.data.loop_triangles),
              'max_triangle_budget': 10000, 'rigged': False, 'animated': False,
              'look_status': 'clothed review draft, not a final likeness or deformation-approved mesh',
              'grounded_head_top_metres': height, 'front': '-Y in Blender; not game-converted',
              'source_licence': 'MakeHuman bundled assets CC0; apron/beard assembly authored for this project'}
    finish(body, output, report)


main()

# Purpose: Bake/export character drafts and verify review assets. Notes: docs/features/characters-3d.md
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


def finish(body, output, report, slug='blacksmith', label='Harlan'):
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.select_all(action='DESELECT')
    body.select_set(True)
    atlas_uv = body.data.uv_layers.new(name='Atlas')
    body.data.uv_layers.active_index = len(body.data.uv_layers) - 1
    atlas_uv.active_render = True
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=.012)
    bpy.ops.object.mode_set(mode='OBJECT')
    image = bpy.data.images.new(label + ' single albedo atlas', width=1024, height=1024, alpha=False)
    image.generated_color = (.1, .1, .1, 1)
    for mat in body.data.materials:
        if not mat:
            continue
        mat.use_nodes = True
        node = mat.node_tree.nodes.new('ShaderNodeTexImage')
        node.image = image
        mat.node_tree.nodes.active = node
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 8
    scene.render.bake.use_pass_direct = False
    scene.render.bake.use_pass_indirect = False
    scene.render.bake.use_pass_color = True
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'}, margin=8)
    image.filepath_raw = str(output / f'{slug}_albedo.png')
    image.file_format = 'PNG'
    image.save()
    final = bpy.data.materials.new(label + ' atlas material')
    final.use_nodes = True
    bsdf = final.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Roughness'].default_value = .85
    tex = final.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image = image
    uv = final.node_tree.nodes.new('ShaderNodeUVMap')
    uv.uv_map = 'Atlas'
    final.node_tree.links.new(uv.outputs['UV'], tex.inputs['Vector'])
    final.node_tree.links.new(tex.outputs['Color'], bsdf.inputs['Base Color'])
    body.data.materials.clear()
    body.data.materials.append(final)
    for p in body.data.polygons:
        p.material_index = 0
        p.use_smooth = True
    # Remove old source UVs so FBX consumers cannot accidentally pick the wrong set.
    for layer in list(body.data.uv_layers):
        if layer.name != 'Atlas':
            body.data.uv_layers.remove(layer)
    image.pack()
    # Final packed file must not depend on unused source images elsewhere on this Mac.
    bpy.data.orphans_purge(do_recursive=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output / f'{slug}_draft.blend'))
    bpy.ops.export_scene.fbx(filepath=str(output / f'{slug}_draft.fbx'), use_selection=True,
                             object_types={'MESH'}, add_leaf_bones=False, bake_anim=False,
                             axis_forward='-Z', axis_up='Y', path_mode='COPY', embed_textures=True)
    bpy.ops.export_scene.gltf(filepath=str(output / f'{slug}_draft.glb'), export_format='GLB',
                              use_selection=True, export_animations=False)
    image512 = image.copy()
    image512.scale(512, 512)
    image512.filepath_raw = str(output / f'{slug}_albedo_512.png')
    image512.file_format = 'PNG'
    image512.save()
    report.update({'atlas_size': [1024, 1024], 'game_atlas_copy': [512, 512], 'materials': 1,
                   'uv_layers': [layer.name for layer in body.data.uv_layers],
                   'fbx_bytes': (output / f'{slug}_draft.fbx').stat().st_size,
                   'glb_bytes': (output / f'{slug}_draft.glb').stat().st_size})
    report.setdefault('still_pending', ['final face/scar/hand details', 'historical costume refinement',
                                      'deformation/rigging/animations', 'RealityKit integration and device check'])
    (output / 'draft_report.json').write_text(json.dumps(report, indent=2) + '\n')
    low = Vector(tuple(min(v.co[i] for v in body.data.vertices) for i in range(3)))
    high = Vector(tuple(max(v.co[i] for v in body.data.vertices) for i in range(3)))
    centre = (low + high) / 2
    height = high.z - low.z
    scene.world = bpy.data.worlds.new('Studio')
    scene.world.color = (.12, .12, .12)
    for pos, energy, size in [((3, -4, 5), 850, 4), ((-3, -2, 3), 450, 3), ((1, 3, 4), 850, 3)]:
        bpy.ops.object.light_add(type='AREA', location=pos)
        light = bpy.context.object
        light.data.energy = energy
        light.data.shape = 'DISK'
        light.data.size = size
        light.rotation_euler = (centre - light.location).to_track_quat('-Z', 'Y').to_euler()
    bpy.ops.object.camera_add(location=(3, -7, centre.z))
    camera = bpy.context.object
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = height * 1.18
    scene.camera = camera
    scene.cycles.samples = 32
    scene.render.resolution_x = 800
    scene.render.resolution_y = 1000
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.view_settings.view_transform = 'AgX'
    for name, pos in [('front', (0, -7, centre.z)), ('threequarter', (3.2, -7, centre.z)),
                      ('back', (2, 7, centre.z)), ('side', (7, 0, centre.z))]:
        camera.location = pos
        camera.rotation_euler = (centre - camera.location).to_track_quat('-Z', 'Y').to_euler()
        scene.render.filepath = str(output / f'{slug}_{name}.png')
        bpy.ops.render.render(write_still=True)
    # Reimport the actual exported FBX into a clean scene, not just the in-memory mesh.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(output / f'{slug}_draft.fbx'), use_custom_normals=False)
    imported = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    count = 0
    points = []
    for obj in imported:
        obj.data.calc_loop_triangles()
        count += len(obj.data.loop_triangles)
        points.extend(obj.matrix_world @ v.co for v in obj.data.vertices)
    assert imported and count == report['triangle_count'] and count <= 10000
    assert all(math.isfinite(c) for p in points for c in p)
    actual_height = max(p.z for p in points) - min(p.z for p in points)
    assert abs(actual_height - height) < .001
    materials = {slot.material.name for obj in imported for slot in obj.material_slots if slot.material}
    assert len(materials) == 1
    missing = [img.filepath for img in bpy.data.images if img.source == 'FILE' and img.filepath
               and not img.packed_file and not Path(bpy.path.abspath(img.filepath)).is_file()]
    assert not missing, missing
    report['fbx_round_trip'] = {'mesh_count': len(imported), 'triangle_count': count,
                              'height_metres': actual_height, 'materials': len(materials),
                              'missing_images': missing, 'passed': True}
    (output / 'draft_report.json').write_text(json.dumps(report, indent=2) + '\n')
    print('CHARACTER_DRAFT_READY ' + json.dumps(report))

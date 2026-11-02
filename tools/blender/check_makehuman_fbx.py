# Purpose: Verify a real MakeHuman FBX and render its base-body preview. Notes: docs/features/characters-3d.md
"""blender --background --python tools/blender/check_makehuman_fbx.py -- /path/to/blacksmith_base.fbx"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def main():
    fbx = Path(sys.argv[sys.argv.index("--") + 1]).resolve()
    generation = json.loads((fbx.parent / "generation_report.json").read_text())
    expected_height = generation["measured_height_cm"] / 100
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # MakeHuman's exported custom normals produce severe facets in Blender 5.2.
    # Recompute from the actual mesh instead of trusting those split normals.
    bpy.ops.import_scene.fbx(filepath=str(fbx), use_custom_normals=False)
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("FBX contains no mesh")
    points = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    low = Vector(tuple(min(p[i] for p in points) for i in range(3)))
    high = Vector(tuple(max(p[i] for p in points) for i in range(3)))
    height = high.z - low.z
    triangles = 0
    for obj in meshes:
        obj.data.calc_loop_triangles()
        triangles += len(obj.data.loop_triangles)
        if not all(math.isfinite(c) for v in obj.data.vertices for c in v.co):
            raise RuntimeError("Non-finite mesh coordinates")
    if abs(height - expected_height) > 0.001:
        raise RuntimeError("Height mismatch: Blender {} m vs MakeHuman {} m".format(height, expected_height))
    if abs(low.z) > 0.005:
        raise RuntimeError("Feet not on ground: {} m".format(low.z))
    result = {
        "fbx": str(fbx), "blender_version": bpy.app.version_string,
        "mesh_count": len(meshes), "triangle_count": triangles,
        "height_metres": height, "expected_height_metres": expected_height,
        "height_error_metres": abs(height - expected_height), "minimum_z_metres": low.z,
        "has_rig": any(obj.type == "ARMATURE" for obj in bpy.context.scene.objects),
        "mobile_triangle_budget": 10000, "within_triangle_budget": triangles <= 10000,
        "source_materials": [m.name for m in bpy.data.materials],
        "missing_image_paths": [img.filepath for img in bpy.data.images
                                if img.source == "FILE" and img.filepath
                                and not Path(bpy.path.abspath(img.filepath)).is_file()],
        "profile_details_applied": False,
        "import_custom_normals": False,
    }
    (fbx.parent / "blender_verification.json").write_text(json.dumps(result, indent=2) + "\n")
    # Preserve imported body/materials before adding the neutral studio preview.
    bpy.ops.wm.save_as_mainfile(filepath=str(fbx.parent / "blacksmith_base.blend"))
    material = bpy.data.materials.new("Neutral review clay")
    material.diffuse_color = (0.30, 0.34, 0.38, 1)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (0.30, 0.34, 0.38, 1)
    bsdf.inputs["Roughness"].default_value = 0.75
    for obj in meshes:
        obj.data.materials.clear()
        obj.data.materials.append(material)
        for poly in obj.data.polygons:
            poly.use_smooth = True
    centre = (low + high) / 2
    bpy.ops.object.camera_add(location=(4, -7, centre.z + 0.2))
    camera = bpy.context.object
    camera.rotation_euler = (centre - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = height * 1.23
    bpy.context.scene.camera = camera
    for location, power, size in [((3, -4, 5), 900, 4), ((-3, -2, 3), 550, 3), ((1, 3, 4), 800, 3)]:
        bpy.ops.object.light_add(type="AREA", location=location)
        lamp = bpy.context.object
        lamp.data.energy = power
        lamp.data.shape = "DISK"
        lamp.data.size = size
        lamp.rotation_euler = (centre - lamp.location).to_track_quat("-Z", "Y").to_euler()
    scene = bpy.context.scene
    scene.world = bpy.data.worlds.new("Review background")
    scene.world.color = (0.12, 0.12, 0.12)
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 24
    scene.render.resolution_x = 700
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(fbx.parent / "blacksmith_base_preview.png")
    bpy.ops.render.render(write_still=True)
    print("MAKEHUMAN_VERIFIED " + json.dumps(result))


main()

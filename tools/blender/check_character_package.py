# Purpose: Verify committed character files work as standalone review packages. Notes: docs/features/characters-3d.md
"""blender --background --python <this file> -- <makehuman asset root>"""
import json
import math
import shutil
import sys
import tempfile
from pathlib import Path

import bpy


def geometry():
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    triangles, points, images = 0, [], []
    materials = set()
    for obj in meshes:
        obj.data.calc_loop_triangles()
        triangles += len(obj.data.loop_triangles)
        points.extend(obj.matrix_world @ v.co for v in obj.data.vertices)
        for mat in obj.data.materials:
            if not mat:
                continue
            materials.add(mat.name)
            images.extend(n.image for n in mat.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image)
    assert len(meshes) == 1 and len(materials) == 1
    assert points and all(math.isfinite(c) for point in points for c in point)
    assert images and all(list(img.size) == [1024, 1024] for img in images)
    return triangles, max(p.z for p in points) - min(p.z for p in points), images


def main():
    root = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
    verification = {}
    for role in ['farmer', 'blacksmith']:
        folder = root / role
        expected = json.loads((folder / 'draft_report.json').read_text())
        expected_height = expected['fbx_round_trip']['height_metres']
        results = {}
        bpy.ops.wm.open_mainfile(filepath=str(folder / f'{role}_draft.blend'), load_ui=False)
        count, height, images = geometry()
        assert count == expected['triangle_count'] <= 10000
        assert abs(height - expected_height) < .001
        assert all(img.packed_file for img in images), 'Blend atlas must be packed'
        results['blend'] = {'triangles': count, 'height_metres': height, 'packed_atlas': True}
        with tempfile.TemporaryDirectory(prefix='highway-character-package-') as scratch:
            temp = Path(scratch)
            for ext in ['fbx', 'glb']:
                shutil.copy2(folder / f'{role}_draft.{ext}', temp / f'{role}_draft.{ext}')
            shutil.copy2(folder / f'{role}_albedo.png', temp / f'{role}_albedo.png')
            for ext in ['fbx', 'glb']:
                bpy.ops.wm.read_factory_settings(use_empty=True)
                path = temp / f'{role}_draft.{ext}'
                if ext == 'fbx':
                    bpy.ops.import_scene.fbx(filepath=str(path), use_custom_normals=False)
                else:
                    bpy.ops.import_scene.gltf(filepath=str(path))
                count, height, images = geometry()
                assert count == expected['triangle_count'] <= 10000
                assert abs(height - expected_height) < .001
                for img in images:
                    if not img.packed_file:
                        file = Path(bpy.path.abspath(img.filepath)).resolve()
                        assert temp in file.parents and file.is_file(), 'External image dependency: ' + str(file)
                results[ext] = {'triangles': count, 'height_metres': height,
                                'portable_textures': True, 'materials': 1}
        verification[role] = results
    (root / 'package_verification.json').write_text(json.dumps(verification, indent=2) + '\n')
    print('CHARACTER_PACKAGES_PASS ' + json.dumps(verification))


main()

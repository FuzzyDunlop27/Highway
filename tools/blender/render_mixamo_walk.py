# Purpose: Renders a stock Mixamo walker with the shared iso staging. Notes: docs/features/zombie-walk-mixamo.md
"""blender -b -P tools/blender/render_mixamo_walk.py -- FBX OUT [--test] [--root-fbx FBX]
Run tools/blender/preview_mixamo_walk.py after rendering for comparison/GIF previews.
The scale/registration is fitted once across the whole cycle, never per frame.
"""
import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from render_iso_sprites import camera_axes, point_camera, staging, FACING  # noqa: E402

CANVAS = (256, 232)
BODY_HEIGHT = 160
BASELINE = 184
FRAME_COUNT = 6


def arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('fbx', type=Path)
    parser.add_argument('out', type=Path)
    parser.add_argument('--root-fbx', type=Path)
    parser.add_argument('--test', action='store_true')
    return parser.parse_args(sys.argv[sys.argv.index('--') + 1:])


def import_actor(path):
    old = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(path.resolve()))
    objects = set(bpy.data.objects) - old
    armature = next(o for o in objects if o.type == 'ARMATURE')
    meshes = [o for o in objects if o.type == 'MESH']
    action = armature.animation_data.action
    start, end = action.frame_range
    return objects, armature, meshes, float(start), float(end)


def mesh_points(meshes):
    deps = bpy.context.evaluated_depsgraph_get()
    points = []
    for obj in meshes:
        evaluated = obj.evaluated_get(deps)
        mesh = evaluated.to_mesh()
        points.extend(evaluated.matrix_world @ v.co for v in mesh.vertices)
        evaluated.to_mesh_clear()
    return points


def set_frame(frame):
    whole = math.floor(frame)
    bpy.context.scene.frame_set(whole, subframe=frame - whole)
    bpy.context.view_layer.update()


def hip_position(armature):
    hip = next(b for b in armature.pose.bones if b.name.endswith(':Hips'))
    return armature.matrix_world @ hip.head


def root_distance(path):
    objects, arm, _, start, end = import_actor(path)
    set_frame(start)
    first = hip_position(arm).copy()
    set_frame(end)
    last = hip_position(arm).copy()
    delta = last - first
    for obj in objects:
        bpy.data.objects.remove(obj, do_unlink=True)
    return math.hypot(delta.x, delta.y), list(delta)


def repair_textures(folder):
    """Embedded Mixamo images need no relink; use adjacent exports if absent."""
    for image in bpy.data.images:
        if image.packed_file or image.packed_files:
            continue
        path = Path(bpy.path.abspath(image.filepath))
        if path.is_file():
            continue
        matches = list(folder.rglob(path.name))
        if not matches:
            raise RuntimeError(f'Missing texture: {path.name}')
        image.filepath = str(matches[0].resolve())
        image.reload()


def main():
    opts = arguments()
    opts.out.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_homefile(use_empty=True)
    scene = bpy.context.scene
    root_meters, root_delta = root_distance(opts.root_fbx) if opts.root_fbx else (None, None)
    objects, armature, meshes, start, end = import_actor(opts.fbx)
    repair_textures(opts.fbx.parent)
    pivot = bpy.data.objects.new('walker facing +X', None)
    scene.collection.objects.link(pivot)
    for obj in objects:
        if obj.parent not in objects:
            obj.parent = pivot
    # Mixamo's native +Z forward imports facing -Y; shared iso models face +X.
    pivot.rotation_euler.z = math.pi / 2
    d, right, up = camera_axes()
    frames = [start + (end - start) * i / FRAME_COUNT for i in range(FRAME_COUNT)]
    projected = []
    for facing in ('se', 'ne'):
        pivot.rotation_euler.z = math.pi / 2 + math.radians(FACING[facing])
        for frame in frames:
            set_frame(frame)
            projected.extend(p.dot(up) for p in mesh_points(meshes))
    k = CANVAS[0] / math.sqrt(2)
    scale = BODY_HEIGHT / ((max(projected) - min(projected)) * k)
    pivot.scale = (scale,) * 3
    # One camera offset puts the lowest cycle silhouette on the existing baseline.
    low = min(projected) * scale
    center_up = low + (BASELINE - CANVAS[1] / 2) / k
    staging.setup(scene, transparent=True, samples=32)
    cam = staging.camera(scene, 'walker iso', d * 60 + up * center_up,
                         up * center_up, math.sqrt(2))
    cam.data.sensor_fit = 'HORIZONTAL'
    scene.render.resolution_x, scene.render.resolution_y = CANVAS
    scene.render.fps = 30
    metrics = {'source': opts.fbx.name, 'character': 'Yaku J Ignite',
               'animation': 'Zombie Walk', 'start': start, 'end': end,
               'sampleFrames': frames, 'scale': scale, 'canvas': CANVAS,
               'bodyHeightPx': BODY_HEIGHT, 'baselinePx': BASELINE,
               'rootDistanceMeters': root_meters, 'rootDeltaMeters': root_delta,
               'strideTiles': root_meters * scale if root_meters else None}
    # Quantify closure of the actual endpoints rather than assuming FBX scene end=250.
    pivot.rotation_euler.z = math.pi / 2
    set_frame(start)
    first = mesh_points(meshes)
    set_frame(end)
    last = mesh_points(meshes)
    metrics['endpointMaxDifferencePx'] = max((a-b).length for a,b in zip(first,last)) * k
    metrics['endpointMeanDifferencePx'] = sum((a-b).length for a,b in zip(first,last)) / len(first) * k
    for facing in ('se', 'ne'):
        if opts.test and facing != 'se':
            continue
        pivot.rotation_euler.z = math.pi / 2 + math.radians(FACING[facing])
        for index, frame in enumerate(frames[:1] if opts.test else frames):
            set_frame(frame)
            scene.render.filepath = str((opts.out / f'zmb_walker_{facing}_w{index}.png').resolve())
            bpy.ops.render.render(write_still=True)
        if not opts.test:
            import shutil
            shutil.copyfile(opts.out / f'zmb_walker_{facing}_w0.png', opts.out / f'zmb_walker_{facing}.png')
    (opts.out.parent / 'render-metadata.json').write_text(json.dumps(metrics, indent=2) + '\n')
    print('MIXAMO_METADATA', json.dumps(metrics), flush=True)


if __name__ == '__main__':
    main()

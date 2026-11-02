# Purpose: Chunks 3M/3M-2: Mixamo character FBX clips → one animated <artId>.usdz + <artId>.anim.json (clip times, stride). Notes: docs/features/characters-3d.md
# Rules: same scale as the 2M models (TILES_PER_METRE, 1 model unit = 1 tile), feet on the origin, front towards +X
# (the game's heading 0). All clips of one character sit one after another on a single timeline (USD has one), and the
# .anim.json says where each clip starts and ends so the app can cut them apart. Mixamo files stay local (D-038).
# Run:  /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/export_characters.py -- [out=App/Models]
#       [textures=512] [only=zmb_walker]
import json
import math
import os
import sys

import bpy

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCES = os.path.join(ROOT, 'HighwayHoldout_3D_Sources')
TILES_PER_METRE = 0.41  # same as tools/blender/export_usdz.py (D-037)
FPS = 30
# art id → source folder, clips (name → in-place FBX; walk is required, the others are used when the file exists),
# the root-motion walk used to measure the stride, and whether the clip's last frame repeats its first (Mixamo loops).
CHARACTERS = {
    'zmb_walker': {
        'folder': 'mixamo-walker',
        'clips': {'walk': 'walker_walk_inplace.fbx', 'attack': 'walker_attack_inplace.fbx', 'idle': 'walker_idle.fbx'},
        'stride': 'walker_walk_root.fbx',
    },
    'unit_defender': {  # optional: skipped until its Mixamo FBX are downloaded
        'folder': 'mixamo-defender',
        'clips': {'idle': 'defender_idle.fbx'},
        'stride': 'defender_walk_root.fbx',
    },
    'sv_farmer': {  # MakeHuman farmer rigged in Mixamo (owner, 2026-11-01); walk/run downloaded with root motion
        'folder': 'makehuman',
        'clips': {'walk': 'sv-farmer_walking.fbx', 'attack': 'sv-farmer_rifle.fbx', 'run': 'sv-farmer_running.fbx'},
        'stride': 'sv-farmer_walking.fbx',
        'rootMotion': True,
        'loopFrom': ['walk'],  # this walk starts from standing: keep only the last full step cycle
    },
}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = FPS


def import_fbx(path):
    """Imports an FBX and returns (new objects, its armature, its action)."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    arm = next(o for o in new if o.type == 'ARMATURE')
    return new, arm, arm.animation_data.action if arm.animation_data else None


def clip_frames(action, first=None):
    """Frames to keep: Mixamo's last frame equals its first, so drop it (else the loop stutters)."""
    start, end = (int(round(v)) for v in action.frame_range)
    start = start if first is None else first
    return start, max(start, end - 1)


def fcurves(action):
    """The action's F-curves (Blender 4.4+ keeps them in layered-action channel bags)."""
    if hasattr(action, 'layers') and action.layers:
        return [fc for strip in action.layers[0].strips for bag in strip.channelbags for fc in bag.fcurves]
    return list(action.fcurves)


def loop_start(arm, action, min_frames=20):
    """First frame of the last full cycle: the frame whose pose (every bone's rotation) best matches the last frame.
    For clips that start from standing, so the kept part loops without a hitch."""
    arm.animation_data.action = action
    first, last = (int(round(v)) for v in action.frame_range)

    def pose(frame):
        bpy.context.scene.frame_set(frame)
        return [b.matrix_basis.to_quaternion() for b in arm.pose.bones]

    end = pose(last)
    best, best_cost = first, float('inf')
    for frame in range(first, last - min_frames + 1):
        cost = sum(1 - abs(a.dot(b)) for a, b in zip(pose(frame), end))
        if cost < best_cost:
            best, best_cost = frame, cost
    return best


def strip_root_motion(action, first=None):
    """Turns a clip that walks forward into an in-place one: removes the hips' steady drift from `first` (default: the
    first key) to the last frame (a straight line), keeping their sway and bob. The game moves the character itself."""
    for fc in fcurves(action):
        if 'Hips' not in fc.data_path or not fc.data_path.endswith('location') or len(fc.keyframe_points) < 2:
            continue
        keys = fc.keyframe_points
        f0, f1 = (keys[0].co.x if first is None else first), keys[-1].co.x
        start = fc.evaluate(f0)
        lead = start - keys[0].co.y  # how far the clip had already walked at `first`: move it back to the origin
        drift = keys[-1].co.y - start
        for k in keys:
            shift = lead + drift * (k.co.x - f0) / (f1 - f0)
            k.co.y -= shift
            k.handle_left.y -= shift
            k.handle_right.y -= shift


def measure_stride(path, action_frames, first=None):
    """Tiles the hips travel in one walk loop of the root-motion FBX (= how far the feet carry the body)."""
    reset()
    _, arm, action = import_fbx(path)
    start, end = action.frame_range
    start = start if first is None else first
    hips = arm.pose.bones['mixamorig:Hips']
    points = []
    for frame in (int(start), int(end)):
        bpy.context.scene.frame_set(frame)
        points.append((arm.matrix_world @ hips.head).copy())
    flat = points[1] - points[0]
    flat.z = 0
    metres = flat.length * (action_frames / (end - start))  # same loop length as the in-place clip
    return metres * TILES_PER_METRE


def build(art_id, spec):
    """Character + every clip that exists, laid out on one NLA track. Returns {clip: (first, last frame)} on the timeline."""
    reset()
    folder = os.path.join(SOURCES, spec['folder'])
    clips = {name: os.path.join(folder, f) for name, f in spec['clips'].items() if os.path.exists(os.path.join(folder, f))}
    if 'walk' not in clips and 'idle' not in clips:
        raise FileNotFoundError(f'{art_id}: no walk or idle FBX in {folder}')
    first = 'walk' if 'walk' in clips else 'idle'
    _, arm, first_action = import_fbx(clips.pop(first))
    actions = {first: first_action}
    root_motion = spec.get('rootMotion', False)
    for name, path in clips.items():  # other clips: keep only their action (same Mixamo skeleton, same bone names)
        new, _, action = import_fbx(path)
        action.use_fake_user = True
        for obj in new:
            bpy.data.objects.remove(obj)
        actions[name] = action
    starts = {name: loop_start(arm, actions[name]) for name in spec.get('loopFrom', []) if name in actions}
    if root_motion:
        for name, action in actions.items():
            strip_root_motion(action, starts.get(name))
    arm.animation_data.action = None
    track = arm.animation_data.nla_tracks.new()
    layout, cursor = {}, 0
    build.walk_start = starts.get('walk')
    for name, action in actions.items():
        start, end = clip_frames(action, starts.get(name))
        strip = track.strips.new(name, cursor, action)
        strip.action_frame_start, strip.action_frame_end = start, end
        strip.frame_end = cursor + (end - start)
        layout[name] = (cursor, cursor + (end - start))
        cursor += end - start + 1
    scene = bpy.context.scene
    scene.frame_start, scene.frame_end = 0, cursor - 1
    root = bpy.data.objects.new('root_' + art_id, None)
    scene.collection.objects.link(root)
    for obj in bpy.data.objects:
        if obj.parent is None and obj is not root:
            obj.parent = root
    root.scale = (TILES_PER_METRE,) * 3
    root.rotation_euler = (0, 0, math.pi / 2)  # Mixamo faces Blender -Y; the game's heading 0 is +X
    bpy.context.view_layer.update()
    return layout


def export(art_id, spec, out, textures):
    layout = build(art_id, spec)
    target = os.path.join(out, art_id + '.usdz')
    bpy.ops.wm.usd_export(filepath=target, export_animation=True, export_materials=True, generate_preview_surface=True,
                          export_lights=False, export_cameras=False, convert_orientation=True,
                          export_global_forward_selection='NEGATIVE_Z', export_global_up_selection='Y',
                          evaluation_mode='RENDER', triangulate_meshes=True, usdz_downscale_size=textures)
    info = {'_notes': 'Written by tools/blender/export_characters.py; do not edit. Clip times in seconds on the '
                      'model timeline (first and last frame shown); strideTiles = distance one walk loop carries the body.',
            'fps': FPS, 'clips': {k: [a / FPS, b / FPS] for k, (a, b) in layout.items()}}
    stride_file = os.path.join(SOURCES, spec['folder'], spec['stride'])
    if 'walk' in layout and os.path.exists(stride_file):
        a, b = layout['walk']
        info['strideTiles'] = round(measure_stride(stride_file, b - a + 1, getattr(build, 'walk_start', None)), 4)
    with open(os.path.join(out, art_id + '.anim.json'), 'w') as f:
        json.dump(info, f, indent=2)
    print(f'CHARACTER {art_id} clips={info["clips"]} stride={info.get("strideTiles")} '
          f'mb={os.path.getsize(target) / 1e6:.2f}')


def main():
    opts = dict(a.split('=', 1) for a in sys.argv[sys.argv.index('--') + 1:])
    out = os.path.join(ROOT, opts.get('out', 'App/Models'))
    os.makedirs(out, exist_ok=True)
    for art_id, spec in CHARACTERS.items():
        if 'only' in opts and opts['only'] != art_id:
            continue
        try:
            export(art_id, spec, out, opts.get('textures', '512'))
        except FileNotFoundError as error:
            print(f'SKIPPED {error}')


main()

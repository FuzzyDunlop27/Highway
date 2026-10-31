# Purpose: Renders the isometric view's sprites from the Blender study's 3D models (+ stand-ins). Spec: docs/graphics-spec-iso.md
"""Run (takes a few minutes):
    /Applications/Blender.app/Contents/MacOS/Blender -b --python tools/blender/render_iso_sprites.py -- [--only bld_hq,bld_farm] [--samples 32]
Writes PNGs to HighwayHoldout_Iso_Art/png/, then import them with:
    python3 tools/import_art.py HighwayHoldout_Iso_Art/png --view iso

Camera: true 2:1 isometric (orthographic, 30 degrees above the ground, looking north-west), per docs/graphics-spec-iso.md.
Each canvas is exactly as wide as its footprint diamond, (w + h) * 128 px, and the diamond's bottom point is the bottom
middle of the canvas, which is the game's anchor. Models face +X in Blender = the map's +x = screen lower-right ("se")."""
import argparse, math, sys
from pathlib import Path
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
STUDY = REPO / 'HighwayHoldout_Blender_Study'
sys.path[:0] = [str(STUDY / 'scripts'), str(HERE)]
from geometry import init_materials, capture, point_camera  # noqa: E402
import buildings, props, characters, staging, extra_models   # noqa: E402

OUT = REPO / 'HighwayHoldout_Iso_Art' / 'png'
TILE_UNITS = 1.55          # study units per map tile (the HQ is ~4.6 units across its 3 tiles)
PX_PER_TILE_SUM = 128      # canvas width = (w + h) * 128 px
ELEVATION = math.radians(30)  # sin(30) = 0.5 -> diamonds exactly 2:1
FIT = 0.97                 # buildings fill this share of their footprint
TILE_EXPOSURE = -0.2       # ground renders a bit darker than objects (study default 0.5) so buildings stand out
FACING = {'se': 0, 'e': 45, 'ne': 90, 'n': 135, 's': -45}  # degrees about Z for a model that faces +X
UNIT_FACINGS = ('se', 'ne')                 # the game mirrors these for sw / nw
TURRET_FACINGS = ('e', 'se', 's', 'ne', 'n')  # mirrored for w / sw / nw

# name: (maker, footprint w, footprint h, kind). kind: 'fit' = scale to footprint, 'unit' = true scale + facings,
# 'tile' = ground tile at true scale on an exact 256x128 canvas.
MODELS = {
    'bld_hq': (buildings.hq, 3, 3, 'fit'), 'bld_shelter': (buildings.shelter, 2, 2, 'fit'),
    'bld_farm': (buildings.farm, 2, 2, 'fit'), 'bld_scavenger': (extra_models.scavenger, 2, 2, 'fit'),
    'bld_workshop': (extra_models.workshop, 2, 2, 'fit'), 'bld_barracks': (extra_models.barracks, 2, 2, 'fit'),
    'bld_storage': (extra_models.storage, 2, 2, 'fit'),
    'bld_construction_2x2': (lambda: extra_models.scaffold(2), 2, 2, 'fit'),
    'bld_construction_3x3': (lambda: extra_models.scaffold(3), 3, 3, 'fit'),
    'bld_rubble_2x2': (extra_models.rubble_2x2, 2, 2, 'fit'),
    'def_wall_wood': (props.wall, 1, 1, 'fit'), 'def_watchtower_base': (props.tower, 1, 1, 'fit'),
    'dec_car_wreck': (props.car, 2, 1, 'fit'), 'dec_tree_dead': (props.dead_tree, 1, 1, 'unit'),
    'dec_rubble': (extra_models.rubble_1x1, 1, 1, 'unit'),
    'unit_survivor': (lambda: characters.human(False), 1, 1, 'unit'),
    'unit_defender': (lambda: characters.human(True), 1, 1, 'unit'),
    'zmb_walker': (characters.zombie, 1, 1, 'unit'),
    'tile_grass': (lambda: extra_models.ground_tile('grass', 'grass'), 1, 1, 'tile'),
    'tile_dirt': (lambda: extra_models.ground_tile('dirt', 'pebbles'), 1, 1, 'tile'),
    'tile_asphalt': (lambda: extra_models.ground_tile('asphalt'), 1, 1, 'tile'),
    'tile_asphalt_line': (lambda: extra_models.ground_tile('asphalt', 'lane'), 1, 1, 'tile'),
    'tile_concrete': (lambda: extra_models.ground_tile('stone', 'cracks'), 1, 1, 'tile'),
}
GUNNER = (lambda: characters.human(True), 0.725, 2.08)  # maker, scale vs tower, deck height in tower units


def args():
    ap = argparse.ArgumentParser()
    ap.add_argument('--only', default='')
    ap.add_argument('--samples', type=int, default=32)
    return ap.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])


def bounds(col):
    pts = [o.matrix_world @ Vector(v) for o in col.all_objects if o.type == 'MESH' for v in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi


def place(scene, col, loc, scale, angle_deg):
    ob = bpy.data.objects.new('ISO ' + col.name, None)
    scene.collection.objects.link(ob)
    ob.instance_type, ob.instance_collection = 'COLLECTION', col
    ob.location, ob.scale, ob.rotation_euler[2] = loc, (scale,) * 3, math.radians(angle_deg)
    bpy.context.view_layer.update()
    return ob


def instance_points(ob):
    return [ob.matrix_world @ o.matrix_world @ Vector(v)
            for o in ob.instance_collection.all_objects if o.type == 'MESH' for v in o.bound_box]


def camera_axes():
    d = Vector((math.cos(ELEVATION) / math.sqrt(2), -math.cos(ELEVATION) / math.sqrt(2), math.sin(ELEVATION)))
    right = Vector((1, 1, 0)).normalized()
    up = d.cross(right).normalized() * -1 if d.cross(right).z < 0 else d.cross(right).normalized()
    return d, right, up


def render_group(scene, cam, w, h, frames, samples, margin=0.04):
    """frames: [(filename, [instance objects shown])]. All frames share one canvas so layers line up."""
    d, right, up = camera_axes()
    front = Vector((w / 2, -h / 2, 0))
    width_u = (w + h) / math.sqrt(2)
    back = Vector((-w / 2, h / 2, 0))
    top = max([(back - front).dot(up)] + [(p - front).dot(up) for _, obs in frames for ob in obs for p in instance_points(ob)])
    width_px = (w + h) * PX_PER_TILE_SUM
    k = width_px / width_u
    height_px = int(math.ceil((top + margin * width_u) * k / 8) * 8)
    cam.data.sensor_fit, cam.data.ortho_scale = 'HORIZONTAL', width_u
    cam.location = front + up * (height_px / k / 2) + d * 60
    point_camera(cam, cam.location - d)
    scene.render.resolution_x, scene.render.resolution_y = width_px, height_px
    scene.cycles.samples = samples
    every = {ob for _, obs in frames for ob in obs}
    for filename, shown in frames:
        for ob in every:
            ob.hide_render = ob not in shown
        scene.render.filepath = str(OUT / filename)
        print('RENDER', filename, width_px, 'x', height_px, flush=True)
        bpy.ops.render.render(write_still=True, scene=scene.name)


def main():
    opts = args()
    only = set(filter(None, opts.only.split(',')))
    OUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_homefile(use_empty=True)
    init_materials()
    scene = bpy.context.scene
    staging.setup(scene, transparent=True, samples=opts.samples)
    cam_data = bpy.data.cameras.new('iso camera')
    cam_data.type = 'ORTHO'
    cam = bpy.data.objects.new('iso camera', cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    for name, (maker, w, h, kind) in MODELS.items():
        if only and name not in only:
            continue
        col = capture(name, maker)
        bpy.context.scene.collection.children.unlink(col)
        lo, hi = bounds(col)
        scale = 1 / TILE_UNITS
        center = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, 0))
        if kind == 'fit':
            scale = min(scale, FIT * w / (hi.x - lo.x), FIT * h / (hi.y - lo.y))
        if kind == 'unit':
            facings = () if name.startswith('dec_') else UNIT_FACINGS  # decorations don't turn
            frames = [(f'{name}_{f}.png', [place(scene, col, (0, 0, 0), scale, FACING[f])]) for f in facings]
            frames.append((f'{name}.png', [place(scene, col, (0, 0, 0), scale, 0)]))
        else:
            base = place(scene, col, -center * scale, scale, 0)
            frames = [(f'{name}.png', [base])]
            if name == 'def_watchtower_base':
                maker_g, rel, deck = GUNNER
                gcol = capture('def_watchtower_gunner', maker_g)
                bpy.context.scene.collection.children.unlink(gcol)
                gloc = -center * scale + Vector((0, 0, deck * scale))
                frames += [(f'def_watchtower_gunner_{f}.png', [place(scene, gcol, gloc, scale * rel, FACING[f])])
                           for f in TURRET_FACINGS]
        scene.view_settings.exposure = TILE_EXPOSURE if kind == 'tile' else 0.5
        render_group(scene, cam, w, h, frames, opts.samples, margin=0 if kind == 'tile' else 0.04)
        for _, obs in frames:
            for ob in obs:
                bpy.data.objects.remove(ob, do_unlink=True)
    print('ISO_RENDER_COMPLETE', flush=True)


main()

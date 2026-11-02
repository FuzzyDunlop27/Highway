# Purpose: Makes the placeholder road textures (asphalt, lane lines, double yellow) and copies photo ground textures into App/Textures/Ground. Notes: docs/features/rendering-art.md
# Run: /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/make_ground_textures.py
# The asphalt is a darkened Poly Haven concrete_rock_path (no real asphalt was downloaded yet): replace road_*.jpg with
# real art any time, keeping the file names. Road images cover 2 × 2 tiles (presentation.json repeatTiles 2): painted
# lines sit at 1/4 and 3/4 of the image, i.e. in the middle of each tile row (east-west) or column (north-south).
import os

import bpy
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, 'HighwayHoldout_3D_Sources', 'free-assets', 'polyhaven', 'textures')
OUT = os.path.join(ROOT, 'App', 'Textures', 'Ground')
SIZE = 1024
PX_PER_TILE = SIZE // 2
LINE = 24  # px ≈ 0.11 m painted line
WHITE = (0.85, 0.85, 0.8)
YELLOW = (0.85, 0.65, 0.12)
ASPHALT_DARKEN = 0.42

# Photo textures copied as they are (slot file name: source file under polyhaven/textures/).
PHOTOS = {
    'vacant_lot_diff.jpg': 'brown_mud_leaves_01/textures/brown_mud_leaves_01_diff_1k.jpg',
    'garden_soil_diff.jpg': 'farm_soil_diff_1k.jpg',
}


def load(path):
    image = bpy.data.images.load(path)
    image.scale(SIZE, SIZE)
    return np.array(image.pixels[:], dtype=np.float32).reshape(SIZE, SIZE, 4)


def save(pixels, name):
    image = bpy.data.images.new(name, SIZE, SIZE)
    image.pixels = pixels.ravel()
    image.filepath_raw = os.path.join(OUT, name)
    image.file_format = 'JPEG'
    bpy.context.scene.render.image_settings.quality = 85
    image.save()
    print('TEXTURE', name)


def asphalt():
    px = load(os.path.join(SRC, 'concrete_rock_path_diff_1k.jpg'))
    grey = px[..., :3].mean(axis=2, keepdims=True)
    px[..., :3] = (grey * 0.7 + px[..., :3] * 0.3) * ASPHALT_DARKEN  # mostly grey, a little of the stone colour
    return px


def paint(px, centre, colour, along_rows, dash=None):
    """A painted line `LINE` px wide at `centre` px; rows = east-west line. `dash` = (on, period) px along the line."""
    half = LINE // 2
    band = slice(centre - half, centre + half)
    mask = np.ones(SIZE, dtype=bool)
    if dash:
        mask = (np.arange(SIZE) % dash[1]) < dash[0]
    rgb = np.array(colour, dtype=np.float32)
    if along_rows:
        px[band, mask, :3] = rgb
    else:
        px[mask, band, :3] = rgb


def main():
    os.makedirs(OUT, exist_ok=True)
    base = asphalt()
    save(base.copy(), 'road_asphalt.jpg')
    centres = (PX_PER_TILE // 2, PX_PER_TILE + PX_PER_TILE // 2)
    lane = base.copy()
    for c in centres:
        paint(lane, c, WHITE, True, dash=(int(PX_PER_TILE * 0.6), SIZE))
    save(lane, 'road_lane_ew.jpg')
    for name, rows in (('road_center_ew.jpg', True), ('road_center_ns.jpg', False)):
        centre = base.copy()
        for c in centres:
            paint(centre, c - LINE, YELLOW, rows)
            paint(centre, c + LINE, YELLOW, rows)
        save(centre, name)
    for name, source in PHOTOS.items():
        save(load(os.path.join(SRC, source)), name)


main()

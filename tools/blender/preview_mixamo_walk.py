# Purpose: Compares rendered Mixamo frames and makes a four-facing preview. Notes: docs/features/zombie-walk-mixamo.md
"""python preview_mixamo_walk.py ART_FOLDER [--test]
Needs Pillow. Composites render output only; never paints or alters production PNGs.
"""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps

REPO = Path(__file__).resolve().parents[2]
OLD = REPO / 'HighwayHoldout_Iso_Art/realistic-walker/png'
SIZE = (256, 232)


def panel(image, label):
    canvas = Image.new('RGB', (256, 260), '#353c37')
    canvas.paste(image, (0, 24), image)
    draw = ImageDraw.Draw(canvas)
    draw.text((8, 6), label, fill='white')
    draw.line((0, 208, 255, 208), fill='#e6b75c')
    return canvas


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('folder', type=Path)
    parser.add_argument('--test', action='store_true')
    opts = parser.parse_args()
    png = opts.folder / 'png'
    current = Image.open(png / 'zmb_walker_se_w0.png').convert('RGBA')
    previous = Image.open(OLD / 'zmb_walker_se.png').convert('RGBA')
    overlay = Image.blend(previous, current, .5)
    compare = Image.new('RGB', (768, 260))
    for i, (img, label) in enumerate([(previous, 'Previous still'), (current, 'Mixamo frame 0'),
                                     (overlay, '50% overlay; gold = baseline')]):
        compare.paste(panel(img, label), (i * 256, 0))
    compare.save(opts.folder / ('test-compare.png' if opts.test else 'compare.png'))
    if opts.test:
        return
    animation = []
    for index in range(6):
        views = []
        for facing in ('se', 'ne'):
            img = Image.open(png / f'zmb_walker_{facing}_w{index}.png').convert('RGBA')
            assert img.size == SIZE
            bounds = img.getbbox()
            assert bounds and bounds[0] > 0 and bounds[1] > 0 and bounds[2] < SIZE[0] and bounds[3] < SIZE[1]
            views += [panel(img, facing.upper()), panel(ImageOps.mirror(img), {'se':'SW','ne':'NW'}[facing])]
        sheet = Image.new('RGB', (1024, 260))
        for i, view in enumerate(views):
            sheet.paste(view, (i*256, 0))
        animation.append(sheet)
    # Match preview tempo to the configured walker speed.
    metadata = json.loads((opts.folder / "render-metadata.json").read_text())
    zombies = json.loads((REPO / "Content/zombies.json").read_text())["zombies"]
    speed = next(z["speed"] for z in zombies if z["id"] == "walker")
    duration = round(metadata["strideTiles"] / speed / 6 * 1000)
    animation[0].save(opts.folder / 'preview.gif', save_all=True, append_images=animation[1:],
                      duration=duration, loop=0, disposal=2)
    print('Preview verified: twelve transparent 256x232 frames with clear borders.')


if __name__ == '__main__':
    main()

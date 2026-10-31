# Purpose: Fit approved realistic walker cutouts onto matching game canvases. Notes: docs/features/rendering-art.md
from pathlib import Path
from PIL import Image, ImageDraw
import shutil

ROOT = Path(__file__).resolve().parent
# Existing walker canvas and approximate height. Footprint center is 64 px above bottom.
CANVAS = (256, 232)
HEIGHT = 160
BOTTOM = 184
for facing in ('se', 'ne'):
    source = Image.open(ROOT / 'source' / f'walker-{facing}.png').convert('RGBA')
    # Use existing generated alpha; no background removal, painting or creative edits.
    bounds = source.getchannel('A').getbbox()
    body = source.crop(bounds)
    body = body.resize((round(body.width * HEIGHT / body.height), HEIGHT), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', CANVAS)
    canvas.alpha_composite(body, ((CANVAS[0] - body.width) // 2, BOTTOM - HEIGHT))
    canvas.save(ROOT / 'png' / f'zmb_walker_{facing}.png')
shutil.copyfile(ROOT / 'png/zmb_walker_se.png', ROOT / 'png/zmb_walker.png')

# Preview on terrain-colored backing: large cutouts plus actual sprite scale.
preview = Image.new('RGB', (1000, 850), '#303b35')
draw = ImageDraw.Draw(preview)
for col, facing in enumerate(('se', 'ne')):
    cutout = Image.open(ROOT / 'source' / f'walker-{facing}.png').convert('RGBA')
    cutout = cutout.crop(cutout.getchannel('A').getbbox())
    cutout.thumbnail((420, 660), Image.Resampling.LANCZOS)
    preview.paste(cutout, (col * 500 + (500-cutout.width)//2, 35), cutout)
    draw.text((col*500+150, 710), 'FRONT / SOUTHEAST' if facing == 'se' else 'BACK / NORTHEAST', fill='white')
    sprite = Image.open(ROOT / 'png' / f'zmb_walker_{facing}.png')
    sprite.thumbnail((128,116), Image.Resampling.LANCZOS)
    preview.paste(sprite, (col*500+190,725),sprite)
preview.save(ROOT / 'preview.png')
for path in (ROOT/'png').glob('*.png'):
    im=Image.open(path)
    assert im.size == CANVAS and im.mode == 'RGBA'
    b=im.getbbox()
    assert b and b[0]>0 and b[1]>0 and b[2]<im.width and b[3]<im.height
    assert im.getpixel((0,0))[3] == 0
    print(path.name, im.size, b)

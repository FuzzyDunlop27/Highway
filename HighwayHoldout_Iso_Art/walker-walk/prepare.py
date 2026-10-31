# Purpose: Slice generated walker poses onto the existing sprite canvas. Notes: docs/features/zombie-walk-animation.md
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
frames_by_facing = {}
for facing in ('se', 'ne'):
    sheet = Image.open(ROOT / 'source' / f'walker-{facing}-sheet.png').convert('RGBA')
    cells = [sheet.crop((c * sheet.width // 3, r * sheet.height // 2,
                         (c + 1) * sheet.width // 3, (r + 1) * sheet.height // 2))
             for r in range(2) for c in range(3)]
    # One scale for the entire cycle. Never independently fit/stretch individual poses.
    bounds = [cell.getchannel('A').getbbox() for cell in cells]
    assert all(bounds)
    scale = 160 / max(b[3] - b[1] for b in bounds)
    frames = []
    for index, (cell, b) in enumerate(zip(cells, bounds)):
        crop = cell.crop(b)
        crop = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
        frame = Image.new('RGBA', (256, 232))
        frame.alpha_composite(crop, ((256 - crop.width) // 2, 184 - crop.height))
        frame.save(ROOT / 'png' / f'zmb_walker_{facing}_w{index}.png')
        box = frame.getbbox()
        assert box and 0 < box[0] < box[2] < 256 and 0 < box[1] < box[3] < 232
        frames.append(frame)
    assert len({f.tobytes() for f in frames}) == 6
    frames_by_facing[facing] = frames
# Review at enlarged scale; also include mirrored facings, without changing any game assets.
preview = []
for i in range(6):
    panel = Image.new('RGB', (1024, 464), '#303b35')
    for col, facing in enumerate(('se', 'ne')):
        frame = frames_by_facing[facing][i]
        for mirror in (False, True):
            f = frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if mirror else frame
            panel.paste(f, (col * 512 + int(mirror) * 256, 116), f)
    preview.append(panel)
preview[0].save(ROOT / 'preview.gif', save_all=True, append_images=preview[1:], duration=170, loop=0)
print('12 unique transparent frames checked; shared 256x232 canvas; four-facing preview saved.')

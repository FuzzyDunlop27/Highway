#!/usr/bin/env python3
"""Rebuild the 8-bit-inspired pack from source layouts and integer-grid drawings."""
from PIL import Image, ImageDraw
import json
from pixel_core import ROOT,M,P,RGB,palette_map,save
from pixel_units import CUSTOM as UNITS
from pixel_world import CUSTOM as WORLD
from pixel_defenses import CUSTOM as DEFENSES

custom={**UNITS,**WORLD,**DEFENSES}
masters={}
for a in M['assets']:
    n=a['name']
    if n=='app_icon':continue
    if n in custom:
        im=custom[n]()
    else:
        im=palette_map(Image.open(ROOT/'reference/layout_rasters'/a['filename']))
    if n=='app_icon_bg':
        d=ImageDraw.Draw(im)
        # Sparse fixed pixels in the dusk sky, not noise across the whole image.
        for x,y in [(12,13),(39,9),(59,21),(83,7),(114,16),(69,35)]:
            d.point((x,y),fill=(*RGB['light'],255))
        d.line([(10,27),(11,27)],fill=(*RGB['metal'],255))
    # Preserve at least one logical pixel of transparency around sprites.
    if not a['opaque'] and not n.startswith('app_icon'):
        d=ImageDraw.Draw(im)
        d.rectangle((0,0,im.width-1,0),fill=(0,0,0,0))
        d.rectangle((0,im.height-1,im.width-1,im.height-1),fill=(0,0,0,0))
        d.rectangle((0,0,0,im.height-1),fill=(0,0,0,0))
        d.rectangle((im.width-1,0,im.width-1,im.height-1),fill=(0,0,0,0))
    masters[n]=im
    save(a,im)
icon=Image.alpha_composite(masters['app_icon_bg'],masters['app_icon_fg'])
save(next(a for a in M['assets'] if a['name']=='app_icon'),icon)
M.update(title='Highway Holdout — 8-bit edition',version='2.0.0',
    rendering='Nearest-neighbor; 32 logical pixels per world tile; binary alpha',
    hardware_note='8-bit-inspired aesthetic; not an NES hardware/palette emulator')
(ROOT/'manifest.json').write_text(json.dumps(M,indent=2)+'\n')
print('Created 57 pixel-art PNGs, native pixel masters and editable pixel SVGs.')

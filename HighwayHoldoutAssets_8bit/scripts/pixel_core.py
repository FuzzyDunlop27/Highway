"""Shared integer-grid drawing, palette mapping and editable pixel SVG export."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageCms
import json

ROOT=Path(__file__).resolve().parents[1]
M=json.loads((ROOT/'reference/base_manifest.json').read_text())
P=M['palette']
RGB={k:tuple(bytes.fromhex(v[1:])) for k,v in P.items()}
ICC=ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()

class Canvas:
    def __init__(self,w=32,h=32,bg=None):
        self.im=Image.new('RGBA',(w,h),(*RGB[bg],255) if bg else (0,0,0,0))
        self.d=ImageDraw.Draw(self.im)
    def rect(self,box,c): self.d.rectangle(box,fill=(*RGB[c],255))
    def poly(self,pts,c): self.d.polygon(pts,fill=(*RGB[c],255))
    def line(self,pts,c,w=1): self.d.line(pts,fill=(*RGB[c],255),width=w)
    def dot(self,x,y,c): self.rect((x,y,x,y),c)
    def oval(self,box,c): self.d.ellipse(box,fill=(*RGB[c],255))

def palette_map(im):
    """Convert vector layout samples to solid palette pixels with binary alpha."""
    im=im.convert('RGBA');out=Image.new('RGBA',im.size)
    cache={}; colors=list(RGB.values()); px=[]
    for r,g,b,a in im.getdata():
        if a<112: px.append((0,0,0,0));continue
        key=(r,g,b)
        if key not in cache:
            cache[key]=min(colors,key=lambda c:2*(r-c[0])**2+3*(g-c[1])**2+(b-c[2])**2)
        px.append((*cache[key],255))
    out.putdata(px)
    return out

def pixel_svg(im,w,h):
    """Runs of native pixels are editable SVG rectangles; no embedded bitmap."""
    p=im.convert('RGBA'); rows=[]
    for y in range(p.height):
        x=0
        while x<p.width:
            color=p.getpixel((x,y));end=x+1
            while end<p.width and p.getpixel((end,y))==color:end+=1
            if color[3]:
                fill='#'+bytes(color[:3]).hex().upper()
                rows.append(f'<rect x="{x}" y="{y}" width="{end-x}" height="1" fill="{fill}"/>')
            x=end
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {im.width} {im.height}" shape-rendering="crispEdges">'+''.join(rows)+'</svg>'

def save(a,im):
    name=a['name'];w,h=a['width'],a['height']
    for folder in ['png','pixel_masters','source_svg']: (ROOT/folder).mkdir(exist_ok=True)
    im=im.convert('RGBA')
    if a['opaque']: im=im.convert('RGB')
    im.save(ROOT/'pixel_masters'/a['filename'],icc_profile=ICC)
    im.resize((w,h),Image.Resampling.NEAREST).save(ROOT/'png'/a['filename'],icc_profile=ICC)
    (ROOT/'source_svg'/f'{name}.svg').write_text(pixel_svg(im,w,h))
    a.update(logical_width=im.width,logical_height=im.height,pixel_scale=w//im.width,
             filtering='nearest',alpha_mode='opaque' if a['opaque'] else 'binary',
             style='8-bit-inspired pixel art')
    a.pop('sha256',None)

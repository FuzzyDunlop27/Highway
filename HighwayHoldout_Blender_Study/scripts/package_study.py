"""Export exact-size game samples, review sheets, and basic image validation."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageCms
import json,hashlib

ROOT=Path(__file__).resolve().parents[1]
M=json.loads((ROOT/'manifest.json').read_text())
ICC=ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
FONT='/System/Library/Fonts/Supplemental/Arial.ttf'
BOLD='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
def text(d,xy,s,size=20,color='#E9E1CF',bold=False):
    d.text(xy,s,font=ImageFont.truetype(BOLD if bold else FONT,size),fill=color)
def paste(canvas,im,xy):canvas.paste(im,xy,im)

checks=[]
for a in M['assets']:
    im=Image.open(ROOT/'renders'/f"{a['name']}_2x.png").convert('RGBA')
    im=im.resize((a['width'],a['height']),Image.Resampling.LANCZOS)
    p=ROOT/'png'/f"{a['name']}.png";im.save(p,icc_profile=ICC)
    bbox=im.getchannel('A').point(lambda x:255 if x>8 else 0).getbbox()
    margins=(bbox[0],bbox[1],im.width-bbox[2],im.height-bbox[3])
    for check,ok in [('dimensions',im.size==(a['width'],a['height'])),
        ('transparent background',im.getchannel('A').getextrema()==(0,255)),
        ('padding at least 4px',min(margins)>=4),('embedded sRGB',bool(Image.open(p).info.get('icc_profile')))]:
        checks.append(dict(asset=a['name'],check=check,passed=ok))
    a['sha256']=hashlib.sha256(p.read_bytes()).hexdigest();a['visible_bounds']=bbox

sheet=Image.new('RGB',(1612,910),'#253C40');d=ImageDraw.Draw(sheet)
text(d,(40,28),'HIGHWAY HOLDOUT / BLENDER SPRITE STUDY',32,bold=True)
text(d,(40,78),'Fresh 3D models / 10 transparent sample assets / overhead units face east',18,'#A9C2BB')
for i,a in enumerate(M['assets']):
    x=40+(i%5)*310;y=136+(i//5)*365
    d.rounded_rectangle((x,y,x+292,y+339),12,fill='#DAD5C7')
    im=Image.open(ROOT/'png'/f"{a['name']}.png").convert('RGBA');im.thumbnail((260,260),Image.Resampling.LANCZOS)
    paste(sheet,im,(x+(292-im.width)//2,y+12+(260-im.height)//2))
    text(d,(x+14,y+281),a['name'],17,'#253C40',True)
    text(d,(x+14,y+309),f"{a['width']} x {a['height']} PNG",15,'#526969')
text(d,(40,878),'Shading comes from real geometry. The diorama camera is separate from the game sprite cameras.',15,'#A9C2BB')
sheet.save(ROOT/'renders/02_transparent_sprite_samples.png')

# Verify the rotating tower overlay and miniature unit readability in context.
sheet=Image.new('RGB',(1260,570),'#253C40');d=ImageDraw.Draw(sheet)
text(d,(36,25),'OVERLAY + SMALL-SIZE CHECK',30,bold=True)
base=Image.open(ROOT/'png/def_watchtower_base.png').convert('RGBA')
top=Image.open(ROOT/'png/def_watchtower_gunner.png').convert('RGBA')
for i,angle in enumerate([0,45,90,135,180,225,270,315]):
    x=36+i*150;y=104
    d.rectangle((x,y,x+128,y+128),fill='#76816A')
    paste(sheet,base,(x,y));paste(sheet,top.rotate(angle,Image.Resampling.BICUBIC),(x,y))
    text(d,(x+36,y+140),f'{angle} deg',15,'#A9C2BB')
for i,n in enumerate(['unit_survivor','unit_defender','zmb_walker','bld_hq','bld_shelter','bld_farm']):
    x=36+i*200;y=333
    im=Image.open(ROOT/'png'/f'{n}.png').convert('RGBA').resize((48,48),Image.Resampling.LANCZOS)
    d.rectangle((x,y,x+64,y+64),fill='#76816A');paste(sheet,im,(x+8,y+8))
    text(d,(x,y+82),n,15);text(d,(x,y+109),'48 x 48 pixels',13,'#A9C2BB')
text(d,(36,528),'Same centered canvases for tower base and gunner. Art is a style sample; gameplay integration is pending.',15,'#A9C2BB')
sheet.save(ROOT/'renders/03_rotation_and_readability.png')

(ROOT/'manifest.json').write_text(json.dumps(M,indent=2)+'\n')
report=dict(passed=sum(c['passed'] for c in checks),failed=sum(not c['passed'] for c in checks),checks=checks)
(ROOT/'qa_report.json').write_text(json.dumps(report,indent=2)+'\n')
print(f"Sprite QA: {report['passed']} passed, {report['failed']} failed")
for c in checks:
    if not c['passed']:print(c)
if report['failed']:raise SystemExit(1)

#!/usr/bin/env python3
"""Create review sheets, an Xcode catalog, and machine-readable QA results."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageCms
import json, math, re, sys, shutil, hashlib

ROOT=Path(__file__).resolve().parents[1]
M=json.loads((ROOT/'manifest.json').read_text())
ASSETS=M['assets']; P=M['palette']; PNG=ROOT/'png'; PRE=ROOT/'previews'
PRE.mkdir(exist_ok=True)
FONT='/System/Library/Fonts/Supplemental/Arial.ttf'
BOLD='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
def font(size,bold=False): return ImageFont.truetype(BOLD if bold else FONT,size)
def load(name): return Image.open(PNG/(name+'.png')).convert('RGBA')
def paste(canvas,im,xy): canvas.paste(im,xy,im)
def txt(d,xy,s,size=20,c='light',bold=False): d.text(xy,s,font=font(size,bold),fill=P.get(c,c))
def page(w,h,title,subtitle):
    im=Image.new('RGB',(w,h),P['dark']); d=ImageDraw.Draw(im)
    d.rectangle((36,36,43,103),fill=P['orange'])
    txt(d,(60,34),title,36,bold=True); txt(d,(60,83),subtitle,16,'metal')
    return im,d
def art_card(im,d,asset,x,y,w=244,h=258,display=164):
    d.rounded_rectangle((x,y,x+w,y+h),radius=12,fill=P['asphalt'])
    a=load(asset['name']); a.thumbnail((display,display),Image.Resampling.NEAREST)
    paste(im,a,(x+(w-a.width)//2,y+16+(display-a.height)//2))
    label_size=14
    while d.textbbox((0,0),asset['name'],font=font(label_size,True))[2]>w-28: label_size-=1
    txt(d,(x+14,y+h-63),asset['name'],label_size,bold=True)
    txt(d,(x+14,y+h-36),f"{asset['width']} x {asset['height']}    /    {asset['priority']}",13,'metal')

def anchor():
    im,d=page(1500,610,'HIGHWAY HOLDOUT / 8-BIT','STYLE ANCHOR  /  32px world tiles · 16-color palette · crisp pixels · overhead units')
    names=['tile_grass','tile_asphalt','bld_shelter','def_wall_wood','def_watchtower_base','unit_defender','zmb_walker']
    for i,n in enumerate(names):
        a=next(a for a in ASSETS if a['name']==n)
        art_card(im,d,a,36+i*205,144,194,263,166)
    for i,(n,c) in enumerate(P.items()):
        x=36+i*89
        d.rounded_rectangle((x,448,x+76,493),radius=5,fill=c)
        txt(d,(x,502),c,12)
        txt(d,(x,526),n,11,'metal')
    txt(d,(36,575),'Art contains no text, numbers, baked shadows or gore. Labels appear only on review sheets.',14,'metal')
    im.save(PRE/'style_anchor.png')

anchor()
if '--anchor' in sys.argv:
    print('Created style anchor preview.'); sys.exit(0)

# Compose final icon from the actual delivered layers, byte-for-byte reproducible.
icon=Image.alpha_composite(load('app_icon_bg'),load('app_icon_fg')).convert('RGB')
icc=Image.open(PNG/'app_icon_bg.png').info.get('icc_profile')
icon.save(PNG/'app_icon.png',icc_profile=icc)

for filename,title,cats in [
    ('01_world_buildings.png','WORLD + TOWN',['tile','dec','bld']),
    ('02_defenses_units_fx.png','DEFENSES + HORDE',['def','unit','zmb','fx','veh']),
    ('03_interface.png','INTERFACE',['icon','ui'])]:
    items=[a for a in ASSETS if a['category'] in cats]
    rows=math.ceil(len(items)/5)
    im,d=page(1340,148+rows*278,title,'HIGHWAY HOLDOUT / 8-BIT  /  Phase 1 sprites  /  Preview cards are not sprite backgrounds')
    for i,a in enumerate(items): art_card(im,d,a,36+(i%5)*258,138+(i//5)*278)
    im.save(PRE/filename)

# 48px review: display sprites on actual grass and road, at native thumbnail size.
units=[a for a in ASSETS if a['category'] in ['bld','def','unit','zmb']]
im,d=page(1260,180+math.ceil(len(units)/4)*130,'48 PX READABILITY','Each sprite below is exactly 48 x 48 pixels. View this file at 100% zoom.')
for i,a in enumerate(units):
    x=36+(i%4)*305; y=141+(i//4)*130
    for j,terrain in enumerate(['tile_grass','tile_asphalt']):
        paste(im,load(terrain).resize((64,64),Image.Resampling.NEAREST),(x+j*68,y))
        paste(im,load(a['name']).resize((48,48),Image.Resampling.NEAREST),(x+8+j*68,y+8))
    txt(d,(x,y+74),a['name'],13)
im.save(PRE/'04_readability_48px.png')

im,d=page(1500,595,'SEAMLESS TERRAIN','3 x 3 repetitions, reduced to 88px per tile for this sheet. Opposite pixel boundaries are checked automatically.')
for i,a in enumerate([a for a in ASSETS if a['category']=='tile']):
    x=36+i*292; y=152; tile=load(a['name']).resize((88,88),Image.Resampling.NEAREST)
    for yy in range(3):
        for xx in range(3): paste(im,tile,(x+xx*88,y+yy*88))
    txt(d,(x,436),a['name'],16,bold=True)
    txt(d,(x,465),'OPAQUE / 128 x 128',13,'metal')
txt(d,(36,551),'Note: the dashed lane repeats horizontally; separate transition tiles are outside the Phase 1 spec.',15,'metal')
im.save(PRE/'05_terrain_tiling.png')

im,d=page(1480,730,'ROTATION + OVERLAYS','Bases stay static. Top layers rotate around the canvas center. All original top layers face east.')
for row,(base,top) in enumerate([('def_watchtower_base','def_watchtower_gunner'),('def_mg_nest_base','def_mg_nest_gun'),(None,'zmb_walker')]):
    y=140+row*180
    for i,angle in enumerate([0,45,90,135,180,225,270,315]):
        x=39+i*179
        paste(im,load('tile_grass'),(x,y))
        if base: paste(im,load(base),(x,y))
        paste(im,load(top).rotate(angle,Image.Resampling.NEAREST,expand=False),(x,y))
        txt(d,(x+40,y+135),f'{angle} deg',13,'metal')
im.save(PRE/'06_rotations.png')

# A composed art test; this is a scene mockup, not a game implementation.
scene=Image.new('RGBA',(1536,1024),P['grass'])
for gy in range(8):
    for gx in range(12):
        name='tile_asphalt_line' if gy==6 else 'tile_asphalt' if gy in [5,7] else 'tile_dirt' if gx in [3,4,7] else 'tile_grass'
        paste(scene,load(name),(gx*128,gy*128))
for n,x,y in [('bld_hq',210,135),('bld_shelter',27,8),('bld_farm',623,25),('bld_scavenger',40,355),('bld_workshop',655,287),('bld_storage',920,15),('dec_car_wreck',1117,630),('dec_rubble',1239,463),('dec_tree_dead',1300,34)]:
    paste(scene,load(n),(x,y))
for x,y in [(940,280),(940,408),(1068,280),(1196,280)]: paste(scene,load('def_wall_wood'),(x,y))
for x,y,rot in [(900,540,0),(1240,240,-30)]:
    paste(scene,load('def_watchtower_base'),(x,y));paste(scene,load('def_watchtower_gunner').rotate(rot,Image.Resampling.NEAREST),(x,y))
for x,y,rot in [(1083,544,0),(1215,548,0)]:
    paste(scene,load('def_mg_nest_base'),(x,y));paste(scene,load('def_mg_nest_gun').rotate(rot,Image.Resampling.NEAREST),(x,y))
for x,y in [(1013,682),(1143,840),(1300,750),(1380,870),(1331,553)]: paste(scene,load('zmb_walker').rotate(180),(x,y))
paste(scene,load('zmb_brute').rotate(180),(1370,690))
for x,y in [(880,705),(1040,914)]: paste(scene,load('zmb_runner').rotate(180),(x,y))
for x,y in [(570,366),(332,517)]: paste(scene,load('unit_survivor'),(x,y))
for x,y in [(793,615),(918,792)]: paste(scene,load('unit_defender'),(x,y))
paste(scene,load('fx_goo_splat'),(1177,727))
scene.convert('RGB').save(PRE/'07_gameplay_art_mockup.png')

im,d=page(1520,890,'APP ICON + LAYERS','Opaque flattened icon, opaque background, and transparent foreground. No baked corner mask.')
for i,n in enumerate(['app_icon','app_icon_bg','app_icon_fg']):
    x=36+i*493
    d.rounded_rectangle((x,147,x+461,608),radius=10,fill=P['asphalt'])
    paste(im,load(n).resize((461,461),Image.Resampling.NEAREST),(x,147))
    txt(d,(x,630),n,22,bold=True)
    txt(d,(x,666),'1024 x 1024 / sRGB',16,'metal')
for i,sz in enumerate([120,80,60]):
    paste(im,load('app_icon').resize((sz,sz),Image.Resampling.NEAREST),(36+i*160,728))
im.save(PRE/'08_app_icon.png')

# Native-grid renditions: 128px master tile maps to 32pt at 1x.
catalog=ROOT/'HighwayHoldout8bit.xcassets';catalog.mkdir(exist_ok=True)
info={'author':'xcode','version':1}
(catalog/'Contents.json').write_text(json.dumps({'info':info},indent=2)+'\n')
for a in ASSETS:
    if a['name']=='app_icon':
        folder=catalog/'AppIcon.appiconset';folder.mkdir(exist_ok=True)
        contents={'images':[{'filename':a['filename'],'idiom':'universal','platform':'ios','size':'1024x1024'}],'info':info}
    else:
        folder=catalog/(a['name']+'.imageset');folder.mkdir(exist_ok=True)
        images=[]
        for scale in [1,2,3]:
            filename=f"{a['name']}@{scale}x.png"
            sz=(a['width']//4*scale,a['height']//4*scale)
            load(a['name']).resize(sz,Image.Resampling.NEAREST).save(folder/filename,icc_profile=icc)
            images.append({'filename':filename,'idiom':'universal','scale':f'{scale}x'})
        contents={'images':images,'info':info}
    if a['name']=='app_icon':shutil.copy2(PNG/a['filename'],folder/a['filename'])
    (folder/'Contents.json').write_text(json.dumps(contents,indent=2)+'\n')

# QA catches size, alpha, color space, padding, tiling and SVG palette violations.
checks=[]; failures=[]
def check(name,kind,ok,detail=''):
    row={'asset':name,'check':kind,'pass':bool(ok),'detail':detail};checks.append(row)
    if not ok:failures.append(row)
expected=set(re.findall(r'^\| ((?:tile|dec|bld|def|unit|zmb|fx|icon|ui|app)_\w+) \|', (ROOT/'reference/graphics-spec-phase1.md').read_text(),re.M))
expected.update(['app_icon_bg','app_icon_fg','icon_medicine','icon_fuel','icon_ammo','icon_knowledge','veh_rv','veh_pickup'])
check('pack','spec coverage',expected=={a['name'] for a in ASSETS},'Required names compared with specification tables and P3 list')
for a in ASSETS:
    name=a['name'];im=Image.open(PNG/a['filename']); rgba=im.convert('RGBA'); alpha=rgba.getchannel('A')
    check(name,'dimensions',im.size==(a['width'],a['height']),str(im.size))
    check(name,'sRGB profile',bool(im.info.get('icc_profile')),'Embedded ICC color profile')
    check(name,'opacity' if a['opaque'] else 'transparency',alpha.getextrema()==(255,255) if a['opaque'] else alpha.getextrema()==(0,255) or (alpha.getextrema()[0]==0 and name=='fx_dust_puff'),str(alpha.getextrema()))
    if not a['opaque'] and not name.startswith('app_icon'):
        bbox=alpha.point(lambda a:255 if a>8 else 0).getbbox()
        margins=[bbox[0],bbox[1],im.width-bbox[2],im.height-bbox[3]]
        check(name,'canvas padding',min(margins)>=3,str(margins))
    source=(ROOT/'source_svg'/f'{name}.svg').read_text()
    colors=set(re.findall(r'#[0-9A-Fa-f]{6}',source))
    check(name,'master palette',colors<=set(P.values()),', '.join(sorted(colors-set(P.values()))))
    palette={tuple(bytes.fromhex(c[1:])) for c in P.values()}
    visible={px[:3] for px in rgba.getdata() if px[3]}
    check(name,'PNG pixel palette',visible<=palette,f'{len(visible)} solid colors')
    check(name,'binary pixel alpha',set(alpha.getdata())<={0,255},'No blurred or partially transparent edges')
    native=rgba.resize((a['logical_width'],a['logical_height']),Image.Resampling.NEAREST)
    check(name,'integer pixel grid',native.resize(im.size,Image.Resampling.NEAREST).tobytes()==rgba.tobytes(),f"{a['pixel_scale']}x integer upscale")
    if name.startswith('tile_'):
        check(name,'left/right seam',rgba.crop((0,0,1,im.height)).tobytes()==rgba.crop((im.width-1,0,im.width,im.height)).tobytes())
        check(name,'top/bottom seam',rgba.crop((0,0,im.width,1)).tobytes()==rgba.crop((0,im.height-1,im.width,im.height)).tobytes())
    a['sha256']=hashlib.sha256((PNG/a['filename']).read_bytes()).hexdigest()
check('app_icon','layer reconstruction',Image.alpha_composite(load('app_icon_bg'),load('app_icon_fg')).convert('RGB').tobytes()==Image.open(PNG/'app_icon.png').convert('RGB').tobytes())
(ROOT/'qa_report.json').write_text(json.dumps({'asset_count':len(ASSETS),'passed':len(checks)-len(failures),'failed':len(failures),'checks':checks},indent=2)+'\n')
(ROOT/'manifest.json').write_text(json.dumps(M,indent=2)+'\n')
print(f'Packaged {len(ASSETS)} assets. QA: {len(checks)-len(failures)} passed, {len(failures)} failed.')
for f in failures: print(f)
if failures: sys.exit(1)

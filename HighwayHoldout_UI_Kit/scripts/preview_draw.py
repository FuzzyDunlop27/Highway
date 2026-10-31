"""Preview compositor: actual reusable assets, live text, correct nine-slice scaling."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageFilter,ImageOps
import json,textwrap
ROOT=Path(__file__).resolve().parents[1]
P=json.loads((ROOT/'design_tokens.json').read_text())['colors']
META={a['name']:a for a in json.loads((ROOT/'reference/vector_assets.json').read_text())}
FONT='/System/Library/Fonts/Avenir Next.ttc'
def font(size,weight='regular'):return ImageFont.truetype(FONT,size,index={'regular':7,'medium':5,'demi':2,'bold':0}[weight])
def text(im,xy,s,size=26,color='ink',weight='regular',anchor=None):
    ImageDraw.Draw(im).text(xy,s,font=font(size,weight),fill=P.get(color,color),anchor=anchor)
def line(im,box,color='edge',width=1):ImageDraw.Draw(im).line(box,fill=P.get(color,color),width=width)
def roundbox(im,box,r=20,fill='white',outline=None,width=1):
    ImageDraw.Draw(im).rounded_rectangle(box,r,fill=P.get(fill,fill),outline=P.get(outline,outline),width=width)
def paste(im,overlay,xy):im.alpha_composite(overlay.convert('RGBA'),(int(xy[0]),int(xy[1])))
def load(name):return Image.open(ROOT/'png'/f'{name}.png').convert('RGBA')
def art(im,name,box):
    x,y,w,h=box;a=load(name);a.thumbnail((int(w),int(h)),Image.Resampling.LANCZOS)
    paste(im,a,(x+(w-a.width)/2,y+(h-a.height)/2))
def glyph(im,name,x,y,size=36,color='ink'):
    a=load('ui_glyph_'+name).resize((size,size),Image.Resampling.LANCZOS)
    out=Image.new('RGBA',a.size,P.get(color,color));out.putalpha(a.getchannel('A'));paste(im,out,(x,y))
def surface(im,name,box,scale=2):
    x,y,w,h=map(int,box);a=load(name);caps=META[name].get('cap_insets_pt')
    if not caps:paste(im,a.resize((w,h),Image.Resampling.LANCZOS),(x,y));return
    l,t,r,b=[round(caps[k]*2) for k in ['left','top','right','bottom']]
    dl,dt,dr,db=[round(caps[k]*scale) for k in ['left','top','right','bottom']]
    sx=[0,l,a.width-r,a.width];sy=[0,t,a.height-b,a.height]
    dx=[0,dl,w-dr,w];dy=[0,dt,h-db,h]
    out=Image.new('RGBA',(w,h))
    for iy in range(3):
        for ix in range(3):
            tw,th=dx[ix+1]-dx[ix],dy[iy+1]-dy[iy]
            if tw<=0 or th<=0 or sx[ix+1]<=sx[ix] or sy[iy+1]<=sy[iy]:continue
            crop=a.crop((sx[ix],sy[iy],sx[ix+1],sy[iy+1])).resize((tw,th),Image.Resampling.LANCZOS)
            out.alpha_composite(crop,(dx[ix],dy[iy]))
    paste(im,out,(x,y))
def button(im,box,label,kind='primary',state='normal',icon=None,size=27):
    surface(im,f'ui_button_{kind}_{state}',box)
    x,y,w,h=box;col='muted' if state=='disabled' else 'ink' if kind=='secondary' else 'white'
    text(im,(x+w/2+(12 if icon else 0),y+h/2-4),label,size,col,'demi','mm')
    if icon:glyph(im,icon,x+25,y+h/2-20,32,col)
def paragraph(im,xy,s,width,size=25,color='muted',leading=36):
    words=s.split();row='';y=xy[1];d=ImageDraw.Draw(im)
    for word in words:
        trial=(row+' '+word).strip()
        if d.textlength(trial,font=font(size))>width and row:
            text(im,(xy[0],y),row,size,color);y+=leading;row=word
        else:row=trial
    if row:text(im,(xy[0],y),row,size,color)
    return y+leading
def background(w,h,dim=0):
    im=Image.open(ROOT/'reference/gameplay_scene_reference.png').convert('RGB')
    im=ImageOps.fit(im,(w,h),Image.Resampling.LANCZOS,centering=(.5,.65)).filter(ImageFilter.GaussianBlur(1.6)).convert('RGBA')
    if dim:im.alpha_composite(Image.new('RGBA',im.size,(10,29,33,dim)))
    return im
def save(im,name):im.convert('RGB').save(ROOT/'previews'/name)
def hud(im):
    x=34
    for key,amount,detail in [('food','412','+10 / min'),('scrap','286','+8 / min'),('survivors','18 / 24','4 idle')]:
        surface(im,'ui_resource_chip',(x,26,260,102))
        art(im,'ui_item_'+key,(x+10,33,81,81))
        text(im,(x+102,42),amount,29,'white','bold');text(im,(x+102,82),detail,19,'#B6CECA')
        x+=276
    surface(im,'ui_resource_chip',(1324,26,240,102));glyph(im,'clock',1344,51,40,'gold')
    text(im,(1400,45),'DAY 12',26,'white','demi');text(im,(1400,83),'Late afternoon',18,'#B6CECA')
    for i,(icon,state) in enumerate([('view_iso','selected'),('inventory','normal'),('pause','normal')]):
        surface(im,'ui_icon_button_'+state,(1590+i*100,26,88,88),scale=1.5)
        glyph(im,icon,1614+i*100,49,40,'white' if state=='selected' else 'ink')

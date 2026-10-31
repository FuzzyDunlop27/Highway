#!/usr/bin/env python3
"""Draw deterministic, editable SVG game assets. Render with render_assets.cjs."""
from pathlib import Path
import json, math, random

ROOT = Path(__file__).resolve().parents[1]
SVG = ROOT / 'source_svg'
SVG.mkdir(exist_ok=True)
P = dict(grass='#6B7A4B', dirt='#8A6F4E', asphalt='#4A4D52', concrete='#9A9890',
         rubble='#7A746B', wood='#B9844A', metal='#7D8C96', orange='#F2A03D',
         yellow='#F5C842', skin='#8FAF6A', clothes='#5B5470', goo='#A6E04F',
         red='#D9483B', dark='#1E2126', light='#EDE6D6', ink='#1A1A1A')
ASSETS = []

def col(c): return P.get(c, c)
def attrs(fill, sw=3, stroke='ink', extra=''):
    return f'fill="{col(fill)}" stroke="{col(stroke) if sw else "none"}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round" {extra}'
def rect(x,y,w,h,c,rx=0,sw=3,stroke='ink',extra=''):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" {attrs(c,sw,stroke,extra)}/>'
def ellipse(x,y,rx,ry,c,sw=3,stroke='ink',extra=''):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" {attrs(c,sw,stroke,extra)}/>'
def circ(x,y,r,c,sw=3,stroke='ink',extra=''): return ellipse(x,y,r,r,c,sw,stroke,extra)
def path(d,c='none',sw=3,stroke='ink',extra=''): return f'<path d="{d}" {attrs(c,sw,stroke,extra)}/>'
def poly(points,c,sw=3,stroke='ink',extra=''):
    return f'<polygon points="{points}" {attrs(c,sw,stroke,extra)}/>'
def line(x,y,a,b,c='ink',sw=3,extra=''): return path(f'M{x} {y}L{a} {b}','none',sw,c,extra)
def group(s,transform='',extra=''): return f'<g transform="{transform}" {extra}>{s}</g>'
def svg(s,w,h):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{s}</svg>'
def save(name,w,h,s,priority='P2',desc='',opaque=False,rotates=False,fill_ratio=None):
    (SVG/f'{name}.svg').write_text(svg(s,w,h))
    ASSETS.append(dict(name=name,filename=f'{name}.png',width=w,height=h,priority=priority,
        category=name.split('_')[0],description=desc,opaque=opaque,rotates=rotates,
        facing='east' if rotates or name.startswith('veh_') or name=='dec_car_wreck' else None,
        anchor=[0.5,0.5],nominal_figure_fraction=fill_ratio))
    return s

def bolt(x,y,r=2): return circ(x,y,r,'light',1.3)
def plank(x,y,w,h=15):
    return rect(x,y,w,h,'wood',2)+line(x+7,y+5,x+w-9,y+5,'dirt',1.5)+bolt(x+5,y+h/2,1.5)+bolt(x+w-5,y+h/2,1.5)
def sack(x,y,w=28,h=15,angle=0):
    s=rect(x-w/2,y-h/2,w,h,'dirt',6)+path(f'M{x-w/2+5} {y-h/2+3}Q{x} {y-2} {x+w/2-5} {y-h/2+3}','none',2,'wood')
    return group(s,f'rotate({angle} {x} {y})')
def crate(x,y,w=30,h=27):
    return rect(x,y,w,h,'wood',2)+rect(x+5,y+5,w-10,h-10,'dirt',1,2)+line(x+5,y+5,x+w-5,y+h-5,'wood',4)+bolt(x+3,y+3,1.4)+bolt(x+w-3,y+h-3,1.4)
def tuft(x,y,s=1,c='grass'):
    return group(path('M-5 3L-6 -4L0 1L4 -7L4 2L9 -2','none',2.5,c),f'translate({x} {y}) scale({s})')
def plate(x,y,w,h,c='metal'):
    return rect(x,y,w,h,c,3)+''.join(bolt(a,b,1.8) for a,b in [(x+6,y+6),(x+w-6,y+6),(x+6,y+h-6),(x+w-6,y+h-6)])
def corrugate(x,y,w,h,c='metal'):
    return rect(x,y,w,h,c,3)+''.join(line(a,y+5,a,y+h-5,'asphalt',2) for a in range(int(x+8),int(x+w-4),10))

# Terrain: every mark wraps on a 128px torus. A two-pixel uniform perimeter
# makes opposite boundary samples identical, including the lane-line tile.
def terrain(kind):
    seed_kind='asphalt' if kind=='asphalt_line' else kind
    rng=random.Random(410+sum(map(ord,seed_kind)))
    base={'grass':'grass','dirt':'dirt','asphalt':'asphalt','asphalt_line':'asphalt','concrete':'concrete'}[kind]
    s=rect(0,0,128,128,base,sw=0)
    marks=''
    for i in range(18):
        x,y=rng.randint(6,121),rng.randint(6,121)
        if kind=='grass':
            if i%3==0: marks+=ellipse(x,y,rng.randint(5,12),rng.randint(2,5),'dirt',0)
            else: marks+=tuft(x,y,0.6,'skin' if i%2 else 'dirt')
        elif kind=='dirt':
            marks+=ellipse(x,y,rng.randint(1,3),rng.randint(1,2),'rubble' if i%3 else 'wood',0)
        else:
            marks+=rect(x,y,rng.randint(1,3),1,'rubble',sw=0)
    if kind.startswith('asphalt'):
        marks+=path('M17 16L30 26L26 40L38 48L34 63 M28 31L43 32L50 40 M92 87L82 96L89 107L105 113','none',2,'dark')
        marks+=tuft(29,40,.65)+tuft(87,105,.6)
    if kind=='concrete':
        marks+=path('M4 67L37 67L45 59L77 62L89 67L124 67 M70 4L70 29L75 41L69 62 M36 69L28 82L33 94','none',2,'rubble')
        marks+=tuft(72,40,.5)
    # Explicit clip protects the matching border; antialiasing cannot spill.
    s+='<defs><clipPath id="interior"><rect x="3" y="3" width="122" height="122"/></clipPath></defs>'+group(marks,extra='clip-path="url(#interior)"')
    if kind=='asphalt_line':
        s+=rect(27,59,74,10,'yellow',1,0)+rect(29,60,28,2,'wood',sw=0)+rect(84,66,14,2,'asphalt',sw=0)
    return s

for name,desc in [('grass','Dusty patchy grass'),('dirt','Packed dirt and pebbles'),('asphalt','Cracked highway asphalt'),('asphalt_line','Asphalt with east–west dashed lane marking'),('concrete','Cracked concrete')]:
    save('tile_'+name,128,128,terrain(name),'P1' if name in ['grass','dirt','asphalt'] else 'P2',desc,True)

def rubble(w=128,h=128,large=False):
    rng=random.Random(19 if large else 10)
    s=''
    if large:
        s+=poly('24,62 72,26 191,34 232,95 214,207 64,231 22,171','rubble')
        s+=path('M38 114L38 56L88 56L94 73L118 68L118 90L203 90L203 158L186 158L186 113L65 113L65 143Z','concrete')
        s+=path('M39 174L73 174L73 203L144 203L144 220L39 220Z','concrete')
    for i in range(15 if not large else 28):
        x=rng.randint(18,w-38); y=rng.randint(24,h-34)
        a=rng.randint(-65,65); ww=rng.randint(12,23); hh=rng.randint(7,13)
        c=['rubble','wood','dirt','concrete'][i%4]
        s+=group(rect(x,y,ww,hh,c,1,2)+line(x+3,y+3,x+ww-3,y+3,'light' if c=='concrete' else 'dirt',1),f'rotate({a} {x+ww/2} {y+hh/2})')
    s+=path(f'M{w*.24} {h*.72}l13 -9l19 5l12 -13','none',3,'metal')
    return s
save('dec_rubble',128,128,rubble(),desc='Scattered brick, broken planks and bent rebar')
tree=path('M61 110L59 72L46 58L26 61L12 49 M60 76L75 60L98 60L115 46 M59 69L61 45L49 27L51 12 M61 45L78 30L80 14 M44 58L40 38L24 27 M76 59L86 78L108 84 M61 108L51 118 M61 108L72 117','none',9,'ink')
tree+=path('M61 108L61 72L47 57L27 59L14 49 M61 74L76 58L98 58L113 46 M61 69L63 45L51 27L52 14 M63 45L79 31L80 16 M46 57L42 39L26 28 M77 59L87 76L106 82','none',5,'wood')
tree+=line(61,100,61,77,'dirt',2)+circ(61,68,7,'dirt',2)+tuft(40,105,.8)
save('dec_tree_dead',128,128,tree,desc='Leafless tree viewed from overhead')

def vehicle(wreck=False,rv=False):
    s=''
    for x in [48,185]:
        s+=rect(x,20,28,17,'dark',4)+rect(x,91,28,17,'dark',4)
    s+=rect(20,27,214,74,'wood' if wreck else 'metal',16)
    s+=path('M25 38Q25 30 37 30H216L226 41H24Z','orange' if wreck else 'light',0)
    s+=rect(25,89,202,8,'dirt' if wreck else 'asphalt',3,0)
    if rv:
        s+=rect(28,32,147,62,'light',8)+rect(47,40,34,45,'metal',4)+rect(103,42,43,40,'concrete',3)
        s+=line(52,62,77,62,'asphalt',2)+rect(188,35,22,57,'dark',6)+poly('189,38 204,39 209,63 204,87 189,89','metal',2)
        s+=rect(32,95,128,7,'orange',2)+plank(167,22,47,9)+plank(166,98,48,9)
    elif wreck:
        s+=poly('81,34 143,34 163,44 163,84 144,94 81,94 64,84 64,44','dirt')
        s+=poly('142,39 159,47 159,81 142,89','dark',2)+poly('72,45 87,39 87,89 72,83','dark',2)
        s+=rect(91,40,45,48,'rubble',5)+path('M94 40L106 52L103 76L130 83','none',2,'dirt')
        s+=path('M175 47L189 43L207 50 M42 72L54 64L65 69','none',4,'dirt')
        s+=path('M145 42L153 57L145 64L159 72','none',2,'metal')
        s+=tuft(28,103)+tuft(222,33)
    else:
        s+=rect(32,36,83,56,'asphalt',4)+''.join(line(39,y,106,y,'metal',2) for y in range(43,89,11))
        s+=rect(119,32,64,64,'orange',7)+poly('165,36 182,43 182,85 165,92','dark',2)+rect(124,39,32,49,'metal',3)
        s+=crate(44,46,43,31)+plank(191,35,35,11)
    s+=rect(227,38,8,15,'yellow',2,2)+rect(227,75,8,15,'yellow',2,2)
    s+=rect(18,39,7,12,'red',2,2)+rect(18,77,7,12,'red',2,2)
    return s
save('dec_car_wreck',256,128,vehicle(True),desc='Rusted abandoned east-facing sedan')

def roof(x,y,w,h,c='wood'):
    s=rect(x,y+9,w,h,'dirt',3)+rect(x-5,y,w+10,h-8,c,3)
    s+=poly(f'{x-5},{y+h-8} {x+w+5},{y+h-8} {x+w+5},{y+h/2} {x-5},{y+h/2}','dirt',2)
    s+=line(x-5,y+h/2,x+w+5,y+h/2,'ink',3)
    for xx in range(int(x+12),int(x+w),24):
        s+=line(xx,y+5,xx,y+h/2-5,'dirt',1.6)+line(xx,y+h/2+5,xx,y+h-13,'wood',1.6)
    s+=line(x,y+5,x+w,y+5,'orange',3)
    return s

def shelter():
    s=rect(37,55,183,161,'wood',3)
    s+=rect(51,155,41,45,'dark',2)+rect(159,155,41,45,'dark',2)
    s+=group(plank(46,171,49,13), 'rotate(-18 70 178)')+group(plank(155,169,49,13),'rotate(16 180 176)')
    s+=rect(107,160,36,57,'dirt',3)+rect(111,167,28,44,'wood',2)+circ(134,190,2,'yellow',0)
    s+=roof(35,46,187,117,'wood')
    s+=group(corrugate(151,58,60,41),'rotate(8 180 78)')
    s+=rect(64,28,26,46,'rubble',2)+rect(60,25,34,12,'concrete',2)+rect(68,28,18,5,'dark',1)
    s+=plank(96,112,58,12)+rect(101,214,49,13,'concrete',2)
    s+=crate(203,192,28,30)+tuft(33,218,1.3)+tuft(184,224)
    return s
save('bld_shelter',256,256,shelter(),'P1','Boarded house with patched roof and chimney')

def farm():
    s=''
    for y in [39,106,173]:
        s+=rect(19,y,113,49,'wood',3)+rect(26,y+6,99,35,'dirt',2)
        for x in [42,68,94,115]:
            s+=path(f'M{x} {y+31}v-14','none',2,'grass')
            s+=ellipse(x-5,y+21,7,4,'grass',1.5)+ellipse(x+4,y+16,6,4,'skin',1.5)+circ(x,y+27,4,'orange',1.5)
    s+=rect(150,35,88,160,'wood',3)
    s+=poly('148,40 194,18 240,40 240,175 194,199 148,175','metal')
    s+=poly('154,44 191,27 191,188 154,171','skin',2)
    s+=poly('197,27 233,44 233,170 197,188','grass',2)
    for y in [63,108,152]: s+=path(f'M151 {y}L194 {y-20}L237 {y}','none',5,'wood')
    s+=line(194,23,194,195,'wood',5)+path('M163 169L163 141L184 132L184 181','none',3,'dirt')
    s+=rect(157,203,39,28,'metal',5)+ellipse(176,205,19,6,'light',2)+line(176,210,176,225,'asphalt',2)
    s+=crate(209,207,28,27)+tuft(20,234)
    return s
save('bld_farm',256,256,farm(),'P1','Raised vegetable beds and a makeshift greenhouse')

def garage(workshop=False):
    s=rect(27,35,202,158,'wood',3)+rect(43,107,167,84,'dark',2)
    s+=roof(27,28,202,92,'metal')
    s+=rect(32,116,14,81,'orange',2)+rect(209,116,14,81,'orange',2)
    if workshop:
        s+=rect(57,135,140,32,'wood',3)+rect(62,166,9,28,'dirt',2)+rect(179,166,9,28,'dirt',2)
        s+=plate(77,139,34,17)+path('M132 142L150 142L153 150L145 157L131 157Z','metal',2)
        s+=path('M168 131L175 142L190 140L182 151L190 159L174 157L168 169L164 155L150 151L163 143Z','yellow',2)
        s+=circ(170,149,5,'light',0)+line(189,136,198,128,'yellow',2)+line(187,160,197,167,'orange',2)
        s+=rect(71,96,114,28,'dirt',2)
        for x in [87,117,147,171]:
            s+=line(x,102,x,119,'metal',4)+line(x-4,103,x+5,103,'metal',4)
        s+=crate(26,202,40,32)+rect(199,197,28,43,'metal',6)+ellipse(213,198,14,5,'light',2)
        s+=path('M207 208Q179 197 180 220Q177 241 149 232','none',4,'dark')
    else:
        s+=group(vehicle(), 'translate(38 125) scale(.68)')
        s+=crate(27,199,35,31)+crate(65,207,29,27)
        s+=group(plate(184,184,44,31),'rotate(14 206 199)')+path('M188 225L211 206L234 224','none',7,'metal')
        s+=circ(128,66,17,'dark',2)+path('M119 65L123 58L128 64L135 57L139 62L134 69L140 75L135 79L128 72L122 79L117 74L123 68Z','orange',0)
    return s
save('bld_scavenger',256,256,garage(),'P1','Garage with pickup truck, scrap and tool emblem')
save('bld_workshop',256,256,garage(True),desc='Open workshop with workbench, tools and warm welding spark')

def hq():
    s=rect(49,93,286,153,'wood',5)+rect(67,152,250,69,'dark',3)
    for x in [79,130,247,287]: s+=rect(x,174,28,35,'yellow',2)+line(x+14,175,x+14,208,'dirt',2)
    s+=rect(180,169,42,73,'metal',2)+rect(187,176,28,28,'yellow',2)+rect(213,215,4,5,'dark',0)
    s+=corrugate(40,79,304,91,'metal')+rect(40,149,304,22,'orange',2)
    s+=plate(67,92,81,40,'asphalt')+line(74,102,140,102,'metal',2)+line(74,112,140,112,'metal',2)+line(74,122,140,122,'metal',2)
    s+=rect(171,61,69,61,'wood',4)+rect(181,71,49,40,'dark',3)
    s+=poly('186,91 205,77 224,91 218,91 218,104 192,104 192,91','yellow',0)
    # Roof antenna is an in-canvas recognizable command-center landmark.
    s+=path('M278 95L296 21L314 95 M286 64H307 M291 44H302 M281 84H311','none',4,'dark')
    s+=line(296,20,296,10,'metal',4)+circ(296,11,4,'red',2)+line(278,31,314,31,'metal',3)
    s+=path('M308 44Q325 42 327 26','none',3,'metal')
    # Forecourt pumps underneath a broad yellow-trimmed canopy.
    for x in [91,267]:
        s+=rect(x,246,30,53,'red',4)+rect(x+4,250,22,19,'light',2)+rect(x+8,255,14,7,'dark',0)
        s+=path(f'M{x+29} 258Q{x+47} 258 {x+43} 279L{x+40} 290','none',4,'dark')
        s+=rect(x-5,295,40,7,'concrete',2)
    s+=rect(48,240,11,70,'wood',2)+rect(324,240,11,70,'wood',2)
    s+=poly('33,200 342,200 354,243 25,243','metal')+rect(25,243,329,16,'orange',2)
    s+=line(37,207,337,207,'light',4)+line(41,251,337,251,'yellow',4)
    s+=plate(166,214,48,27,'dark')+poly('177,229 188,218 199,229 195,229 195,236 182,236 182,229','yellow',0)
    for x in [50,82,114,270,302,334]: s+=sack(x,329,33,18)
    for x in [66,98,286,318]: s+=sack(x,344,33,18)
    s+=crate(43,275,27,29)+crate(310,280,28,27)+tuft(37,354)+tuft(339,353)
    return s
save('bld_hq',384,384,hq(),'P1','Fortified gas station headquarters, antenna, pumps and warm windows')

def barracks():
    s=''
    for x in [34,67,100,133,166,199,226]: s+=sack(x,229,32,17)
    for y in [72,106,140,174,208]: s+=sack(22,y,32,17,90)+sack(234,y,32,17,90)
    s+=poly('45,72 127,24 213,72 213,199 45,199','grass')
    s+=poly('45,72 127,24 127,160 45,199','wood')+poly('127,24 213,72 213,199 127,160','dirt')
    s+=poly('45,199 127,153 213,199','grass')+poly('91,199 127,161 158,199','dark')
    s+=path('M127 27V157 M50 77V190 M207 77V190','none',3,'light')
    s+=path('M46 74L26 45 M210 73L232 44','none',2,'wood')+circ(26,45,4,'metal',2)+circ(232,44,4,'metal',2)
    s+=rect(60,90,44,25,'orange',3)+path('M69 102L81 94L94 102 M69 110L81 102L94 110','none',3,'light')
    s+=plank(162,195,57,10)+line(168,192,168,220,'wood',4)+line(213,192,213,220,'wood',4)
    for x in [177,190,203]: s+=line(x,180,x,217,'dark',5)+rect(x-3,200,6,14,'metal',1)
    return s
save('bld_barracks',256,256,barracks(),desc='Warm canvas tent, sandbag perimeter and rifle rack')

def storage():
    s=corrugate(24,104,207,118,'orange')+rect(24,104,207,25,'yellow',2)
    s+=rect(31,133,192,81,'orange',2)+line(126,135,126,211,'dark',3)
    for x in [53,103,149,202]: s+=line(x,140,x,206,'dirt',3)+rect(x-3,164,6,20,'metal',1.5)
    s+=corrugate(44,30,184,96,'metal')+poly('44,30 61,19 237,19 228,30','light',2)+poly('228,30 237,19 237,115 228,126','asphalt',2)
    s+=rect(48,36,176,14,'concrete',2)+plate(71,57,45,34,'dark')+poly('79,81 93,65 108,81','orange',0)
    s+=crate(20,207,35,33)+crate(193,218,33,25)
    return s
save('bld_storage',256,256,storage(),desc='Two stacked shipping containers with locking bars')

def construction(size):
    k=size/256
    s=''
    for y in [51,122,206]: s+=plank(20,y,216,14)
    for x in [27,119,216]:
        s+=rect(x,26,13,206,'wood',2)+bolt(x+6,41)+bolt(x+6,127)+bolt(x+6,213)
    s+=path('M35 211L123 67L222 212 M34 68L123 212L222 65','none',9,'ink')
    s+=path('M35 211L123 67L222 212 M34 68L123 212L222 65','none',5,'dirt')
    s+=poly('52,37 180,29 214,51 203,163 172,150 151,163 127,142 59,152','metal')
    s+=poly('52,37 180,29 214,51 80,60 59,152','light',0)+path('M80 61L84 145 M143 47L137 144 M192 48L181 142','none',2,'asphalt')
    s+=plank(28,221,68,11)+crate(175,205,43,34)
    s+=poly('106,232 120,204 134,232','orange',2)+rect(105,233,30,7,'dark',2)+line(115,218,126,218,'light',4)
    return group(s,f'scale({k})')
save('bld_construction_2x2',256,256,construction(256),'P1','Timber scaffold with folded tarp and construction cone')
save('bld_construction_3x3',384,384,construction(384),desc='Large timber scaffold with folded tarp and construction cone')
save('bld_rubble_2x2',256,256,rubble(256,256,True),desc='Collapsed walls, rubble, planks and bent rebar')

def wall(metal=False):
    s=rect(6,22,116,86,'dirt',2)
    if metal:
        s+=corrugate(8,17,112,82,'metal')+rect(8,17,112,11,'light',2)
        s+=line(8,78,120,78,'asphalt',5)+line(25,10,25,116,'dark',4)+line(103,10,103,116,'dark',4)
        s+=poly('36,40 93,40 93,64 36,64','orange',2)+path('M44 42L37 55 M64 42L52 62 M84 42L72 62','none',6,'dark')
    else:
        for y in [23,41,59,77]: s+=plank(7,y,114,17)
        s+=line(14,88,114,31,'ink',9)+line(14,88,114,31,'dirt',5)
        for x in [9,105]: s+=rect(x,13,14,101,'wood',2)+rect(x,13,14,10,'orange',2)+bolt(x+7,38)+bolt(x+7,89)
    return s
save('def_wall_wood',128,128,wall(),'P1','Solid plank barricade; repeat on adjacent grid cells')
save('def_wall_metal',128,128,wall(True),desc='Corrugated steel barricade, rebar posts and hazard plate')

def tower():
    s=rect(17,17,94,94,'dirt',2)
    for y in range(20,105,14): s+=plank(19,y,90,13)
    s+=rect(10,10,108,9,'wood',2)+rect(10,109,108,9,'wood',2)+rect(10,19,9,90,'wood',2)+rect(109,19,9,90,'wood',2)
    for x in [9,107]:
        for y in [9,107]: s+=rect(x,y,12,12,'orange',2)+bolt(x+6,y+6,2)
    s+=rect(45,104,38,14,'dirt',2)+line(50,106,50,116,'wood',3)+line(78,106,78,116,'wood',3)+line(51,112,77,112,'wood',3)
    return s
save('def_watchtower_base',128,128,tower(),'P1','Overhead timber watchtower platform with ladder opening')

def human(armed=False,gunner=False):
    s=''
    # Limbs flank the head in plan view. No face, eyes or upright portrait.
    s+=path('M53 51L39 48L31 51L31 58L48 60 M53 76L38 79L30 75L30 69L48 68','wood',2.5)
    s+=rect(29,49,13,9,'dark',3,2)+rect(29,70,13,9,'dark',3,2)
    s+=rect(42,45,33,39,'orange' if armed else 'wood',10,2.5)
    s+=path('M49 48L62 48L62 81L49 81Z','dirt',0)
    if not armed:
        s+=rect(37,48,19,32,'grass',6,2.5)+rect(38,52,12,23,'skin',3,1.5)+line(42,56,42,70,'grass',2)
    s+=path('M69 47Q77 44 81 50L88 55L84 62L73 58 M69 81Q77 84 82 78L90 73L86 66L73 71','wood',2.5)
    s+=ellipse(87,58,5,4,'light',2)+ellipse(89,70,5,4,'light',2)
    s+=ellipse(62,64,13,14,'light',2.5)+path('M56 52Q66 48 72 57L73 69L68 76L56 76Q46 63 56 52Z','dirt',2)
    if armed:
        s+=ellipse(62,64,12,13,'grass',2)+path('M70 55L79 59L79 69L70 74Z','wood',2)
        s+=rect(74,45,9,8,'orange',2,1.5)
        s+=rect(77,58,25,9,'dark',2,2)+rect(65,59,15,7,'wood',2,2)+line(101,62,111 if gunner else 103,62,'ink',4)
        s+=rect(85,67,8,5,'metal',1,1.5)+line(86,60,97,60,'metal',1.5)
    return s
save('unit_survivor',128,128,human(),'P1','Overhead civilian worker with green backpack',rotates=True,fill_ratio=.55)
save('unit_defender',128,128,human(True),'P1','Overhead rifle defender with orange armband',rotates=True,fill_ratio=.55)
save('def_watchtower_gunner',128,128,human(True,True),'P1','Centered overhead gunner with long east-facing rifle',rotates=True)

nest=''
for a in range(0,360,30):
    rad=math.radians(a)
    nest+=sack(64+43*math.cos(rad),64+43*math.sin(rad),29,18,a+90)
save('def_mg_nest_base',128,128,nest,desc='Overhead sandbag emplacement ring')
mg=path('M64 62L41 28 M64 62L38 98 M64 62L96 88','none',7,'ink')+path('M64 62L41 28 M64 62L38 98 M64 62L96 88','none',3,'metal')
mg+=circ(64,64,17,'asphalt')+rect(44,53,42,21,'metal',4)+rect(33,57,16,14,'wood',3)+rect(83,58,31,11,'dark',2)
mg+=line(85,60,112,60,'metal',2)+rect(60,75,19,15,'grass',2)+path('M64 74V86 M70 74V86 M76 74V86','none',3,'yellow')+rect(54,45,10,12,'dark',2)
save('def_mg_nest_gun',128,128,mg,desc='Centered tripod-mounted machine gun, barrel east',rotates=True)
spikes=''
for y in [24,52,80]:
    spikes+=plank(12,y,104,21)
    for x in [28,63,98]: spikes+=poly(f'{x-7},{y+14} {x},{y-9} {x+7},{y+14}','metal',2)+line(x,y-5,x,y+8,'light',1.5)
save('def_spikes',128,128,spikes,desc='Three low nail boards with sharpened metal stakes')
wire=plank(10,29,108,9)+plank(10,88,108,9)
for x in [25,49,73,97]:
    wire+=ellipse(x,63,16,35,'none',5,'dark')+ellipse(x,63,16,35,'none',2,'metal')
    for y in [36,88]: wire+=line(x-5,y-4,x+5,y+4,'metal',2)+line(x-4,y+5,x+4,y-5,'metal',2)
wire+=line(12,65,116,65,'metal',2)
save('def_barbwire',128,128,wire,desc='Overhead barbed wire coil on wooden mounting slats')

def zombie(kind):
    brute=kind=='brute'; runner=kind=='runner'
    # Use the same strictly overhead anatomy and rightward reach as survivors.
    s=path('M52 51L36 47L29 53L30 59L46 61 M51 75L38 82L29 77L30 70L46 67','clothes',2.5)
    s+=rect(27,50,13,9,'dark',3,2)+rect(27,72,13,9,'dark',3,2)
    s+=path('M44 47Q58 39 73 47L78 55L73 63L79 73L69 83L48 80L43 71L47 63Z','clothes',2.5)
    s+=path('M47 50L54 47L57 58L50 61L52 71L46 76','grass',0)
    if brute:
        s+=path('M57 45L70 46L76 53L72 66L77 74L68 82L58 78Z','skin',2)
    s+=path('M70 48Q74 42 82 46L91 49L97 45L102 49L98 56L89 57L78 54 M71 78Q77 84 84 79L95 76L101 79L105 74L100 68L91 70L79 73','skin',2.5)
    s+=line(98,47,102,44,'skin',2.5)+line(101,75,105,73,'skin',2.5)
    s+=ellipse(64,64,14,14,'skin',2.5)+path('M54 56Q56 49 65 51L68 54L64 59L59 58L56 64L51 63Z','grass',0)
    s+=ellipse(75,64,4,7,'skin',2)+path('M59 74L67 76','none',2,'grass')
    if runner:
        # A staggered sprint pose has a different silhouette at 48px, not just
        # a scaled walker. One arm reaches east while the opposite arm drives back.
        s=path('M53 55L43 45L34 49L37 57L48 63 M54 70L41 80L36 90L45 93L52 83L62 76','clothes',2.5)
        s+=path('M33 48L41 47L42 54L34 57L30 53Z M36 87L45 89L44 95L34 94Z','dark',2)
        s+=path('M49 51L64 47L75 54L72 67L77 74L64 81L52 75L55 64Z','clothes',2.5)
        s+=path('M70 52L81 43L89 40L96 44L94 49L86 47L77 59 M60 75L52 82L41 76L39 69L43 66L47 72L53 74','skin',2.5)
        s+=ellipse(69,63,12,12,'skin',2.5)+ellipse(79,61,3,5,'skin',1.5)
        s+=path('M60 55L67 51L72 55L65 57L62 63L58 62Z','grass',0)
        s+=path('M55 52L49 48L53 56 M63 78L57 84L67 80','clothes',2)
    if brute:
        s=group(s,'translate(-23 -23) scale(1.36)')
        s+=path('M40 28L54 24L59 30L51 35L43 34','clothes',2)+rect(77,34,15,9,'clothes',2,2)
    return s
save('zmb_walker',128,128,zombie('walker'),'P1','Cartoon overhead walker with two arms reaching east',rotates=True,fill_ratio=.55)
save('zmb_runner',128,128,zombie('runner'),desc='Lean overhead runner with torn purple clothing',rotates=True,fill_ratio=.50)
save('zmb_brute',128,128,zombie('brute'),desc='Broad hulking overhead zombie with torn purple clothing',rotates=True,fill_ratio=.85)

flash=poly('7,25 25,27 19,12 37,24 56,16 46,30 59,35 42,39 46,52 31,42 19,48 24,36 7,36','orange',2)+poly('18,30 35,29 45,25 39,33 49,35 34,38 27,34 18,35','yellow',0)+poly('25,31 39,33 28,36','light',0)
save('fx_muzzle_flash',64,64,flash,desc='East-facing yellow-orange muzzle burst',rotates=True)
save('fx_tracer',64,16,path('M5 8L53 5L59 8L53 11Z','yellow',0)+path('M19 8L55 7L58 8L55 9Z','light',0),desc='Thin horizontal bullet streak; long axis east',rotates=True)
goo=path('M31 45Q25 28 37 30L49 40Q54 26 62 33L70 45L90 34Q104 32 93 48L83 57Q102 58 101 67Q100 75 85 75L79 78Q92 93 82 97L67 85Q63 104 54 97L49 81Q32 91 28 81L40 67Q19 65 22 55Z','goo',2.5)
goo+=ellipse(55,55,15,7,'skin',0)+ellipse(64,54,7,3,'light',0)+circ(15,39,5,'goo',2)+circ(107,86,6,'goo',2)+circ(40,108,4,'goo',1.5)+circ(105,28,4,'goo',1.5)
save('fx_goo_splat',128,128,goo,'P1','Cartoon green goo splat, no gore')
dust=''
for x,y,r in [(36,72,22),(54,46,23),(83,54,24),(95,76,19),(66,85,24),(48,80,25)]:
    dust+=circ(x,y,r,'dirt',0,extra='opacity=".26"')
for x,y,r in [(40,68,17),(57,49,18),(82,61,19),(70,82,19),(52,80,18)]:
    dust+=circ(x,y,r,'wood',0,extra='opacity=".45"')
dust+=ellipse(58,50,17,10,'light',0,extra='opacity=".3"')+circ(19,91,5,'wood',0,extra='opacity=".4"')+circ(105,35,5,'wood',0,extra='opacity=".3"')
dust='<defs><filter id="soft" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="2"/></filter></defs>'+group(dust,extra='filter="url(#soft)"')
save('fx_dust_puff',128,128,dust,desc='Translucent soft-edged cel-shaded dust puff')

def gear(cx,cy,r,c,inner=0,sw=4):
    pts=[]
    for i in range(48):
        a=2*math.pi*i/48
        rr=r if i%4 in [1,2] else r*.81
        pts.append(f'{cx+rr*math.cos(a):.2f},{cy+rr*math.sin(a):.2f}')
    s=poly(' '.join(pts),c,sw)
    if inner: s+=circ(cx,cy,inner,'dark',sw)
    return s
def person(x=128,y=76,armed=False):
    s=circ(x,y,30,'light',5)+path(f'M{x-66} 216V167Q{x-64} 123 {x-27} 120L{x} 133L{x+27} 120Q{x+64} 123 {x+66} 167V216Z','light',5)
    if armed:
        s+=group(rect(69,155,105,23,'wood',4,4)+rect(163,159,45,14,'dark',2,3)+rect(112,174,18,24,'metal',2,3),'rotate(-32 132 167)')
        s+=rect(68,142,20,16,'orange',2,3)
    return s
def icon(name):
    if name=='food':
        s=''
        for x,y in [(36,106),(129,106),(82,31)]:
            s+=rect(x,y+12,82,94,'metal',7,5)+ellipse(x+41,y+105,41,11,'asphalt',4)+rect(x+2,y+33,78,46,'orange',sw=0)
            s+=ellipse(x+41,y+12,41,12,'light',4)+ellipse(x+41,y+12,26,5,'metal',2)+ellipse(x+41,y+55,15,12,'grass',3)+path(f'M{x+41} {y+46}q-3 -11 8 -14','none',3,'grass')
        return s
    if name=='scrap': return group(plate(44,47,164,167),'rotate(-9 126 130)')+gear(133,125,75,'orange',25,5)+circ(133,125,13,'metal',3)
    if name=='survivors': return person()
    if name=='defender': return person(armed=True)
    if name=='build': return group(rect(114,85,28,144,'wood',5,5)+line(122,118,122,210,'orange',4)+path('M52 40H169L210 70L194 91L159 76H147V107H81V78H52Z','metal',5)+rect(53,40,35,39,'light',2,4),'rotate(35 128 128)')
    if name=='upgrade': return poly('128,29 221,120 177,120 177,220 79,220 79,120 35,120','orange',5)+poly('128,45 197,113 166,113 128,76 90,113 58,113','yellow',0)+rect(90,147,75,10,'yellow',2,0)
    if name=='demolish': return group(path('M99 226V83Q99 31 144 30H177V59H149Q129 59 129 84V196L152 214L137 232L115 219Z','metal',5)+line(109,87,109,196,'light',5)+path('M158 32V57','none',4,'dark'),'rotate(28 128 128)')
    if name=='horde_alert':
        s=path('M81 212L78 150L49 115Q41 103 52 95Q60 89 68 99L85 116L79 57Q77 43 90 41Q102 39 104 53L111 102L109 31Q109 18 121 18Q134 18 134 33L137 101L145 44Q147 30 160 34Q171 37 168 50L160 110L173 76Q178 64 190 69Q201 74 193 88L179 143L165 163L163 213Z','skin',5)
        s+=path('M109 128L139 140L151 122 M114 171L139 175','none',4,'grass')+rect(76,195,94,35,'clothes',3,4)+poly('35,229 45,214 74,214 81,207 102,214 170,214 180,205 214,218 224,229','dirt',4)
        return s
    if name=='clock': return circ(128,128,94,'wood',5)+circ(128,128,76,'light',5)+''.join(line(128+63*math.cos(a),128+63*math.sin(a),128+52*math.cos(a),128+52*math.sin(a),'dark',5) for a in [0,math.pi/2,math.pi,3*math.pi/2])+path('M128 76V128L165 147','none',9,'dark')+circ(128,128,9,'orange',3)
    if name=='speed': return poly('30,52 121,128 30,204','orange',5)+poly('129,52 222,128 129,204','yellow',5)
    if name=='pause': return rect(48,39,59,178,'yellow',10,5)+rect(148,39,59,178,'orange',10,5)+rect(57,48,10,158,'light',3,0)+rect(157,48,10,158,'yellow',3,0)
    if name=='settings': return gear(128,128,106,'metal',36,5)+path('M72 90Q92 54 133 56','none',6,'light')
    if name=='medicine': return rect(39,61,178,159,'light',16,5)+path('M91 61V43Q91 30 104 30H153Q165 30 165 43V61','none',9,'metal')+poly('110,91 147,91 147,121 178,121 178,158 147,158 147,189 110,189 110,158 79,158 79,121 110,121','red',3)
    if name=='fuel': return path('M72 61L88 30H158L177 61H196Q208 61 208 75V213H48V75Q48 61 62 61Z','orange',5)+path('M103 43H145L154 61H94Z','dark',3)+rect(47,56,43,22,'metal',3,4)+path('M73 88L183 190 M183 88L73 190','none',7,'dirt')+path('M128 92Q155 129 155 145A27 27 0 0 1 101 145Q101 126 128 92Z','yellow',4)
    if name=='ammo':
        s=rect(33,113,190,110,'grass',8,5)+rect(28,110,200,26,'metal',4,4)
        for x in [60,110,160]: s+=path(f'M{x} 101V62L{x+18} 25L{x+36} 62V101Z','yellow',4)+rect(x,89,36,19,'wood',2,3)+line(x+8,59,x+8,82,'light',3)
        return s+rect(106,140,44,29,'orange',4,4)
    if name=='knowledge': return path('M29 49Q76 30 125 52Q171 30 223 49V209Q171 193 125 215Q77 193 29 209Z','wood',5)+path('M39 42Q80 28 125 48Q168 28 213 42V196Q165 183 125 205Q79 183 39 196Z','light',4)+line(125,48,125,203,'dirt',4)+path('M143 39V119L161 106L177 115V35','orange',3)+path('M57 77Q81 70 105 80 M57 98Q81 91 105 101 M57 119Q81 112 105 122 M57 140Q81 133 105 143 M145 148Q170 138 194 145 M145 167Q170 157 194 164','none',3,'concrete')
    raise ValueError(name)

for name in ['food','scrap','survivors','defender','build','upgrade','demolish','horde_alert','clock','speed','pause','settings','medicine','fuel','ammo','knowledge']:
    pri='P1' if name in ['food','scrap','survivors','build','upgrade','horde_alert'] else 'P3' if name in ['medicine','fuel','ammo','knowledge'] else 'P2'
    save('icon_'+name,256,256,icon(name),pri,name.replace('_',' ').capitalize()+' HUD icon')
badge=path('M50 26H206V162L128 230L50 162Z','wood',5)+path('M65 42H191V153L128 209L65 153Z','orange',4)+path('M82 65L128 104L174 65','none',8,'yellow')
save('ui_level_badge',256,256,badge,desc='Blank chevron shield; put the level number in its lower center')
save('veh_rv',256,128,vehicle(rv=True),'P3','Armored RV with roof equipment, top-down, facing east')
save('veh_pickup',256,128,vehicle(),'P3','Salvage pickup with crate in bed, top-down, facing east')

# App icon: one coherent illustration, split into exact background/foreground.
bg=rect(0,0,1024,1024,'dark',sw=0)
bg+=circ(749,242,180,'orange',0)+circ(749,242,139,'yellow',0)
bg+=path('M0 352L68 328L137 353L237 313L324 352L442 325L526 348L629 321L708 357L809 333L914 346L1024 316V1024H0Z','clothes',0)
bg+=path('M0 479L141 415L242 454L379 401L502 459L618 411L750 460L918 407L1024 440V1024H0Z','grass',0)
bg+=poly('422,425 593,425 1024,1024 64,1024','asphalt',0)
for x,y,w,h in [(504,466,17,35),(514,540,23,47),(532,646,30,68),(555,794,42,99),(581,974,51,50)]: bg+=poly(f'{x},{y} {x+w},{y} {x+w+8},{y+h} {x+3},{y+h}','yellow',0)
bg+=path('M402 452L63 1024 M605 450L1024 1007','none',8,'concrete')
for x,y in [(53,594),(912,652),(96,754),(825,504)]: bg+=group(tree,f'translate({x} {y}) scale(1.4)',extra='opacity=".8"')
fg=''
# Gas station town heart is a secondary landmark below the hero tower.
fg+=group(hq(),'translate(365 413) scale(1.38)')
# Watchtower: perspective reserved for icon illustration, not game sprite.
fg+=path('M182 395L137 823 M344 395L386 823 M156 641L365 796 M367 634L154 800 M172 493L355 637 M351 493L165 638','none',24,'ink')
fg+=path('M182 395L137 823 M344 395L386 823 M156 641L365 796 M367 634L154 800 M172 493L355 637 M351 493L165 638','none',15,'wood')
fg+=rect(146,273,236,149,'wood',7,7)+rect(164,290,199,99,'dark',3,5)
fg+=rect(176,302,69,73,'yellow',3,4)+rect(268,302,78,73,'yellow',3,4)
fg+=poly('155,268 263,192 390,268','orange',7)+poly('133,273 263,171 406,273','metal',7)+line(159,260,265,182,'light',8)
fg+=rect(125,404,281,26,'orange',3,6)+line(130,415,401,415,'yellow',6)
fg+=path('M151 351V407 M382 351V407 M137 359H395','none',10,'wood')
fg+=path('M265 176V100 M241 128H289','none',7,'metal')+circ(265,98,9,'red',3)
fg+=path('M211 376V345Q211 325 228 325Q246 325 246 345V376Z','dark',0)+circ(229,315,13,'dark',0)+line(236,346,279,332,'dark',10)
fg+=rect(195,532,18,263,'wood',3,4)+rect(247,532,18,263,'wood',3,4)
for y in range(546,794,32): fg+=line(207,y,250,y,'wood',9)
fg+=group(crate(0,0,80,70),'translate(103 805)')+group(crate(0,0,58,53),'translate(316 820)')
# Bottom-edge approaching silhouettes give context without gore or text.
def silhouette(x,y,k):
    s=circ(0,-57,18,'dark',0)+path('M-18 -36Q0 -45 20 -34L27 12L20 66H3L-1 20L-9 66H-27L-23 4L-34 -17L-51 -7L-59 -20L-29 -42Z','dark',0)+path('M14 -35L38 -47L55 -36L50 -21L33 -28L23 -8','dark',0)
    return group(s,f'translate({x} {y}) scale({k})')
fg+=silhouette(93,946,1.5)+silhouette(873,947,1.6)+silhouette(726,1004,1.3)
save('app_icon_bg',1024,1024,bg,desc='Opaque dusk landscape and highway layer',opaque=True)
save('app_icon_fg',1024,1024,fg,desc='Transparent watchtower, gas station and zombie silhouettes layer')
save('app_icon',1024,1024,bg+fg,desc='Opaque full-bleed dusk watchtower app icon',opaque=True)

(ROOT/'manifest.json').write_text(json.dumps({'title':'Highway Holdout — Phase 1','version':'1.0.0','palette':P,'coordinate_system':'PNG/SVG origin top-left; game anchors centered','assets':ASSETS},indent=2)+'\n')
print(f'Created {len(ASSETS)} editable SVG masters.')

"""Pixel-native terrain, decor and effects; solid palette pixels only."""
import random
from pixel_core import Canvas

def tile(kind):
    base='asphalt' if kind.startswith('asphalt') else kind
    c=Canvas(bg=base);rng=random.Random(512+sum(map(ord,base)))
    if kind=='grass':
        for x,y in [(5,5),(22,4),(14,12),(26,18),(6,23),(19,27)]:
            c.rect((x,y,x+3,y+1),'dirt');c.dot(x+1,y-1,'dirt')
        for x,y in [(10,7),(25,8),(5,14),(20,16),(12,22),(26,27)]:
            c.line([(x-1,y-1),(x,y),(x+1,y-2)],'skin')
            c.dot(x,y+1,'dirt')
    elif kind=='dirt':
        for i in range(12):
            x,y=rng.randrange(3,28),rng.randrange(3,28)
            c.rect((x,y,x+1,y),'rubble' if i%3 else 'wood')
            if i%4==0:c.dot(x+2,y+1,'rubble')
    elif kind.startswith('asphalt'):
        for i in range(12):
            x,y=rng.randrange(2,30),rng.randrange(2,30)
            c.dot(x,y,'rubble')
        c.line([(4,4),(7,6),(7,9),(9,11),(8,15)],'dark')
        c.line([(7,7),(11,7),(13,9)],'dark')
        c.line([(24,21),(21,24),(23,27),(27,28)],'dark')
        c.line([(7,11),(8,12),(9,10)],'grass')
        c.dot(23,26,'grass')
        if kind=='asphalt_line':
            c.rect((7,15,24,16),'yellow');c.rect((7,15,10,15),'wood');c.dot(23,16,'asphalt')
    elif kind=='concrete':
        c.line([(1,16),(9,16),(12,14),(20,15),(23,16),(30,16)],'rubble')
        c.line([(17,1),(17,7),(19,10),(17,14)],'rubble')
        c.line([(9,17),(7,21),(8,24)],'rubble')
        c.dot(18,10,'grass');c.dot(19,9,'grass')
        for x,y in [(6,6),(25,8),(19,25),(4,27)]:c.dot(x,y,'rubble')
    return c.im

def dust():
    c=Canvas()
    c.poly([(7,13),(10,13),(10,9),(14,9),(14,6),(19,6),(19,9),(23,9),(23,13),(27,13),(27,21),(23,21),(23,25),(16,25),(16,27),(10,27),(10,23),(6,23),(6,18),(4,18),(4,14)],'dirt')
    c.poly([(8,14),(12,14),(12,10),(16,10),(16,8),(19,8),(19,12),(22,12),(22,16),(25,16),(25,20),(21,20),(21,23),(16,23),(16,25),(12,25),(12,21),(8,21)],'wood')
    c.rect((12,12,17,14),'light');c.rect((10,14,15,16),'wood')
    # Checker gaps soften the boundary without semitransparent blur.
    for y in range(32):
        for x in range(32):
            px=c.im.getpixel((x,y))
            if px[3] and px[:3]==(138,111,78) and (x+y)%2==0:c.im.putpixel((x,y),(0,0,0,0))
    for x,y in [(4,24),(7,27),(27,9),(24,27)]:c.dot(x,y,'wood')
    return c.im

def flash():
    c=Canvas(16,16)
    c.poly([(1,6),(6,6),(4,3),(8,5),(13,3),(11,7),(14,8),(10,10),(11,13),(7,11),(4,12),(5,9),(1,9)],'ink')
    c.poly([(3,7),(7,7),(6,5),(9,6),(11,5),(9,8),(12,8),(9,9),(9,11),(7,10),(6,10),(6,8),(3,8)],'orange')
    c.rect((5,7,9,8),'yellow');c.dot(7,8,'light')
    return c.im

def tracer():
    c=Canvas(16,4)
    c.rect((1,1,13,1),'yellow');c.rect((8,2,14,2),'yellow')
    c.rect((8,1,14,1),'light')
    return c.im

def tree():
    c=Canvas()
    branches=[[(16,16),(15,10),(10,5),(10,2)],[(16,16),(21,11),(25,11),(29,7)],
        [(16,16),(9,14),(5,8),(2,8)],[(16,16),(11,21),(4,24),(2,22)],
        [(16,16),(19,23),(24,27),(28,27)],[(16,16),(15,24),(12,29)],
        [(15,10),(18,6),(21,4)],[(19,23),(24,20),(28,19)]]
    for pts in branches:c.line(pts,'ink',3)
    for pts in branches:c.line(pts,'wood')
    c.rect((14,14,18,18),'ink');c.rect((15,15,17,17),'dirt');c.dot(15,15,'wood')
    return c.im

CUSTOM={**{'tile_'+k:lambda k=k:tile(k) for k in ['grass','dirt','asphalt','asphalt_line','concrete']},
        'fx_dust_puff':dust,'fx_muzzle_flash':flash,'fx_tracer':tracer,'dec_tree_dead':tree}

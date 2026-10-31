"""Low-resolution defense silhouettes with one-pixel outlines and wood grain."""
from pixel_core import Canvas

def wood():
    c=Canvas()
    c.rect((2,5,29,26),'ink')
    for y in [6,11,16,21]:
        c.rect((3,y,28,y+3),'wood');c.rect((3,y+3,28,y+3),'dirt')
    c.line([(4,23),(27,8)],'ink',3);c.line([(4,23),(27,8)],'dirt')
    for x in [2,26]:
        c.rect((x,3,x+3,28),'ink');c.rect((x+1,4,x+2,27),'wood')
        c.rect((x+1,4,x+2,5),'orange');c.dot(x+1,9,'light');c.dot(x+1,23,'light')
    return c.im

def tower():
    c=Canvas()
    c.rect((2,2,29,29),'ink');c.rect((3,3,28,28),'wood')
    c.rect((5,5,26,26),'ink');c.rect((6,6,25,25),'wood')
    for y in [9,13,17,21,25]:
        c.rect((6,y,25,y),'dirt');c.rect((6,y+1,25,y+1),'ink')
    for x in [2,26]:
        for y in [2,26]:
            c.rect((x,y,x+3,y+3),'ink');c.rect((x+1,y+1,x+2,y+2),'orange')
            c.dot(x+1,y+1,'yellow')
    c.rect((12,26,20,29),'dirt')
    c.rect((12,26,12,29),'wood');c.rect((20,26,20,29),'wood')
    c.rect((12,28,20,28),'wood')
    return c.im

def sandbags():
    c=Canvas()
    # Octagonal ring, opening centered precisely on (16,16).
    bags=[(11,2,18,5),(19,4,25,7),(24,8,28,13),(26,14,29,19),
          (23,20,27,25),(17,25,23,28),(10,26,16,29),(4,22,10,26),
          (2,16,5,22),(3,9,6,15),(6,4,12,8)]
    for x,y,r,b in bags:
        c.rect((x,y,r,b),'ink');c.rect((x+1,y+1,r-1,b-1),'dirt')
        c.rect((x+1,y+1,r-1,y+1),'wood')
    return c.im

CUSTOM={'def_wall_wood':wood,'def_watchtower_base':tower,'def_mg_nest_base':sandbags}

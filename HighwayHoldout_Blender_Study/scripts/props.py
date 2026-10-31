"""Chunky timber defenses, a salvage sedan, and scene dressing."""
import math,random
from geometry import box,cyl,beam,rod,sphere,roof,mesh

def tower():
    for x in [-.63,.63]:
        for y in [-.63,.63]:
            beam('splayed timber leg',(x*1.2,y*1.2,.05),(x,y,1.9),.15,'wood')
            box('post foot',(x*1.2,y*1.2,.1),(.24,.24,.19),'stone',.035)
    for y in [-.64,.64]:
        beam('tower diagonal',(-.69,y,.35),(.64,y,1.8),.095,'wood_light')
        beam('tower diagonal',(.69,y,.35),(-.64,y,1.8),.095,'wood_dark')
    for x in [-.64,.64]:beam('side diagonal',(x,-.7,.35),(x,.64,1.8),.09,'wood_light')
    box('platform joists',(0,0,1.9),(1.65,1.65,.18),'wood_dark',.045)
    for y in [-.7,-.46,-.22,.02,.26,.5,.74]:box('deck board',(0,y,2.03),(1.68,.21,.09),'wood_light',.015)
    for x in [-.76,.76]:
        for y in [-.76,.76]:box('rail upright',(x,y,2.28),(.095,.095,.55),'wood',.02)
    for y in [-.76,.76]:box('deck rail',(0,y,2.5),(1.65,.1,.11),'wood',.02)
    for x in [-.76,.76]:box('deck rail',(x,0,2.5),(.1,1.65,.11),'wood',.02)
    for x in [-.25,.25]:beam('ladder upright',(x,-1.0,.1),(x,-.8,2.1),.06,'wood_light')
    for z in [.3,.6,.9,1.2,1.5,1.8]:rod('ladder rung',(-.25,-1+z*.1,z),(.25,-1+z*.1,z),.038,'wood')
    box('platform supply box',(-.38,.38,2.17),(.4,.34,.22),'teal',.03)

def wall():
    for x in [-.67,.67]:
        box('heavy barricade post',(x,0,.57),(.19,.25,1.14),'wood_dark',.035)
        box('post cap',(x,0,1.16),(.23,.29,.1),'wood_light',.02)
    for z in [.22,.49,.76,1.03]:box('barricade board',(0,-.03,z),(1.65,.19,.23),'wood',.025)
    beam('diagonal brace',(-.68,-.17,.19),(.68,-.17,1.07),.11,'wood_light',.07)
    for x in [-.65,.65]:
        for z in [.22,.76]:cyl('iron bolt',(x,-.145,z),.035,.025,'iron',8,(math.pi/2,0,0),0)

def car():
    for x in [-.8,.85]:
        for y in [-.55,.55]:
            cyl('flat tire',(x,y,.28),.29,.18,'rubber',12,(math.pi/2,0,0),.025)
            cyl('wheel hub',(x,y*1.16,.28),.14,.025,'steel',8,(math.pi/2,0,0),.01)
    box('rusting chassis',(0,0,.4),(2.65,1.13,.3),'rust',.13)
    box('sedan body',(0,0,.66),(2.55,1.13,.43),'teal',.17)
    box('front hood',(.91,0,.87),(.72,1.03,.13),'teal_light',.07)
    box('rear boot',(-1,0,.86),(.48,1.0,.12),'teal',.055)
    verts=[(-.72,-.49,.85),(.62,-.49,.85),(.62,.49,.85),(-.72,.49,.85),
           (-.43,-.4,1.28),(.29,-.4,1.28),(.29,.4,1.28),(-.43,.4,1.28)]
    mesh('faceted cabin',verts,[(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)],'glass',.025)
    box('roof',(-.07,0,1.29),(.82,.87,.09),'cream',.05)
    for y in [-.5,.5]:beam('door pillar',(-.05,y,.88),(-.05,y*.81,1.28),.065,'teal')
    box('front bumper',(1.35,0,.46),(.1,1.14,.13),'steel',.035)
    box('grille',(1.3,0,.69),(.025,.44,.16),'iron',.01)
    for y in [-.39,.39]:box('broken headlight',(1.3,y,.73),(.04,.22,.16),'cream',.035)
    box('rust hood patch',(.98,.2,.946),(.35,.24,.01),'rust',.02,(0,0,.2))
    box('broken rear plank',(-.89,0,1.01),(.12,1.01,.05),'wood',.01,(0,.3,.3))

def dead_tree():
    beam('dead trunk',(0,0,0),(.06,.02,1.3),.18,'wood_dark')
    branches=[((.03,0,.75),(-.5,.12,1.24)),((.04,0,.9),(.45,-.04,1.51)),
              ((.06,0,1.22),(-.13,.07,1.81)),((-.31,.08,1.03),(-.4,.11,1.63)),
              ((.3,-.03,1.31),(.69,.15,1.48))]
    for a,b in branches:beam('bare fork',a,b,.075,'wood',bevel=.015)

def grass(x,y,z=0,scale=1):
    for dx,dy,h in [(-.08,0,.18),(.04,.04,.28),(.12,-.03,.14)]:
        mesh('dry grass blade',[(x+dx-.035*scale,y+dy,z),(x+dx+.035*scale,y+dy,z),(x+dx+.02,y+dy+.025,z+h*scale)],[(0,1,2)],'grass_light')

def rubble(x,y):
    rng=random.Random(235+int(x*100)+int(y*100))
    for i in range(6):
        box('scattered broken masonry',(x+rng.uniform(-.35,.35),y+rng.uniform(-.25,.25),.07),
            (rng.uniform(.12,.26),.12,.13),'stone' if i%2 else 'rust',.018,(.1,.15,rng.random()*3))

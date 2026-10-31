"""Fresh 3D roadside buildings; no imported drawings or image textures."""
import math
from geometry import box,cyl,beam,rod,roof,sphere,curve,mesh

def sandbag(x,y,z=.13,angle=0):
    box('stitched canvas sandbag',(x,y,z),(.58,.31,.25),'soil',.09,(0,0,angle))
    beam('bag stitching',(x-.18,y-.15,z+.05),(x+.18,y-.15,z+.05),.018,'wood_light')

def barrel(x,y):
    cyl('salvaged oil drum',(x,y,.37),.27,.72,'teal',16,bevel=.03)
    for z in [.15,.59]:cyl('raised drum rib',(x,y,z),.283,.055,'teal_dark',16)
    cyl('drum lid',(x,y,.74),.24,.025,'steel',16)
    cyl('bung',(x+.1,y,.76),.035,.03,'black',8)

def crate(x,y,z=0,scale=1):
    box('supply crate',(x,y,z+.23*scale),(.48*scale,.48*scale,.46*scale),'wood',.025)
    for yy in [-.245,.245]:
        for xx in [-.18,.18]:box('crate binding',(x+xx*scale,y+yy*scale,z+.23*scale),(.05*scale,.02,.46*scale),'wood_light',.005)
    beam('crate crossbrace',(x-.18*scale,y-.26*scale,z+.06*scale),(x+.18*scale,y-.26*scale,z+.41*scale),.055*scale,'wood_light')

def hq():
    box('reinforced slab',(0,0,.09),(4.6,4.5,.18),'stone',.12)
    box('cream station walls',(0,.72,.83),(3.85,2.35,1.5),'cream',.1)
    box('dark teal lower trim',(0,-.475,.38),(3.9,.11,.4),'teal',.02)
    box('left storefront glass',(-1.06,-.487,1.01),(1.34,.045,.76),'glass',.025)
    box('right storefront glass',(1.08,-.487,1.01),(1.28,.045,.76),'glass',.025)
    for x in [-1.6,-.54,.52,1.6]:box('window mullion',(x,-.525,1.01),(.06,.07,.84),'cream',.012)
    for x in [-1.05,1.08]:
        box('window sill',(x,-.55,.63),(1.4,.14,.09),'teal_dark',.02)
        box('window reflection',(x-.34,-.516,1.16),(.1,.015,.4),'glass_light',.005)
    box('store door frame',(0,-.51,.86),(.76,.1,1.32),'teal',.02)
    box('store door',(0,-.57,.87),(.58,.05,1.18),'glass',.02)
    box('door kickplate',(0,-.61,.4),(.57,.02,.22),'steel',.01)
    box('brass handle',(.18,-.64,.88),(.035,.05,.2),'yellow',.005)
    box('flat roof rim',(0,.72,1.66),(4.15,2.65,.2),'teal',.09)
    box('recessed roof surface',(0,.72,1.77),(3.88,2.4,.07),'teal_light',.03)
    box('rooftop HVAC',(-1.15,1.0,2.0),(.8,.62,.4),'cream',.035)
    for x in [-1.4,-1.25,-1.1,-.95]:box('HVAC slat',(x,.68,2.0),(.045,.03,.25),'iron',.006)
    cyl('HVAC fan',(-1.15,1.0,2.22),.24,.035,'iron',12)
    for i in range(4):box('fan blade',(-1.15,1,2.25),(.35,.055,.015),'steel',.005,(0,0,i*math.pi/2+.3))
    box('roof access hatch',(.6,1.4,1.87),(.7,.5,.15),'iron',.035)
    for x in [1.27,1.65]:beam('radio tower leg',(x,1.5,1.8),(1.46,1.5,2.93),.035,'steel')
    rod('mast',(1.46,1.5,2.7),(1.46,1.5,3.45),.023,'iron')
    for z in [2.25,2.55,2.85]:rod('antenna cross rung',(1.2,1.5,z),(1.72,1.5,z),.018,'steel')
    sphere('radio tip',(1.46,1.5,3.45),(.055,.055,.055),'coral',2)
    # An off-center rooftop tarp makes the headquarters read as improvised.
    box('rust tarp',(.62,.15,1.85),(1.4,.8,.05),'coral',.03,(0,.04,.13))
    for x in [.0,1.2]:box('tarp ballast',(x,.15,1.92),(.22,.15,.1),'stone',.02)
    for x in [-1.78,1.78]:
        box('canopy column',(x,-1.7,.85),(.13,.13,1.6),'teal',.02)
        box('column foot',(x,-1.7,.2),(.25,.25,.25),'cream',.035)
    box('floating canopy',(0,-1.54,1.73),(4.45,1.53,.2),'cream',.07)
    box('canopy coral fascia',(0,-2.3,1.72),(4.45,.08,.19),'coral',.025)
    box('canopy teal top',(0,-1.54,1.86),(4.45,1.53,.07),'teal',.035)
    for x in [-1.02,1.02]:
        box('fuel island',(x,-1.68,.16),(.78,.7,.15),'stone',.06)
        box('retro fuel pump body',(x,-1.68,.62),(.49,.4,.79),'coral',.09)
        box('fuel pump head',(x,-1.68,1.06),(.56,.43,.4),'cream',.06)
        box('pump dark display',(x,-1.91,1.09),(.34,.02,.16),'black',.02)
        box('pump display gleam',(x-.08,-1.925,1.11),(.12,.012,.025),'teal_light',.002)
        curve('hanging pump hose',[(x+.25,-1.69,1.1),(x+.51,-1.67,.92),(x+.51,-1.7,.38),(x+.28,-1.85,.56)],'rubber',.033)
        box('nozzle',(x+.28,-1.9,.65),(.09,.09,.2),'iron',.015,(0,.3,0))
    cyl('round station crest',(0,-2.36,1.75),.24,.075,'teal_dark',24,(math.pi/2,0,0))
    cyl('crest warm center',(0,-2.407,1.75),.16,.025,'yellow',16,(math.pi/2,0,0))
    for x in [-1.6,-1,1,1.6]:sandbag(x,-2.11,.25)
    barrel(-2.03,.5);crate(2.02,.65,scale=.85)
    box('step',(0,-.83,.17),(.85,.4,.17),'stone',.03)

def shelter():
    box('foundation',(0,0,.1),(2.6,2.3,.2),'stone',.08)
    box('shelter stucco',(0,0,.85),(2.26,1.9,1.5),'plaster',.06)
    roof('thick terracotta roof',2.65,2.3,1.56,.8,'coral')
    for y in [-1.08,-.72,-.36,0,.36,.72,1.08]:
        beam('left roof seam',(-1.3,y,1.6),(0,y,2.38),.045,'rust')
        beam('right roof seam',(0,y,2.38),(1.3,y,1.6),.045,'rust')
    beam('rounded ridge',(0,-1.2,2.39),(0,1.2,2.39),.14,'cream',.12,.035)
    box('chimney',(-.63,.48,2.16),(.36,.38,1.0),'stone',.04)
    box('chimney cap',(-.63,.48,2.68),(.47,.49,.13),'cream',.03)
    box('chimney soot',(-.63,.48,2.755),(.25,.27,.015),'black',.005)
    box('front door',(.36,-.968,.67),(.62,.065,1.18),'teal',.03)
    box('door glass',(.36,-1.009,.91),(.36,.025,.38),'glass',.015)
    sphere('door knob',(.57,-1.03,.59),(.045,.035,.045),'yellow',2)
    box('boarded window',(-.65,-.972,.99),(.6,.06,.58),'glass',.025)
    beam('window plank',(-1,-1.025,.85),(-.31,-1.025,1.08),.12,'wood_light',.06)
    beam('window plank',(-1,-1.05,1.16),(-.31,-1.05,.94),.12,'wood',.06)
    box('porch step',(.36,-1.2,.14),(.86,.42,.22),'wood',.035)
    box('metal roof patch',(.66,.1,2.02),(.88,.7,.035),'teal',.015,(0,.54,0))
    for y in [-.15,.02,.19,.36]:beam('patch rib',(.3,y,2.25),(1.03,y,1.82),.025,'teal_light')
    crate(-1.03,-1.09,scale=.7)

def farm():
    for x in [-.72,.72]:
        for y in [-.72,.5]:
            box('garden bed earth',(x,y,.13),(1.05,.88,.23),'soil',.04)
            for yy in [-.46,.46]:box('raised bed plank',(x,y+yy,.23),(1.15,.07,.28),'wood_light',.02)
            for xx in [-.55,.55]:box('bed end plank',(x+xx,y,.23),(.07,.95,.28),'wood',.02)
            for dx in [-.3,0,.3]:
                for dy in [-.22,.2]:
                    z=.35
                    sphere('chunky cabbage',(x+dx,y+dy,z),(.18,.16,.15),'leaf',1)
                    sphere('cabbage center',(x+dx-.025,y+dy,z+.055),(.10,.10,.11),'leaf_light',1)
    barrel(0,1.22)
    box('seed sack',(-.72,1.18,.19),(.47,.33,.36),'cream',.09)

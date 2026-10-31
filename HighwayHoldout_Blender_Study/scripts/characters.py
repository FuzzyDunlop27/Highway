"""Rounded miniature humans and green zombies, modeled facing world +X."""
import math
from geometry import box,sphere,cyl,beam,rod

def human(armed=False):
    for y in [-.13,.13]:
        box('scuffed boot',(-.05,y,.1),(.33,.17,.18),'wood_dark',.055)
        beam('trouser leg',(-.07,y,.17),(0,y,.44),.15,'denim',.15,.045)
    sphere('padded vest',(0,0,.6),(.23,.28,.31),'coral' if armed else 'teal',2)
    box('vest front',(.19,0,.63),(.08,.4,.3),'wood_light' if armed else 'teal_light',.035)
    for y in [-.14,.14]:box('vest webbing',(.239,y,.63),(.016,.045,.3),'cream',.005)
    box('backpack',(-.22,0,.65),(.22,.37,.44),'teal' if armed else 'coral',.065)
    box('backpack flap',(-.35,0,.74),(.07,.3,.16),'cream',.03)
    sphere('head',(.09,0,1.02),(.22,.21,.23),'skin',2)
    sphere('cap',(.055,0,1.15),(.245,.235,.14),'teal_dark' if armed else 'wood_dark',2)
    box('cap visor',(.27,0,1.14),(.24,.32,.04),'teal',.035)
    sphere('nose',(.285,0,1.02),(.055,.065,.065),'skin',2)
    for y in [-.16,.16]:sphere('ear',(.06,y,1.01),(.07,.07,.085),'skin',2)
    if armed:
        for y,end in [(-.24,(.43,-.14,.68)),(.24,(.32,-.05,.69))]:
            beam('rolled sleeve',(.04,y,.74),(.2,y,.64),.15,'coral',.15,.04)
            beam('forearm',(.2,y,.64),end,.1,'skin',.1,.035)
            sphere('gripping hand',end,(.075,.065,.075),'skin',2)
        box('rifle wooden stock',(.26,-.15,.7),(.28,.09,.11),'wood',.025)
        box('rifle receiver',(.48,-.15,.72),(.22,.1,.13),'iron',.015)
        rod('rifle barrel',(.55,-.15,.75),(.87,-.15,.75),.027,'black')
        box('rifle magazine',(.47,-.15,.61),(.075,.06,.14),'iron',.01,(0,-.15,0))
        box('orange armband',(.09,-.26,.76),(.12,.07,.11),'yellow',.018)
    else:
        for y in [-.24,.24]:
            beam('rolled sleeve',(0,y,.77),(.1,y,.55),.15,'teal',.15,.04)
            beam('exposed forearm',(.1,y,.55),(.28,y,.48),.1,'skin',.1,.025)
            sphere('hand',(.28,y,.48),(.075,.065,.075),'skin',2)
        cyl('canteen',(-.1,.31,.53),.08,.22,'steel',10)

def zombie():
    for y,x in [(-.14,-.16),(.14,.02)]:
        box('worn zombie shoe',(x,y,.09),(.3,.18,.15),'black',.04,(0,0,y*.8))
        beam('torn trouser leg',(x,y,.16),(-.06,y,.44),.16,'purple',.16,.03)
    sphere('hunched body',(-.03,0,.63),(.23,.29,.31),'purple',2)
    box('torn shirt front',(.15,0,.65),(.13,.35,.31),'zombie_dark',.025,(0,.1,0))
    sphere('large lopsided head',(.18,0,1.0),(.26,.24,.27),'zombie',2)
    sphere('uneven scalp',(.06,.01,1.2),(.2,.2,.1),'zombie_dark',1)
    sphere('zombie nose',(.41,0,1),(.055,.06,.065),'zombie',1)
    for y in [-.13,.13]:
        box('sleepy eye socket',(.404,y,1.07),(.018,.06,.04),'zombie_dark',.01)
    for y in [-.27,.27]:
        beam('torn shirt sleeve',(.01,y,.79),(.22,y,.72),.16,'purple',.16,.025)
        beam('reaching forearm',(.22,y,.72),(.61,y*.8,.79),.11,'zombie',.11,.03)
        sphere('cartoon reaching hand',(.65,y*.8,.79),(.12,.09,.075),'zombie',1)
        for yy in [-.035,.035]:rod('blocky finger',(.7,y*.8+yy,.79),(.79,y*.8+yy,.8),.018,'zombie')

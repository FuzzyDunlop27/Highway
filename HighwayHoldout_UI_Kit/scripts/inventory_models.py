"""Fresh dimensional inventory props for the in-game UI."""
import bpy,math
from model_geometry import box,cyl,sphere,beam,rod,mesh,M

def gear(x=0,y=0,z=.2,r=.55,mat='steel'):
    n=48;verts=[]
    for height,inner in [(z-.09,False),(z+.09,False),(z-.09,True),(z+.09,True)]:
        for i in range(n):
            a=i*2*math.pi/n;rr=r*.37 if inner else r*(1 if i%4 in [1,2] else .81)
            verts.append((x+rr*math.cos(a),y+rr*math.sin(a),height))
    faces=[]
    for i in range(n):
        j=(i+1)%n
        faces.extend([(i,j,j+n,i+n),(i+n,j+n,j+3*n,i+3*n),(i+2*n,j+2*n,j,i),(i+3*n,j+3*n,j+2*n,i+2*n)])
    mesh('machined gear',verts,faces,mat,.015)

def food():
    for x,y,z in [(-.33,-.17,.32),(.3,-.04,.32),(-.08,.36,.42)]:
        cyl('sealed ration tin',(x,y,z),.26,.62,'steel',32,bevel=.035)
        cyl('coral paper label',(x,y,z-.015),.265,.37,'coral',32,bevel=.01)
        cyl('tin top rolled lip',(x,y,z+.32),.272,.035,'cream',32)
        cyl('tin lid inset',(x,y,z+.342),.225,.012,'steel',32,bevel=0)
        box('pull tab',(x,y-.045,z+.36),(.14,.065,.02),'iron',.025)
        sphere('simple food emblem',(x,y-.26,z),(.085,.014,.085),'cream',2)

def scrap():
    box('salvage plate',(-.05,0,.07),(1.15,.82,.13),'teal',.055,(0,0,-.18))
    box('cut metal plate',(.13,.15,.18),(.89,.64,.09),'iron',.035,(0,.05,.18))
    gear(-.04,-.06,.34,.49)
    for x,y in [(-.46,-.37),(.47,.23)]:cyl('riveted bolt',(x,y,.17),.055,.08,'cream',6)
    beam('copper rod',(-.52,.43,.15),(.49,.4,.15),.08,'coral')

def wood():
    for i,(x,y,z) in enumerate([(-.12,-.18,.13),(.1,.16,.2),(-.03,-.02,.38)]):
        box('salvaged timber',(x,y,z),(1.2,.27,.2),'wood_light' if i%2 else 'wood',.045,(0,.03,(-1)**i*.12))
        for xx in [-.4,.4]:box('timber binding',(x+xx,y,z+.11),(.07,.28,.035),'teal_dark',.01)

def medicine():
    box('medical case',(0,0,.4),(1.05,.65,.77),'cream',.13)
    box('case middle seam',(0,0,.4),(1.06,.665,.035),'plaster',.02)
    for x in [-.21,.21]:box('handle mount',(x,0,.86),(.1,.14,.22),'teal_dark',.035)
    box('carry handle',(0,0,.95),(.47,.14,.1),'teal',.035)
    box('medical emblem vertical',(0,-.337,.42),(.17,.035,.42),'coral',.025)
    box('medical emblem horizontal',(0,-.34,.42),(.42,.035,.17),'coral',.025)
    for x in [-.33,.33]:box('brass catch',(x,-.34,.74),(.11,.065,.13),'yellow',.02)

def fuel():
    box('jerrycan',(0,0,.5),(.87,.53,1.03),'coral',.12)
    for x in [-.19,.19]:box('handle support',(x,0,1.08),(.1,.17,.32),'rust',.025)
    box('jerrycan handle',(0,0,1.22),(.48,.18,.11),'coral',.035)
    cyl('fuel cap',(-.29,-.03,1.08),.14,.1,'iron',12)
    for a,b in [((-.3,-.28,.24),(.3,-.28,.79)),((.3,-.28,.24),(-.3,-.28,.79))]:beam('pressed diagonal',a,b,.055,'rust',.03)
    sphere('fuel medallion',(0,-.3,.5),(.15,.025,.19),'yellow',2)

def ammo():
    box('ammunition box',(0,0,.19),(1.1,.64,.36),'teal_dark',.07)
    box('box lid lip',(0,0,.38),(1.15,.68,.09),'teal',.025)
    for x in [-.32,0,.32]:
        cyl('brass shell',(x,0,.73),.115,.65,'yellow',16)
        cyl('shell base',(x,0,.43),.13,.065,'wood',16)
        bpy.ops.mesh.primitive_cone_add(vertices=16,radius1=.115,radius2=.035,depth=.25,location=(x,0,1.18))
        bpy.context.object.name='rounded bullet tip';bpy.context.object.data.materials.append(M['coral'])
    box('box clasp',(0,-.35,.24),(.2,.05,.16),'cream',.025)

def tools():
    box('tool roll',(0,0,.14),(1.03,.84,.27),'teal',.09)
    for x in [-.32,.32]:box('canvas strap',(x,0,.29),(.09,.86,.05),'cream',.02)
    beam('hammer handle',(-.45,-.37,.34),(.35,.38,.34),.13,'wood_light',.13,.035)
    box('hammer head',(.34,.4,.39),(.49,.23,.23),'steel',.05,(0,0,-.8))
    beam('wrench shaft',(-.32,.4,.43),(.39,-.33,.43),.12,'cream',.08,.025)
    cyl('wrench end',(-.34,.42,.43),.18,.09,'steel',10)
    cyl('wrench opening',(-.34,.42,.48),.08,.015,'iron',6)

def knowledge():
    box('field manual cover',(0,0,.14),(1.13,.88,.18),'teal',.04,(0,0,-.1))
    box('page block',(0,0,.25),(1.02,.78,.15),'paper',.025,(0,0,-.1))
    box('open left pages',(-.26,-.01,.37),(.51,.81,.07),'cream',.025,(0,-.15,-.1))
    box('open right pages',(.27,-.07,.37),(.51,.81,.07),'paper',.025,(0,.15,-.1))
    box('cloth bookmark',(.3,-.2,.43),(.12,.57,.015),'coral',.005,(0,.1,-.1))
    for y in [-.21,-.05,.11]:box('embossed rule',(-.25,y,.43),(.25,.012,.012),'plaster',.002,(0,0,-.1))

def water():
    box('canteen body',(0,0,.43),(.83,.55,.83),'teal',.2)
    box('canteen webbing',(0,-.286,.42),(.15,.035,.77),'cream',.02)
    cyl('neck',(0,0,.89),.16,.18,'teal_light',16)
    cyl('screw cap',(0,0,1.02),.19,.12,'iron',12)
    for x in [-.46,.46]:rod('strap loop',(x,0,.64),(x,0,.82),.055,'wood')
    box('cap highlight',(0,-.19,1.02),(.13,.018,.05),'steel',.01)

def battery():
    for x,y,z in [(-.24,.12,.43),(.27,-.12,.38)]:
        cyl('battery body',(x,y,z),.22,.72,'teal_dark',24)
        cyl('battery copper sleeve',(x,y,z+.14),.224,.4,'coral',24)
        cyl('battery top',(x,y,z+.375),.2,.045,'steel',24)
        cyl('positive terminal',(x,y,z+.42),.08,.065,'cream',12)
        box('positive mark vertical',(x,y-.223,z+.11),(.045,.018,.2),'cream',.007)
        box('positive mark horizontal',(x,y-.226,z+.11),(.16,.018,.045),'cream',.007)

def cloth():
    for z,w,d,mat in [(.12,1.05,.78,'teal_dark'),(.3,.98,.71,'teal'),(.48,.86,.65,'cream')]:
        box('folded canvas',(0,0,z),(w,d,.22),mat,.075)
        box('fold seam',(0,-d/2-.002,z-.035),(w-.15,.014,.025),'plaster' if mat=='cream' else 'teal_light',.005)
    box('rolled strap',(0,0,.62),(.12,.7,.06),'coral',.02)

def radio():
    box('field radio',(0,0,.45),(.81,.48,.91),'teal_dark',.09)
    box('speaker plate',(0,-.25,.37),(.56,.04,.41),'iron',.04)
    for z in [.24,.31,.38,.45]:box('speaker slot',(0,-.28,z),(.43,.02,.022),'steel',.006)
    box('radio glass',(0,-.257,.71),(.5,.025,.17),'glass_light',.02)
    box('tuning stripe',(.1,-.273,.71),(.025,.012,.12),'yellow',.002)
    for x in [-.2,.2]:cyl('control knob',(x,0,.95),.085,.12,'black',12)
    rod('telescoping antenna',(-.25,.07,1),(-.34,.07,1.53),.025,'steel')

def portrait(armed=False):
    cyl('profile medallion',(0,0,.08),.57,.14,'teal_dark',32)
    sphere('jacket shoulders',(0,0,.39),(.49,.27,.32),'coral' if armed else 'teal',2)
    box('jacket collar',(0,-.1,.57),(.29,.15,.13),'cream',.03)
    sphere('head',(0,0,.87),(.27,.25,.3),'skin',2)
    sphere('cap crown',(0,.025,1.08),(.3,.28,.15),'teal_dark' if armed else 'wood_dark',2)
    box('cap peak',(0,-.24,1.08),(.46,.3,.045),'teal' if armed else 'wood',.045)
    sphere('nose',(0,-.245,.87),(.075,.06,.07),'skin',2)
    if armed:
        beam('rifle across chest',(-.37,-.29,.3),(.4,-.29,.65),.095,'wood',.08,.025)
        rod('rifle barrel',(.3,-.29,.6),(.57,-.29,.75),.028,'iron')

MODELS={'food':food,'scrap':scrap,'wood':wood,'medicine':medicine,'fuel':fuel,'ammo':ammo,
        'tools':tools,'knowledge':knowledge,'water':water,'battery':battery,'cloth':cloth,'radio':radio,
        'survivors':lambda:portrait(False),'defender':lambda:portrait(True)}

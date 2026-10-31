"""Lighting, cameras and a roadside diorama for evaluating the fresh 3D style."""
import bpy,math,random
from geometry import box,cyl,mesh,instance,point_camera
from buildings import sandbag,crate,barrel
from props import grass,rubble,dead_tree

def light(scene,name,loc,energy,size,color=(1,1,1)):
    data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.shape='DISK';data.size=size;data.color=color
    ob=bpy.data.objects.new(name,data);scene.collection.objects.link(ob);ob.location=loc;point_camera(ob,(0,0,0));return ob

def camera(scene,name,loc,target,scale):
    data=bpy.data.cameras.new(name);data.type='ORTHO';data.ortho_scale=scale;data.lens=45
    ob=bpy.data.objects.new(name,data);scene.collection.objects.link(ob);ob.location=loc;point_camera(ob,target);scene.camera=ob;return ob

def setup(scene,transparent=False,samples=32):
    scene.render.engine='CYCLES';scene.cycles.samples=samples;scene.cycles.use_denoising=True
    scene.cycles.max_bounces=5;scene.cycles.diffuse_bounces=3;scene.cycles.glossy_bounces=2
    scene.render.film_transparent=transparent
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
    scene.render.image_settings.color_depth='8';scene.render.resolution_percentage=100
    scene.view_settings.view_transform='AgX'
    scene.view_settings.look='AgX - Medium High Contrast';scene.view_settings.exposure=.5
    world=bpy.data.worlds.new(scene.name+' ambient');world.use_nodes=True
    world.node_tree.nodes['Background'].inputs[0].default_value=(.31,.39,.42,1)
    world.node_tree.nodes['Background'].inputs[1].default_value=.5;scene.world=world
    light(scene,'large warm skylight',(-5,-7,12),1800,7,(1,.87,.72))
    light(scene,'cool fill',(5,2,8),1000,6,(.68,.83,1))
    light(scene,'roof rim',(0,6,10),1300,5,(1,.82,.58))

def diorama(models):
    # Solid miniature island and inset highway; the presentation owns its shadows.
    box('earth cutaway plinth',(0,0,-.33),(13.1,9.9,.62),'soil',.22)
    box('dusty island surface',(0,0,-.025),(13,9.8,.16),'dirt',.2)
    box('back grass parcel',(-.1,1.1,.07),(12.6,6.8,.12),'grass',.16)
    box('highway ribbon',(0,-3.17,.09),(13.03,2.88,.12),'asphalt',.06)
    for x in [-5.6,-3.9,-2.2,-.5,1.2,2.9,4.6]:box('faded center dash',(x,-3.18,.155),(.78,.065,.013),'roadpaint',.012)
    for y in [-4.4,-1.94]:box('highway shoulder stripe',(0,y,.155),(12.6,.04,.012),'roadpaint',.005)
    box('service apron',(-2.7,.25,.14),(5.25,4.3,.13),'stone',.08)
    instance(models['bld_hq'],'OUTPOST headquarters',(-2.75,.85,.19),scale=.94)
    instance(models['bld_shelter'],'SURVIVOR cottage',(2.35,2.55,.16),angle=-.12,scale=.95)
    instance(models['bld_farm'],'COMMUNITY garden',(5,1.1,.14),angle=.08,scale=.74)
    instance(models['def_watchtower_base'],'GUARD watchtower',(1.1,-.55,.16),scale=1.02)
    instance(models['def_watchtower_gunner'],'TOWER sentry',(1.1,-.55,2.26),angle=-.6,scale=.74)
    for x in [2.6,4.18,5.76]:instance(models['def_wall_wood'],'TIMBER front defense',(x,-1.22,.13))
    for y in [.15,1.65]:instance(models['def_wall_wood'],'TIMBER side defense',(6.1,y,.13),math.pi/2)
    instance(models['dec_car_wreck'],'SALVAGED sedan',(-.2,-3.52,.17),angle=.12,scale=.88)
    instance(models['unit_survivor'],'WORKER with backpack',(-.15,1.1,.18),angle=-.6,scale=.9)
    instance(models['unit_defender'],'DEFENDER at gate',(1.4,-2.17,.18),angle=.08,scale=.94)
    for i,(x,y,a) in enumerate([(4.6,-3.8,2.8),(3.25,-3.05,3),(5.5,-2.55,3.4)]):
        instance(models['zmb_walker'],'APPROACHING walker '+str(i),(x,y,.17),a,.92)
    for x in [-5.5,-4.9,-4.3]:sandbag(x,-1.65,.28)
    crate(-5.68,.05,.17);crate(-5.6,.7,.17,1.1);barrel(-.16,3.95)
    rng=random.Random(44)
    for i in range(56):
        x,y=rng.uniform(-6.25,6.25),rng.uniform(-1.5,4.6)
        if -5.4<x<-.1 and -1.5<y<3.2:continue
        grass(x,y,.18,rng.uniform(.6,1.1))
    for x,y in [(-5.8,3.5),(.05,3.6),(5.8,-1.5),(-4.7,-4.35)]:rubble(x,y)
    # Dead tree at the edge; build locally then translate its newly made meshes.
    old=set(bpy.data.objects);dead_tree()
    for o in set(bpy.data.objects)-old:o.location.x-=5.8;o.location.y+=3.7;o.location.z+=.15
    box('studio floor',(0,0,-.79),(200,200,.2),'teal_dark',0)

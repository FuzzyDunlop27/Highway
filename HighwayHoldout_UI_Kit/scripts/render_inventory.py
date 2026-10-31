"""Render editable Blender inventory icons on transparent canvases."""
import bpy,sys,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts'))
from model_geometry import init_materials,capture,point_camera
from inventory_models import MODELS

bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
init_materials();scene=bpy.context.scene;scene.name='Inventory icon studio'
scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=True
scene.cycles.max_bounces=5;scene.render.film_transparent=True
scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
scene.view_settings.view_transform='AgX';scene.view_settings.look='AgX - Medium High Contrast';scene.view_settings.exposure=.25
world=bpy.data.worlds.new('cool studio');world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.36,.43,.48,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.4;scene.world=world
for name,loc,power,size,color in [('key',(-3,-4,7),550,4,(1,.9,.76)),('fill',(4,-1,4),280,3,(.7,.85,1)),('rim',(0,4,6),650,3,(1,.87,.65))]:
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.size=size;data.color=color
    ob=bpy.data.objects.new(name,data);scene.collection.objects.link(ob);ob.location=loc;point_camera(ob,(0,0,.5))
camdata=bpy.data.cameras.new('UI orthographic camera');camdata.type='ORTHO'
camera=bpy.data.objects.new('UI orthographic camera',camdata);scene.collection.objects.link(camera);scene.camera=camera
records=[];models=[]
for key,fn in MODELS.items():
    col=capture('ui_item_'+key,fn);models.append(col)
    bpy.context.view_layer.update()
    camera.location=(4,-6,4.6);point_camera(camera,(0,0,.5))
    inv=camera.rotation_euler.to_matrix().transposed()
    pts=[inv@(o.matrix_world@Vector(v)) for o in col.objects if o.type=='MESH' for v in o.bound_box]
    xmin,xmax=min(p.x for p in pts),max(p.x for p in pts);ymin,ymax=min(p.y for p in pts),max(p.y for p in pts)
    # Fit with a generous consistent safety margin and center the visible object.
    camera.location=(4,-6,4.6)
    center=camera.rotation_euler.to_matrix()@Vector(((xmin+xmax)/2,(ymin+ymax)/2,0))
    initial=inv@camera.location
    camera.location+=camera.rotation_euler.to_matrix()@Vector((-initial.x,-initial.y,0))+center
    camdata.ortho_scale=max(xmax-xmin,ymax-ymin)*1.22
    name='ui_item_'+key;scene.render.filepath=str(ROOT/'png'/f'{name}.png')
    print('RENDER',name,flush=True);bpy.ops.render.render(write_still=True)
    records.append(dict(name=name,width=512,height=512,category='item',template=False,description=key.capitalize()+' dimensional inventory icon'))
    col.hide_render=True
models[0].hide_render=False
camera.location=(4,-6,4.6);point_camera(camera,(0,0,.5));camdata.ortho_scale=1.9
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source_blender/Inventory_Icons.blend'))
(ROOT/'reference/item_assets.json').write_text(json.dumps(records,indent=2)+'\n')
print('INVENTORY_ICONS_COMPLETE',flush=True)

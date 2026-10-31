"""Render generous three-quarter thumbnails from the Blender study models."""
import bpy,sys,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts'))
from model_geometry import point_camera
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.name='Build-menu thumbnail studio'
scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=True;scene.cycles.max_bounces=5
scene.render.film_transparent=True;scene.render.resolution_x=512;scene.render.resolution_y=384;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
scene.view_settings.view_transform='AgX';scene.view_settings.look='AgX - Medium High Contrast';scene.view_settings.exposure=.35
w=bpy.data.worlds.new('UI sky');w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.32,.4,.45,1)
w.node_tree.nodes['Background'].inputs[1].default_value=.45;scene.world=w
for name,loc,energy,size,color in [('key',(-5,-7,10),1300,6,(1,.87,.72)),('fill',(5,1,8),850,5,(.7,.85,1)),('rim',(0,6,9),1000,5,(1,.85,.65))]:
    data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.size=size;data.color=color
    ob=bpy.data.objects.new(name,data);scene.collection.objects.link(ob);ob.location=loc;point_camera(ob,(0,0,.5))
data=bpy.data.cameras.new('Menu thumbnail camera');data.type='ORTHO';camera=bpy.data.objects.new('Menu thumbnail camera',data);scene.collection.objects.link(camera);scene.camera=camera
records=[];loaded=[]
for key,source in [('hq','bld_hq'),('shelter','bld_shelter'),('farm','bld_farm'),('watchtower','def_watchtower_base'),('wall','def_wall_wood')]:
    library=ROOT.parent/'HighwayHoldout_Blender_Study/models'/f'{source}.blend'
    if not library.exists():library=ROOT/'source_blender/Build_Menu_Models.blend'
    with bpy.data.libraries.load(str(library),link=False) as (src,dst):dst.collections=[source]
    col=dst.collections[0];scene.collection.children.link(col);loaded.append(col);bpy.context.view_layer.update()
    camera.location=(6,-8,6);point_camera(camera,(0,0,.5));inv=camera.rotation_euler.to_matrix().transposed()
    pts=[inv@(o.matrix_world@Vector(v)) for o in col.objects if o.type=='MESH' for v in o.bound_box]
    xmin,xmax=min(p.x for p in pts),max(p.x for p in pts);ymin,ymax=min(p.y for p in pts),max(p.y for p in pts)
    initial=inv@camera.location
    camera.location+=camera.rotation_euler.to_matrix()@Vector(((xmin+xmax)/2-initial.x,(ymin+ymax)/2-initial.y,0))
    data.ortho_scale=max(xmax-xmin,(ymax-ymin)*4/3)*1.16
    name='ui_build_'+key;scene.render.filepath=str(ROOT/'png'/f'{name}.png')
    print('RENDER',name,flush=True);bpy.ops.render.render(write_still=True)
    records.append(dict(name=name,width=512,height=384,logical_width=256,logical_height=192,category='building_thumbnail',template=False,description=key.capitalize()+' three-quarter menu illustration'))
    col.hide_render=True
loaded[0].hide_render=False
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source_blender/Build_Menu_Models.blend'))
(ROOT/'reference/build_assets.json').write_text(json.dumps(records,indent=2)+'\n')

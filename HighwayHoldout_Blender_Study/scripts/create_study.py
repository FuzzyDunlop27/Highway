"""Build and render the new Blender art study. Run with Blender --python."""
import bpy,sys,math,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from geometry import init_materials,capture,instance,point_camera
import buildings,props,characters,staging

bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
init_materials()
makers={
    'bld_hq':buildings.hq,'bld_shelter':buildings.shelter,'bld_farm':buildings.farm,
    'def_watchtower_base':props.tower,'def_wall_wood':props.wall,'dec_car_wreck':props.car,
    'unit_survivor':lambda:characters.human(False),'unit_defender':lambda:characters.human(True),
    'def_watchtower_gunner':lambda:characters.human(True),'zmb_walker':characters.zombie,
}
models={}
for name,fn in makers.items():
    col=capture(name,fn);col.use_fake_user=True
    bpy.context.scene.collection.children.unlink(col);models[name]=col
    print('MODELED',name,flush=True)

scene=bpy.context.scene;scene.name='01_ROADSIDE_DIORAMA'
staging.setup(scene,samples=48);staging.diorama(models)
staging.camera(scene,'Diorama hero camera',(13,-18,16),(0,.2,.5),17.8)
scene.render.resolution_x=1600;scene.render.resolution_y=1200
scene.render.filepath=str(ROOT/'renders/01_roadside_diorama.png')

sprite_scene=bpy.data.scenes.new('02_TRANSPARENT_SPRITE_STAGE')
staging.setup(sprite_scene,transparent=True,samples=32)
sprite_camera=staging.camera(sprite_scene,'Orthographic sprite camera',(0,-7,14),(0,0,.6),5.5)

# Keep a named model library and two useful camera stages in the editable file.
bpy.context.window.scene=scene
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'HighwayHoldout_Blender_Study.blend'))
print('RENDERING hero',flush=True)
bpy.ops.render.render(write_still=True,scene=scene.name)

definitions=[
    ('bld_hq',384,384,False),('bld_shelter',256,256,False),('bld_farm',256,256,False),
    ('def_watchtower_base',128,128,True),('def_wall_wood',128,128,False),
    ('dec_car_wreck',256,128,True),('unit_survivor',128,128,True),
    ('unit_defender',128,128,True),('def_watchtower_gunner',128,128,True),('zmb_walker',128,128,True),
]
assets=[]
for name,w,h,overhead in definitions:
    bpy.context.window.scene=sprite_scene
    ob=bpy.data.objects.new('ACTIVE '+name,None);sprite_scene.collection.objects.link(ob)
    ob.instance_type='COLLECTION';ob.instance_collection=models[name]
    top=name.startswith(('unit_','zmb_')) or name=='def_watchtower_gunner'
    sprite_camera.location=(0,0,14) if overhead else (0,-7,14)
    point_camera(sprite_camera,(0,0,0))
    if top:
        # A fixed camera center and extent maintain common east-facing pivots.
        sprite_camera.data.ortho_scale=2.25
    elif name=='def_watchtower_base':
        sprite_camera.data.ortho_scale=2.25
    else:
        # Fit projected geometry to the existing aspect ratio with breathing room.
        inverse=sprite_camera.rotation_euler.to_matrix().transposed()
        pts=[inverse@(o.matrix_world@Vector(v)) for o in models[name].objects if o.type=='MESH' for v in o.bound_box]
        xmin,xmax=min(p.x for p in pts),max(p.x for p in pts)
        ymin,ymax=min(p.y for p in pts),max(p.y for p in pts)
        center=sprite_camera.rotation_euler.to_matrix()@Vector(((xmin+xmax)/2,(ymin+ymax)/2,0))
        sprite_camera.location+=center
        sprite_camera.data.ortho_scale=max(xmax-xmin,(ymax-ymin)*w/h)*1.12
    sprite_scene.render.resolution_x=w*2;sprite_scene.render.resolution_y=h*2
    sprite_scene.render.filepath=str(ROOT/'renders'/f'{name}_2x.png')
    print('RENDERING sprite',name,flush=True)
    bpy.ops.render.render(write_still=True,scene=sprite_scene.name)
    assets.append(dict(name=name,width=w,height=h,facing='east' if top or name=='dec_car_wreck' else None,
        anchor=[.5,.5],camera='pure overhead' if overhead else 'orthographic 26.6 degrees from vertical'))
    bpy.data.objects.remove(ob,do_unlink=True)

bpy.context.window.scene=scene
# Save independent editable object collections for future art iteration.
for name,col in models.items():bpy.data.libraries.write(str(ROOT/'models'/f'{name}.blend'),{col},fake_user=True)
(ROOT/'manifest.json').write_text(json.dumps({'title':'Highway Holdout — fresh Blender style study','assets':assets,
    'status':'10 sample assets; not the full Phase 1 pack','renderer':'Blender Cycles','source':'Original procedural mesh modeling; no v1/v2 geometry or images reused'},indent=2)+'\n')
print('BLENDER_STUDY_COMPLETE',flush=True)

"""Blender-native modeling helpers and the miniature material palette."""
import bpy, math
from mathutils import Vector

M={}
COLORS={
    'cream':'E8D8B7','plaster':'CBBDA3','teal':'3A7C7A','teal_light':'66ADA4',
    'teal_dark':'245252','coral':'C96547','rust':'944D36','yellow':'FFCA65',
    'wood':'A87143','wood_light':'D4A66A','wood_dark':'604638','iron':'3B4C52',
    'steel':'809798','glass':'325765','glass_light':'659095','black':'242C31',
    'rubber':'30363A','grass':'76816A','grass_light':'A0AB77','soil':'85735B',
    'dirt':'AE9574','asphalt':'555D62','roadpaint':'D9C28A','stone':'A4A497',
    'leaf':'5A8760','leaf_light':'9AB675','zombie':'98B67E','zombie_dark':'607C5B',
    'purple':'655D77','denim':'465D70','skin':'D9B28C','paper':'E8E1CD',
}

def material(name,hexcode,rough=.8,metallic=0,emission=0):
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    rgb=[int(hexcode[i:i+2],16)/255 for i in (0,2,4)]
    # Hex palette is sRGB; Principled inputs expect linear values.
    rgb=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
    bs=mat.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(*rgb,1)
    bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=metallic
    if emission:
        bs.inputs['Emission Color'].default_value=(*rgb,1)
        bs.inputs['Emission Strength'].default_value=emission
    mat.diffuse_color=(*rgb,1)
    return mat

def init_materials():
    for n,c in COLORS.items():M[n]=material(n,c,.45 if n.startswith('glass') else .82,.25 if n in ['steel','iron'] else 0)
    M['glow']=material('warm amber lamps','FFD488',.35,0,.7)

def finish(o,name,mat,bevel=0):
    o.name=name;o.data.materials.append(M[mat])
    if bevel:
        mod=o.modifiers.new('soft miniature edges','BEVEL');mod.width=bevel;mod.segments=2
        mod.affect='EDGES'
        mod=o.modifiers.new('weighted corner normals','WEIGHTED_NORMAL')
    return o

def box(name,loc,dim,mat,bevel=.04,rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    o=bpy.context.object;o.dimensions=dim
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if rot:o.rotation_euler=rot
    return finish(o,name,mat,bevel)

def cyl(name,loc,r,depth,mat,vertices=12,rot=None,bevel=.02):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=loc)
    o=bpy.context.object
    if rot:o.rotation_euler=rot
    return finish(o,name,mat,bevel)

def sphere(name,loc,scale,mat,sub=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=loc)
    o=bpy.context.object;o.scale=scale
    return finish(o,name,mat)

def beam(name,a,b,width,mat,depth=None,bevel=.01):
    a,b=Vector(a),Vector(b);v=b-a
    o=box(name,(a+b)/2,(width,depth or width,v.length),mat,bevel)
    o.rotation_euler=v.to_track_quat('Z','Y').to_euler();return o

def rod(name,a,b,r,mat,vertices=8):
    a,b=Vector(a),Vector(b);v=b-a
    o=cyl(name,(a+b)/2,r,v.length,mat,vertices,bevel=0)
    o.rotation_euler=v.to_track_quat('Z','Y').to_euler();return o

def mesh(name,verts,faces,mat,bevel=0):
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
    o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o)
    return finish(o,name,mat,bevel)

def curve(name,pts,mat,r=.03):
    cu=bpy.data.curves.new(name,'CURVE');cu.dimensions='3D';cu.bevel_depth=r;cu.bevel_resolution=1
    spl=cu.splines.new('BEZIER');spl.bezier_points.add(len(pts)-1)
    for p,v in zip(spl.bezier_points,pts):p.co=v;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
    ob=bpy.data.objects.new(name,cu);bpy.context.collection.objects.link(ob);ob.data.materials.append(M[mat]);return ob

def roof(name,w,d,z,peak,mat):
    return mesh(name,[(-w/2,-d/2,z),(w/2,-d/2,z),(w/2,d/2,z),(-w/2,d/2,z),
                      (0,-d/2,z+peak),(0,d/2,z+peak)],
                [(0,1,4),(3,5,2),(0,4,5,3),(4,1,2,5),(0,3,2,1)],mat,.025)

def capture(name,fn):
    """Store a model at the origin in its own library collection."""
    before=set(bpy.data.objects);fn();parts=set(bpy.data.objects)-before
    col=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(col)
    for o in parts:
        for c in list(o.users_collection):c.objects.unlink(o)
        col.objects.link(o)
    return col

def instance(collection,name,loc=(0,0,0),angle=0,scale=1):
    ob=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(ob)
    ob.instance_type='COLLECTION';ob.instance_collection=collection;ob.location=loc
    ob.rotation_euler[2]=angle;ob.scale=(scale,)*3
    return ob

def point_camera(camera,target):
    camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()

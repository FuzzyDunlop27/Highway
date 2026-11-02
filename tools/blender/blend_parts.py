# Purpose: Loads single objects out of Poly Haven .blend downloads (fence pieces, foliage with see-through leaves). Notes: docs/features/models-3d.md
# Some Poly Haven assets only keep their see-through (alpha) texture in the .blend, not in the glTF, so they are taken
# from there. Same rules as model_kit.prop: real metres, origin at the footprint's ground middle, one shared template.
import os

import bpy

import model_kit


def _fix_image_paths(base):
    """Appended images keep '//textures/…' paths relative to the source .blend; point them at the real files."""
    for image in bpy.data.images:
        path = image.filepath
        if path.startswith('//') and not os.path.exists(bpy.path.abspath(path)):
            image.filepath = os.path.join(base, path[2:])
            image.reload()


def _cutout_material(asset, base):
    """Plain leaf material: diffuse colour + alpha cut out at 0.5. The .blend's own node setup is too complex for the
    USD exporter (it wired the normal map in as colour); a Greater Than node is exported as opacityThreshold."""
    name = 'cutout_' + asset
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes['Principled BSDF']
    bsdf.inputs['Roughness'].default_value = 0.9
    textures = os.path.join(base, 'textures')
    diff = nodes.new('ShaderNodeTexImage')
    diff.image = bpy.data.images.load(os.path.join(textures, f'{asset}_diff_1k.jpg'), check_existing=True)
    alpha = nodes.new('ShaderNodeTexImage')
    alpha.image = bpy.data.images.load(os.path.join(textures, f'{asset}_alpha_1k.png'), check_existing=True)
    alpha.image.colorspace_settings.name = 'Non-Color'
    clip = nodes.new('ShaderNodeMath')
    clip.operation = 'GREATER_THAN'
    clip.inputs[1].default_value = 0.5
    links.new(diff.outputs['Color'], bsdf.inputs['Base Color'])
    links.new(alpha.outputs['Color'], clip.inputs[0])
    links.new(clip.outputs['Value'], bsdf.inputs['Alpha'])
    return mat


def _template(asset, object_name, cutout):
    key = 'blend_' + object_name
    if key in model_kit._templates:
        return model_kit._templates[key]
    base = model_kit.prop_folder(asset)
    blend = next(os.path.join(base, f) for f in os.listdir(base) if f.endswith('.blend'))
    with bpy.data.libraries.load(blend, link=False) as (_, loaded):
        loaded.objects = [object_name]
    obj = loaded.objects[0]
    bpy.context.scene.collection.objects.link(obj)
    _fix_image_paths(base)
    if cutout:
        obj.data.materials.clear()
        obj.data.materials.append(_cutout_material(asset, base))
    obj.parent = None
    obj.location = (0, 0, 0)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    xs, ys, zs = zip(*(v.co for v in obj.data.vertices))
    shift = ((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, min(zs))
    for v in obj.data.vertices:
        v.co.x -= shift[0]
        v.co.y -= shift[1]
        v.co.z -= shift[2]
    obj.name = 'tpl_' + key
    obj.hide_render = obj.hide_viewport = True
    model_kit._templates[key] = obj
    return obj


def blend_part(asset, object_name, x=0.0, y=0.0, z=0.0, turn=0.0, scale=1.0, tilt=(0.0, 0.0), cutout=False):
    """One object from the .blend in Poly Haven folder `asset`, placed like model_kit.prop. `cutout` swaps its
    material for a plain diffuse + alpha cut-out one (foliage)."""
    return model_kit.place(_template(asset, object_name, cutout), x, y, z, turn, scale, tilt)

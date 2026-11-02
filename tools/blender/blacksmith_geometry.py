# Purpose: Build the blacksmith apron, beard and draft materials. Notes: docs/features/characters-3d.md
import math
import bpy
from mathutils import Vector


def material(name, dark, light=None, scale=35):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*dark, 1)
    bsdf.inputs['Roughness'].default_value = .86
    if light:
        noise = nodes.new('ShaderNodeTexNoise')
        noise.inputs['Scale'].default_value = scale
        noise.inputs['Detail'].default_value = 3
        ramp = nodes.new('ShaderNodeValToRGB')
        ramp.color_ramp.elements[0].color = (*dark, 1)
        ramp.color_ramp.elements[1].color = (*light, 1)
        links.new(noise.outputs['Fac'], ramp.inputs[0])
        links.new(ramp.outputs[0], bsdf.inputs['Base Color'])
    return mat


def assign(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.material_index = 0
        poly.use_smooth = True


def front_y(objects, x, z, fallback=-.14):
    hits = []
    for obj in objects:
        hit, point, _, _ = obj.ray_cast(Vector((x, -2, z)), Vector((0, 1, 0)))
        if hit:
            hits.append(point.y)
    return min(hits) if hits else fallback


def tube(name, points, radius, mat):
    curve = bpy.data.curves.new(name, 'CURVE')
    curve.dimensions = '3D'
    curve.resolution_u = 1
    curve.bevel_depth = radius
    curve.bevel_resolution = 1
    spline = curve.splines.new('POLY')
    spline.points.add(len(points) - 1)
    for p, co in zip(spline.points, points):
        p.co = (*co, 1)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target='MESH')
    obj.select_set(False)
    return obj


def apron(objects, height, leather, strap):
    # The bib narrows toward the chest and flares across the thighs.
    rows = [(.39, .092), (.43, .097), (.48, .093), (.54, .085),
            (.60, .078), (.67, .066), (.73, .054), (.79, .046)]
    verts, faces = [], []
    for z_ratio, half_width in rows:
        z = z_ratio * height
        # Keep each row in front of the fullest part of shirt/trousers, bridging
        # the crotch instead of folding into the gap between the two legs.
        front = min(front_y(objects, (i / 4 - 1) * half_width * height, z)
                    for i in range(9)) - .035
        for i in range(9):
            x = (i / 4 - 1) * half_width * height
            verts.append((x, front, z))
    for j in range(len(rows) - 1):
        for i in range(8):
            # Small central split at the hem for walking clearance.
            if j == 0 and i in (3, 4):
                continue
            a = j * 9 + i
            faces.append((a, a + 1, a + 10, a + 9))
    mesh = bpy.data.meshes.new('Leather apron surface')
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new('Split leather apron', mesh)
    bpy.context.collection.objects.link(obj)
    assign(obj, leather)
    solid = obj.modifiers.new('Leather thickness', 'SOLIDIFY')
    solid.thickness = .004
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=solid.name)
    # A loop around the neck and a belt around the waist; small hand props stay separate.
    for side in (-1, 1):
        points = []
        for xr, zr in [(side * .04, .79), (side * .048, .82), (side * .04, .855)]:
            x, z = xr * height, zr * height
            points.append((x, front_y(objects, x, z) - .018, z))
        tube('Apron neck strap', points, .009, strap)
    belt = []
    for i in range(33):
        angle = i * math.tau / 32
        radial = Vector((math.sin(angle), math.cos(angle), 0))
        origin = radial * 2 + Vector((0, 0, .61 * height))
        points = []
        for mesh_obj in objects:
            hit, point, _, _ = mesh_obj.ray_cast(origin, -radial)
            if hit:
                points.append(point)
        surface = min(points, key=lambda p: (p - origin).length) if points else radial * .15 + Vector((0, 0, .61 * height))
        belt.append(tuple(surface + radial * .012))
    tube('Leather waist belt', belt, .010, strap)
    return obj


def beard(body, height, mat):
    # Close-fitting shell follows actual chin/cheeks, avoiding an unrelated primitive head.
    verts, faces, lookup = [], [], {}
    for poly in body.data.polygons:
        centre = poly.center
        if not (.881 * height < centre.z < .927 * height and centre.y < -.020
                and abs(centre.x) < .061 * height):
            continue
        cheek_top = height * (.908 + min(abs(centre.x) / (.05 * height), 1) * .018)
        moustache = .915 * height < centre.z < .922 * height and abs(centre.x) < .024 * height
        if centre.z > cheek_top and not moustache:
            continue
        idx = []
        for vi in poly.vertices:
            if vi not in lookup:
                vertex = body.data.vertices[vi]
                position = vertex.co + vertex.normal * .006
                lookup[vi] = len(verts)
                verts.append(tuple(position))
            idx.append(lookup[vi])
        faces.append(tuple(idx))
    mesh = bpy.data.meshes.new('Close cropped beard')
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new('Greyrun short beard', mesh)
    bpy.context.collection.objects.link(obj)
    assign(obj, mat)
    return obj

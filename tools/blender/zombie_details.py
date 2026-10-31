# Purpose: Costume, facial sculpt and surface detail for zombie miniatures. Notes: docs/features/rendering-art.md
import bpy
from geometry import box, sphere, beam, rod, M, material


def surfaces():
    """Local materials: keep other models' shared palette untouched."""
    for name, color in [('dead_skin', '829780'), ('bruise', '505965'),
                        ('dirty_teal', '315F60'), ('faded_red', '934F40'),
                        ('work_canvas', '78684A'), ('dead_eye', 'D9D5A1')]:
        if name in M:
            continue
        mat = material(name, color)
        nodes = mat.node_tree.nodes
        noise = nodes.new('ShaderNodeTexNoise')
        noise.inputs['Scale'].default_value = 38
        noise.inputs['Detail'].default_value = 3
        bump = nodes.new('ShaderNodeBump')
        bump.inputs['Strength'].default_value = .22
        bump.inputs['Distance'].default_value = .035
        mat.node_tree.links.new(noise.outputs['Fac'], bump.inputs['Height'])
        mat.node_tree.links.new(bump.outputs['Normal'], nodes.get('Principled BSDF').inputs['Normal'])
        M[name] = mat


def face(x, z, scale=1):
    s = scale
    for y in (-.105*s, .105*s):
        sphere('sunken orbital ridge', (x-.025*s,y,z+.055*s), (.045*s,.075*s,.07*s), 'bruise', 2)
        sphere('clouded dead eye', (x+.011*s,y,z+.055*s), (.022*s,.035*s,.025*s), 'dead_eye', 2)
        beam('angled heavy eyebrow', (x,y-.045*s,z+.105*s), (x+.006*s,y+.035*s,z+.09*s), .025*s, 'zombie_dark')
        sphere('sharp cheekbone', (x-.025*s,y*1.25,z-.035*s), (.05*s,.06*s,.045*s), 'dead_skin', 2)
    box('recessed crooked mouth', (x+.008*s,0,z-.105*s), (.025*s,.14*s,.065*s), 'black', .012)
    for y in (-.045*s,.012*s,.049*s):
        box('uneven worn tooth', (x+.025*s,y,z-.085*s), (.022*s,.023*s,.028*s), 'cream', .004)
    sphere('angular lower jaw', (x-.04*s,0,z-.155*s), (.075*s,.115*s,.055*s), 'dead_skin', 2)
    for offset in (-.03,.03):
        rod('stitched brow scar', (x-.04*s,-.16*s,z+.14*s+offset*s), (x,-.12*s,z+.12*s+offset*s), .008*s, 'wood_dark')


def finish_parts(before):
    for ob in set(bpy.data.objects)-before:
        if ob.type != 'MESH':
            continue
        for i, mat in enumerate(ob.data.materials):
            if mat.name == 'zombie':
                ob.data.materials[i] = M['dead_skin']
        if 'head' in ob.name or 'forearm' in ob.name:
            for poly in ob.data.polygons:
                poly.use_smooth = True


def walker_costume():
    # Open roadside jacket, with contrasting lapels and a loose tie.
    for y in (-.16,.16):
        box('weathered jacket panel', (.205,y,.66), (.07,.14,.36), 'dirty_teal', .02)
        beam('folded jacket lapel', (.24,y,.84), (.255,y*.4,.65), .065, 'teal_light', .025)
        box('jacket pocket flap', (.25,y,.58), (.025,.10,.045), 'teal_dark', .008)
        for z in (.55,.65):
            sphere('tarnished jacket button', (.262,y*.5,z), (.012,.016,.016), 'wood_light', 1)
    beam('loose crooked tie', (.28,0,.78), (.30,.055,.54), .045, 'faded_red', .025)
    box('patched knee', (.015,-.14,.32), (.06,.13,.12), 'work_canvas', .012)
    for y in (-.19,-.1):
        rod('patch stitching', (.05,y,.27), (.05,y,.37), .006, 'cream')
    for y in (-.12,-.04,.04,.12):
        beam('unkempt swept hair', (.03,y,1.22), (.16,y,1.255), .043, 'wood_dark', .04)
    face(.415,1.04)


def runner_costume():
    # Torn sports jersey, side stripes, wrist wrap and tied trainers.
    box('weathered jersey chest', (.265,0,.76), (.035,.23,.22), 'dirty_teal', .015, (0,.65,0))
    for y in (-.14,.14):
        beam('jersey side piping', (.08,y,.62), (.26,y,.83), .025, 'cream')
    box('faded race bib', (.3,-.005,.76), (.025,.14,.10), 'paper', .006, (0,.65,0))
    for y in (-.035,.015,.045):
        box('race bib ink marks', (.326,y,.76), (.01,.012,.055), 'iron', .002, (0,.65,0))
    for z in (.73,.755,.78):
        box('frayed wrist wrapping', (.62,.21,z), (.10,.115,.018), 'cream', .008)
    for x,y,z in ((.28,.11,.12),(-.26,-.11,.24)):
        for dx in (-.05,0,.05):
            rod('trainer laces',(x+dx,y-.045,z),(x+dx+.02,y+.045,z),.008,'wood_dark')
    face(.605,1.01,.83)


def brute_costume():
    # Industrial workwear with reinforced bib, utility belt and battered helmet.
    box('heavy canvas bib pocket', (.46,0,1.15), (.055,.31,.21), 'work_canvas', .025)
    box('bib pocket stitched edge', (.493,0,1.24), (.015,.3,.025), 'cream', .005)
    for y in (-.2,.2):
        box('metal strap buckle', (.45,y,1.36), (.04,.10,.09), 'steel', .015)
    box('wide work belt', (.40,0,.89), (.10,.60,.10), 'wood_dark', .02)
    box('heavy belt buckle', (.46,0,.89), (.035,.12,.09), 'steel', .01)
    box('side utility pouch', (.02,-.52,1.02), (.25,.15,.26), 'work_canvas', .025)
    sphere('battered safety helmet', (.38,0,2.0), (.29,.285,.14), 'yellow', 3)
    box('helmet brim', (.48,0,1.99), (.51,.60,.04), 'wood_light', .025)
    beam('helmet crown ridge', (.17,0,2.05), (.55,0,2.10), .04, 'cream')
    for y in (-.3,.3):
        box('reinforced knee patch', (.17,y,.48), (.055,.23,.22), 'work_canvas', .018)
        box('steel toe cap', (.25,y,.12), (.12,.28,.12), 'iron', .025)
    face(.71,1.81,1.12)

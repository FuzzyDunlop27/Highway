# Purpose: Fit CC0 clothes, hair and a stronger face to the saved trial body. Notes: docs/features/characters-3d.md
"""Run in MakeHuman Utilities > Scripting, then Execute. Preserves the base file."""


def dress_blacksmith():
    import importlib
    import json
    import tempfile
    from pathlib import Path
    import mh
    import material
    from core import G

    app = G.app
    human = app.selectedHuman
    source = Path('/Users/rick/Documents/MakeHuman/v1py3/exports/highway-blacksmith/blacksmith_hog2rxxs/blacksmith_base.mhm')
    output = Path(tempfile.mkdtemp(prefix='blacksmith_dressed_', dir=str(source.parent.parent)))
    human.save(str(output / 'session_backup.mhm'))
    human.load(str(source), True)
    # Resolve the installed modifier names rather than assuming abbreviated names.
    face = {'head/head-square': .40, 'head/head-rectangular': .20,
            'chin/chin-width': .24, 'chin/chin-prominent': .12,
            'nose/nose-width1': .12, 'head/head-age': .18}
    applied = {}
    for prefix, value in face.items():
        matches = [m for m in human.modifiers if m.fullName == prefix or m.fullName.startswith(prefix + '-')]
        if len(matches) != 1:
            raise RuntimeError('Ambiguous/missing face modifier: ' + prefix)
        matches[0].setValue(value)
        applied[matches[0].fullName] = value
    human.applyAllTargets()
    data = Path(mh.getSysDataPath())
    human.setMaterial(material.fromFile(str(data / 'skins/middleage_caucasian_male/middleage_caucasian_male.mhmat')))
    clothes = app.modules['3_libraries_clothes_chooser'].taskview
    for item in ['male_casualsuit01', 'shoes02']:
        clothes.selectProxy(str(data / 'clothes' / item / (item + '.mhclo')))
    app.modules['3_libraries_polygon_hair_chooser'].taskview.selectProxy(str(data / 'hair/short04/short04.mhclo'))
    human.setName('Harlan blacksmith - clothed source')
    human.save(str(output / 'blacksmith_dressed.mhm'))
    plugin = app.modules['9_export_fbx']
    config = plugin.FbxConfig()
    config.setHuman(human)
    config.binary = True
    config.scale = 1.0
    config.unit = 'decimeter'
    config.feetOnGround = True
    config.hiddenGeom = False
    config.useRelPaths = True
    importlib.import_module(plugin.__name__ + '.mh2fbx').exportFbx(str(output / 'blacksmith_dressed.fbx'), config)
    report = {'base_mhm': str(source), 'face_modifiers': applied,
              'actual': {'age_years': human.getAgeYears(), 'muscle': human.getMuscle(),
                         'weight': human.getWeight(), 'height': human.getHeight()},
              'measured_height_cm': human.getHeightCm(),
              'assets': ['middleage_caucasian_male', 'male_casualsuit01', 'shoes02', 'short04'],
              'licence': 'Bundled MakeHuman system assets: CC0', 'rigged': False}
    (output / 'dressed_source.json').write_text(json.dumps(report, indent=2) + '\n')
    app.redraw()
    app.statusPersist('Dressed source exported: ' + str(output))
    print('DRESSED_BLACKSMITH ' + str(output))


dress_blacksmith()

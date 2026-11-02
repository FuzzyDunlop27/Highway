# Purpose: Generate the spec's adult woman farmer with fitted CC0 workwear. Notes: docs/features/characters-3d.md
"""Run in MakeHuman Utilities > Scripting, then Execute. Saves current work first."""


def generate_farmer():
    import importlib
    import json
    import tempfile
    from pathlib import Path
    import mh
    import material
    from core import G

    app = G.app
    human = app.selectedHuman
    root = Path(mh.getPath('exports')) / 'highway-farmer'
    root.mkdir(parents=True, exist_ok=True)
    output = Path(tempfile.mkdtemp(prefix='farmer_source_', dir=str(root)))
    human.save(str(output / 'session_backup.mhm'))
    app._resetHuman()
    human.setSkeleton(None)
    requested = {'gender': 0.0, 'age_years': 40.0, 'muscle': .50, 'weight': .50, 'height': .50}
    human.setGender(requested['gender'])
    human.setAgeYears(requested['age_years'])
    human.setMuscle(requested['muscle'])
    human.setWeight(requested['weight'])
    human.setHeight(requested['height'])
    data = Path(mh.getSysDataPath())
    human.setMaterial(material.fromFile(str(data / 'skins/middleage_asian_female/middleage_asian_female.mhmat')))
    clothes = app.modules['3_libraries_clothes_chooser'].taskview
    for item in ['male_worksuit01', 'shoes02']:
        clothes.selectProxy(str(data / 'clothes' / item / (item + '.mhclo')))
    app.modules['3_libraries_polygon_hair_chooser'].taskview.selectProxy(str(data / 'hair/short02/short02.mhclo'))
    # Some bundled proxy materials refer to retired optional preview litspheres.
    # Use an installed preview sphere; diffuse maps for the actual export are unchanged.
    for obj in human.getObjects():
        sphere = obj.material.shaderParameters.get('litsphereTexture')
        if isinstance(sphere, str) and not Path(sphere).is_file():
            obj.material.setShaderParameter('litsphereTexture', str(data / 'litspheres/skinmat_caucasian.png'))
    human.setName('Farmer - adult woman survivor')
    human.save(str(output / 'farmer_source.mhm'))
    plugin = app.modules['9_export_fbx']
    config = plugin.FbxConfig()
    config.setHuman(human)
    config.binary = True
    config.scale = 1.0
    config.unit = 'decimeter'
    config.feetOnGround = True
    config.hiddenGeom = False
    config.useRelPaths = True
    importlib.import_module(plugin.__name__ + '.mh2fbx').exportFbx(str(output / 'farmer_source.fbx'), config)
    actual = {'gender': human.getGender(), 'age_years': human.getAgeYears(),
              'muscle': human.getMuscle(), 'weight': human.getWeight(), 'height': human.getHeight()}
    assert all(abs(actual[key] - value) < .0001 for key, value in requested.items())
    report = {'role': 'farmer survivor', 'requested': requested, 'actual': actual,
              'measured_height_cm': human.getHeightCm(), 'rigged': False,
              'assets': ['middleage_asian_female', 'male_worksuit01', 'shoes02', 'short02'],
              'licence': 'Bundled MakeHuman system assets CC0',
              'note': 'Workwear proxy fits the common hm08 base, including female body shapes.'}
    (output / 'farmer_source.json').write_text(json.dumps(report, indent=2) + '\n')
    app.redraw()
    app.statusPersist('Farmer source exported: ' + str(output))
    print('FARMER_SOURCE_READY ' + str(output))


generate_farmer()

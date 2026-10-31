"""Verify every catalog rendition preserves the source canvas and exact pixels."""
from pathlib import Path
from PIL import Image
import json

ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'manifest.json').read_text())
cat=ROOT/'HighwayHoldout8bit.xcassets'; checks=[]
for a in manifest['assets']:
    folder=cat/('AppIcon.appiconset' if a['name']=='app_icon' else a['name']+'.imageset')
    data=json.loads((folder/'Contents.json').read_text())
    master=Image.open(ROOT/'png'/a['filename']).convert('RGBA')
    for row in data['images']:
        scale=int(row.get('scale','1x')[0])
        size=(1024,1024) if a['name']=='app_icon' else (a['width']//4*scale,a['height']//4*scale)
        actual=Image.open(folder/row['filename']).convert('RGBA')
        expected=master.resize(size,Image.Resampling.NEAREST)
        ok=actual.size==size and actual.tobytes()==expected.tobytes()
        checks.append({'asset':a['name'],'file':row['filename'],'pass':ok,'size':size})
failed=[r for r in checks if not r['pass']]
(ROOT/'catalog_qa_report.json').write_text(json.dumps({'passed':len(checks)-len(failed),'failed':len(failed),'checks':checks},indent=2)+'\n')
print(f"Catalog: {len(checks)-len(failed)} exact renditions passed; {len(failed)} failed.")
if failed:raise SystemExit(1)

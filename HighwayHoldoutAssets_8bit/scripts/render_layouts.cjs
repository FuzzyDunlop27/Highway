// Render the editable v1 geometry at the v2 logical pixel resolution.
// This is an intermediate layout guide; build_pixel_assets.py makes final art.
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const root = path.resolve(__dirname,'..');
const manifest = JSON.parse(fs.readFileSync(path.join(root,'reference/base_manifest.json')));
const out = path.join(root,'reference/layout_rasters');
fs.mkdirSync(out,{recursive:true});
(async()=>{
  for(const a of manifest.assets){
    const factor = /^(app_icon|icon_|ui_)/.test(a.name) ? 8 : 4;
    let svg = fs.readFileSync(path.join(root,'reference/vector_layouts',a.name+'.svg'),'utf8');
    svg = svg.replace('<svg ', '<svg shape-rendering="crispEdges" ')
      .replace(/width="\d+" height="\d+"/,`width="${a.width/factor}" height="${a.height/factor}"`);
    await sharp(Buffer.from(svg))
      .ensureAlpha().png().toFile(path.join(out,a.filename));
  }
  console.log('Rendered 57 low-resolution layout guides.');
})().catch(e=>{console.error(e);process.exit(1)});

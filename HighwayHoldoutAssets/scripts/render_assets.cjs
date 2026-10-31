#!/usr/bin/env node
// Requires sharp. NODE_PATH may point to the Codex bundled node_modules.
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'manifest.json')));
const dest = path.join(root, 'png');
fs.mkdirSync(dest, {recursive:true});
const anchor = new Set(['tile_grass','tile_asphalt','bld_shelter','def_wall_wood','def_watchtower_base','unit_defender','zmb_walker']);
(async()=>{
  for(const a of manifest.assets) {
    if(process.argv.includes('--anchor') && !anchor.has(a.name)) continue;
    let pipeline = sharp(path.join(root,'source_svg',a.name+'.svg'), {density:288})
      .resize(a.width,a.height,{kernel:'lanczos3'}).toColourspace('srgb');
    if(a.opaque) pipeline=pipeline.removeAlpha();
    await pipeline.withIccProfile('srgb').png().toFile(path.join(dest,a.filename));
  }
  console.log('Rendered '+(process.argv.includes('--anchor') ? 'style anchor assets' : manifest.assets.length+' PNG assets'));
})().catch(e=>{console.error(e);process.exit(1)});

// Render scalable UI sources at their 2x master resolution.
const fs=require('fs'),path=require('path'),sharp=require('sharp');
const root=path.resolve(__dirname,'..');
const assets=JSON.parse(fs.readFileSync(path.join(root,'reference/vector_assets.json')));
(async()=>{
 for(const a of assets) await sharp(path.join(root,'source_svg',a.name+'.svg'),{density:144})
   .resize(a.width,a.height).toColourspace('srgb').withIccProfile('srgb').png()
   .toFile(path.join(root,'png',a.name+'.png'));
 console.log(`Rendered ${assets.length} UI components.`);
})().catch(e=>{console.error(e);process.exit(1)});

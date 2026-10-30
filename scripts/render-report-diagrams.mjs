import fs from 'node:fs';import path from 'node:path';import http from 'node:http';import {createRequire} from 'node:module';import {createHash} from 'node:crypto';
const root=process.cwd(),modules=process.env.THoxay_MERMAID_MODULES??path.join(root,'.tools/report-validation/node_modules');
let require=createRequire(import.meta.url),chromium;
try{({chromium}=require('playwright'));}catch{
 const runtimeRoot='C:/Users/thiet/AppData/Local/OpenAI/Codex/runtimes/cua_node';
 const runtime=fs.readdirSync(runtimeRoot).map(d=>path.join(runtimeRoot,d,'bin/node.exe')).find(p=>fs.existsSync(path.join(path.dirname(p),'node_modules/playwright')));
 if(!runtime)throw new Error('Playwright is required for local Mermaid rendering');
 ({chromium}=createRequire(runtime)('playwright'));
}
const text=fs.readFileSync('docs/BAO_CAO_DO_AN.md','utf8').replace(/\r\n/g,'\n');
const blocks=[...text.matchAll(/<!-- diagram:([\w-]+) -->\s*```mermaid\s*\n([\s\S]*?)```/g)];
if(blocks.length!==[...text.matchAll(/```mermaid/g)].length)throw new Error('Every Mermaid block needs a unique diagram marker');
const names=new Set();for(const b of blocks){if(names.has(b[1]))throw new Error('Duplicate diagram name');names.add(b[1]);}
const server=http.createServer((req,res)=>{
 const url=new URL(req.url,'http://localhost');
 if(url.pathname==='/'){res.setHeader('Content-Type','text/html; charset=utf-8');res.end('<!doctype html><html><body style="margin:24px;background:white"><div id="stage"></div></body></html>');return;}
 if(!url.pathname.startsWith('/vendor/')){res.writeHead(404).end();return;}
 const file=path.resolve(modules,'.'+url.pathname.slice('/vendor'.length));
 if(!file.startsWith(path.resolve(modules)+path.sep)){res.writeHead(403).end();return;}
 fs.readFile(file,(err,data)=>{if(err){res.writeHead(404).end();return;}res.setHeader('Content-Type',file.endsWith('.json')?'application/json':'text/javascript');res.end(data);});
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));const port=server.address().port;
let browser;const manifest=[];
try{
 browser=await chromium.launch({headless:true,...(process.platform==='win32'?{executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe'}:{})});
 const page=await browser.newPage({deviceScaleFactor:2});await page.goto(`http://127.0.0.1:${port}`);
 await page.evaluate(async()=>{window.mermaid=(await import('/vendor/mermaid/dist/mermaid.esm.min.mjs')).default;window.mermaid.initialize({startOnLoad:false,securityLevel:'strict',theme:'base',themeVariables:{fontFamily:'Arial',fontSize:'16px',primaryColor:'#ecfdf5',primaryTextColor:'#0f172a',primaryBorderColor:'#059669',lineColor:'#64748b',secondaryColor:'#fff1e8',tertiaryColor:'#f1f5f9'},flowchart:{htmlLabels:false,useMaxWidth:false},er:{useMaxWidth:false}});});
 for(const [index,b]of blocks.entries()){
  const dims=await page.evaluate(async({code,index})=>{const {svg}=await window.mermaid.render('figure'+index,code);document.querySelector('#stage').innerHTML=svg;const el=document.querySelector('#stage svg');const box=el.viewBox.baseVal;let width=Math.min(1800,box.width);if(box.height*width/box.width>10000)width=10000*box.width/box.height;el.style.maxWidth='none';el.style.width=width+'px';el.style.height='auto';return{width:Math.ceil(width),height:Math.ceil(box.height*width/box.width)};},{code:b[2],index});
  await page.setViewportSize({width:dims.width+48,height:Math.min(1200,dims.height+48)});
  const file='docs/diagrams/'+b[1]+'.png';await page.locator('#stage svg').screenshot({path:file});
  manifest.push({name:b[1],file,width:dims.width*2,height:dims.height*2,sourceSha256:createHash('sha256').update(b[2]).digest('hex'),pngSha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
  console.log('Rendered '+b[1]+' '+dims.width+'x'+dims.height+' @2x');
 }
 fs.writeFileSync('docs/diagrams/manifest.json',JSON.stringify(manifest,null,2)+'\n');
}finally{await browser?.close();await new Promise(r=>server.close(r));}

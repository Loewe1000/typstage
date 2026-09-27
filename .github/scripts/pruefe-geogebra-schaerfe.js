const {starte,schlaf}=require('./decklauf/cdp.js');
const fs=require('fs'),os=require('os'),path=require('path'),{execFileSync}=require('child_process'),assert=require('assert');
// Live regression: the external GeoGebra renderer cannot be replaced by a stub.
const packageRoot=path.resolve(__dirname,'../..');
const chrome=process.env.CHROME||(process.platform==='darwin'?'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome':'google-chrome');
(async()=>{
const root=fs.mkdtempSync(path.join(os.tmpdir(),'typstage-geogebra-'));
let b;
try {
const pkg=path.join(root,'pkg/preview/typstage');
fs.mkdirSync(pkg,{recursive:true});fs.symlinkSync(packageRoot,path.join(pkg,'0.2.0'));
fs.writeFileSync(path.join(root,'deck.typ'),`#import "@preview/typstage:0.2.0": *
#show: presentation.with(title: [Sharp GeoGebra])
== Circle
#geogebra(width: 360pt, height: 260pt)
#ggb-run("c=Circle((0,0),1)","A=Point(c)")
#ggb-view(x: (-1.8,1.8), y: (-1.3,1.3))
`);
execFileSync('typst',['compile','--features','html','--format','html','--package-path',path.join(root,'pkg'),'--root',root,path.join(root,'deck.typ'),path.join(root,'deck.html')],{stdio:'pipe'});
b=await starte(chrome);await b.ruf('Emulation.setDeviceMetricsOverride',{width:836,height:472,deviceScaleFactor:1,mobile:false});await b.navigiere('file://'+path.join(root,'deck.html'));await schlaf(800);await b.taste('ArrowRight');
for(let i=0;i<45;i++){if(await b.ev(`!!document.querySelector('iframe').contentWindow.ggbApplet?.getXML`))break;await schlaf(1000);}await schlaf(1500);
const inspect=`(()=>{let f=document.querySelector('iframe'),w=f.contentWindow;return {dpr:w.devicePixelRatio,xml:w.ggbApplet.getXML(),view:w.ggbApplet.getViewProperties(0),canvases:[...w.document.querySelectorAll('canvas')].filter(c=>c.getBoundingClientRect().width>100).map(c=>({w:c.width,h:c.height,cw:c.getBoundingClientRect().width,ch:c.getBoundingClientRect().height}))}})()`;
let base;
for(const [width,height,dpr] of [[836,472,1],[1905,1074,1],[1905,1074,2],[836,472,1]]){
 await b.ruf('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:dpr,mobile:false});await schlaf(1700);

 let a=await b.ev(inspect);console.log('viewport',width,height,'DPR',dpr,'canvas',JSON.stringify(a.canvases));
 if(!base)base=a;else {assert.equal(a.view,base.view,'logical view unchanged');assert.equal(a.xml,base.xml,'construction and labels unchanged');}
 const c=a.canvases[0];assert(c&&Math.abs(c.w-c.cw*dpr)<1.1&&Math.abs(c.h-c.ch*dpr)<1.1,'backing pixels cover displayed pixels');

}
await b.ruf('Runtime.evaluate',{expression:"window.__p=window.open(location.href.split('#')[0]+'#speaker')",userGesture:true});
for(let i=0;i<45;i++){if(await b.ev(`!!__p.document.querySelector('iframe')?.contentWindow.ggbApplet?.getXML`))break;await schlaf(1000);}await schlaf(1800);
const preview=await b.ev(inspect.replace("document.querySelector('iframe')","__p.document.querySelector('iframe')"));
// Different windows can round the logical canvas by one pixel; compare the
// mathematical bounds, not that rounding. Within one window XML stays exact.
for(const a of [preview,base]){const v=JSON.parse(a.view);assert(Math.abs(v.xMin+1.8)<1e-9);assert(Math.abs(v.yMin+1.3)<1e-9);assert(Math.abs(v.xMin+v.width*v.invXscale-1.8)<1e-9);assert(Math.abs(v.yMin+v.height*v.invYscale-1.3)<1e-9);}
const drag=await b.ev(`(()=>{let f=__p.document.querySelector('iframe'),w=f.contentWindow,a=w.ggbApplet,v=JSON.parse(a.getViewProperties(0)),c=w.document.querySelector('canvas').getBoundingClientRect(),r=f.getBoundingClientRect();let pos=(x,y)=>({x:r.left+c.left+(x-v.xMin)/v.invXscale*c.width/v.width,y:r.top+c.top+(v.height-(y-v.yMin)/v.invYscale)*c.height/v.height});return {from:pos(a.getXcoord('A'),a.getYcoord('A')),to:pos(0,1)}})()`);
const presenter=await b.zweites();try{
await presenter.taste('m');await schlaf(200);
await presenter.ruf('Input.dispatchMouseEvent',{type:'mousePressed',...drag.from,button:'left',clickCount:1});
for(let i=1;i<=12;i++)await presenter.ruf('Input.dispatchMouseEvent',{type:'mouseMoved',x:drag.from.x+(drag.to.x-drag.from.x)*i/12,y:drag.from.y+(drag.to.y-drag.from.y)*i/12,buttons:1});
await presenter.ruf('Input.dispatchMouseEvent',{type:'mouseReleased',...drag.to,button:'left',clickCount:1});await schlaf(1200);
const y=await b.ev(`document.querySelector('iframe').contentWindow.ggbApplet.getYcoord('A')`);assert(y>.8,'presenter drag reaches stage, y='+y);
}finally{await presenter.ende();await b.ev('__p.close()');}
console.log('PASS: stable construction and viewport, native canvas resolution at both DPRs, presenter drag synchronized.');
}finally{try{if(b)await b.ende();}finally{fs.rmSync(root,{recursive:true,force:true});}}})().catch(e=>{console.error(e);process.exitCode=1});

// Exercise the real deck/navigation/bridge, replacing only the external applet.
const {starte,schlaf}=require('./decklauf/cdp.js');
const {execFileSync}=require('child_process');
const fs=require('fs'),os=require('os'),path=require('path'),assert=require('assert');
const root=path.resolve(__dirname,'../..');
const receiver=`<script>window.received=[];addEventListener('message',e=>{let d=e.data;if(!d||!d.typstage||!d.jobs)return;if(d.reset)received=[];received.push(...d.jobs)});parent.postMessage({typstage:1,ready:1},'*');</script>`;
(async()=>{
 const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'typstage-ggb-steps-'));let b;
 try {
  const pkg=path.join(tmp,'pkg/preview/typstage');fs.mkdirSync(pkg,{recursive:true});fs.symlinkSync(root,path.join(pkg,'0.1.3'));
  const src=path.join(root,'examples/geogebra-sprecher.typ'),out=path.join(tmp,'deck.html');
  const args=['compile','--package-path',path.join(tmp,'pkg'),'--root',root,src];
  execFileSync('typst',[...args,out,'--features','html','--format','html','--input','typstage-overflow=error'],{stdio:'pipe'});
  execFileSync('typst',[...args,path.join(tmp,'deck.pdf')],{stdio:'pipe'});
  const escaped=receiver.replace(/&/g,'&amp;').replace(/"/g,'&quot;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
  let html=fs.readFileSync(out,'utf8'),count=0;
  html=html.replace(/srcdoc="[^"]*"/g,()=>{count++;return 'srcdoc="'+escaped+'"'});assert.equal(count,2,'two applet receivers');fs.writeFileSync(out,html);
  b=await starte(process.env.CHROME||(process.platform==='darwin'?'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome':'google-chrome'));
  await b.navigiere('file://'+out);await schlaf(500);
  for(const bridge of ['thales','family']){
   const first=await b.ev(`(()=>{let i=typstage.slides.findIndex(s=>s.querySelector('[data-bridge="${bridge}"]'));return typstage.steps.findIndex(x=>x.slide===i)})()`);
   assert(first>=0,'find '+bridge);await b.ev(`typstage.goto(${first},true)`);await schlaf(250);
   async function check(step){
    await schlaf(200);
    const state=await b.ev(`(()=>{let w=document.querySelector('[data-bridge="${bridge}"]'),s=w.closest('.ts-slide'),jobs=w.querySelector('iframe').contentWindow.received;return {bullets:[...s.querySelectorAll('.ts-el[data-on="1"]')].filter(e=>!e.classList.contains('ts-embed')).length,jobs}})()`);
    assert.equal(state.bullets,step-1,bridge+' captions step '+step);
    const cmd=state.jobs.flatMap(j=>j.cmd||[]);
    if(bridge==='thales'){
     assert.equal(cmd.includes('k=Semicircle(A,B)'),step>=2,'semicircle matches first caption');
     assert.equal(cmd.includes('C=Point(k)'),step>=3,'C matches second caption');
     assert.equal(cmd.includes('u=Segment(A,C)'),step>=3,'sides match second caption');
     assert.equal(cmd.includes('w=Angle(A,C,B)'),step>=4,'angle matches third caption');
     assert.equal(state.jobs.some(j=>j.style?.trace===true),step>=5,'trace matches fourth caption');
    }else{
     assert.equal(cmd.includes('f(x)=a*x^2+b'),step>=2,'parabola matches first caption');
     assert.equal(cmd.includes('N=Root(f)'),step>=5,'roots match fourth caption');
    }
   }
   await check(1);
   for(let k=2;k<=5;k++){await b.taste('ArrowRight');await check(k)}
   for(let k=4;k>=1;k--){await b.taste('ArrowLeft');await check(k)}
   await b.ev(`typstage.goto(${first+4},true)`);await check(5);
   console.log(bridge+': captions and bridge jobs agree forward, backward and on direct entry.');
  }
 }finally{if(b)await b.ende();fs.rmSync(tmp,{recursive:true,force:true})}
})().catch(e=>{console.error(e);process.exitCode=1});

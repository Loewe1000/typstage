// Real HTML audio over HTTP and local paths; deterministic timer boundaries.
const {starte,schlaf}=require('./decklauf/cdp.js');
const fs=require('fs'),os=require('os'),path=require('path'),http=require('http'),assert=require('assert');
const {execFileSync}=require('child_process');
const root=path.resolve(__dirname,'../..');
(async()=>{
 const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'typstage-audio-'));
 let b,server,html='';
 try {
  const sound=fs.readFileSync(path.join(root,'examples/medien/airhorn.mp3'));
  server=http.createServer((req,res)=>{
   if(req.url.endsWith('.mp3')){res.setHeader('Content-Type','audio/mpeg');res.end(sound);}
   else {res.setHeader('Content-Type','text/html');res.end(html);}
  });
  await new Promise(r=>server.listen(0,'127.0.0.1',r));
  const url='http://127.0.0.1:'+server.address().port;
  const pkg=path.join(tmp,'pkg/preview/typstage');fs.mkdirSync(pkg,{recursive:true});fs.symlinkSync(root,path.join(pkg,'0.2.0'));
  const deck=`#import "@preview/typstage:0.2.0": *
#show: presentation.with(title: [Audio], room: (clock: (step: 5, sound: "${url}/alarm.mp3")))
== Local
#audio("local.mp3", loop: true)
== URL
#audio("${url}/remote.mp3", at: "2-", autoplay: true)
== Silent
No audio here.
`;
  fs.writeFileSync(path.join(tmp,'deck.typ'),deck);
  const args=['compile','--package-path',path.join(tmp,'pkg'),'--root',tmp,path.join(tmp,'deck.typ')];
  execFileSync('typst',[...args,path.join(tmp,'deck.html'),'--features','html','--format','html'],{stdio:'pipe'});
  execFileSync('typst',[...args,path.join(tmp,'deck.pdf')],{stdio:'pipe'});
  html=fs.readFileSync(path.join(tmp,'deck.html'),'utf8');
  assert(html.includes('id="ts-clock-sound"'),'alarm is emitted');
  // Also compile disabled/default sound and the local-file variant.
  for(const value of ['none','"local.mp3"']){
   fs.writeFileSync(path.join(tmp,'variant.typ'),deck.replace('"'+url+'/alarm.mp3"',value));
   execFileSync('typst',['compile','--package-path',path.join(tmp,'pkg'),'--root',tmp,path.join(tmp,'variant.typ'),path.join(tmp,'variant.html'),'--features','html','--format','html'],{stdio:'pipe'});
   const v=fs.readFileSync(path.join(tmp,'variant.html'),'utf8');
   assert.equal(v.includes('id="ts-clock-sound"'),value!=='none');
  }
  b=await starte(process.env.CHROME||(process.platform==='darwin'?'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome':'google-chrome'));
  await b.navigiere(url+'/deck.html');await schlaf(700);
  async function until(js,label){for(let i=0;i<80;i++){if(await b.ev(js))return;await schlaf(100);}assert.fail(label);}
  await until(`Array.from(document.querySelectorAll('audio')).every(a=>a.readyState>=2)`,'all audio sources load');
  await b.taste('ArrowRight');await schlaf(400);
  assert(await b.ev(`document.querySelector('.ts-audio audio').paused`),'audio defaults to manual play');
  await b.taste('k');await schlaf(150);
  assert(await b.ev(`!document.querySelector('.ts-audio audio').paused`),'k plays local audio');
  await b.taste('k');
  assert(await b.ev(`document.querySelector('.ts-audio audio').paused`),'k pauses audio');
  await b.taste('ArrowRight');await schlaf(500);
  assert(await b.ev(`document.querySelectorAll('.ts-audio audio')[1].paused`),'hidden reveal is silent');
  await b.taste('ArrowRight');
  await until(`!document.querySelectorAll('.ts-audio audio')[1].paused`,'URL audio starts on reveal');
  await b.taste('ArrowLeft');await schlaf(400);
  assert(await b.ev(`document.querySelectorAll('.ts-audio audio')[1].paused`),'concealed audio pauses');
  await b.taste('End');await schlaf(300);
  await b.ev(`window.rings=0;document.querySelector('#ts-clock-sound').addEventListener('play',()=>rings++);typstage.pruef.uhr(0);typstage.clock.start(5)`);
  await schlaf(100);
  await b.ev('typstage.pruef.uhr(4999)');await schlaf(100);
  assert.equal(await b.ev('rings'),0,'no early alarm');
  await b.ev('typstage.pruef.uhr(5000)');await schlaf(150);
  assert.equal(await b.ev('rings'),1,'exact zero rings once');
  await b.ev('typstage.pruef.uhr(9000)');await schlaf(100);
  assert.equal(await b.ev('rings'),1,'overtime does not repeat');
  await b.ev('typstage.clock.stop();typstage.clock.start(5)');await schlaf(100);
  await b.ev('typstage.clock.stop();typstage.pruef.uhr(15000)');await schlaf(100);
  assert.equal(await b.ev('rings'),1,'cancelled timer stays silent');
  // The presenter owns commands, but its timer and audio never play a second copy.
  await b.ruf('Runtime.evaluate',{expression:"window.__p=window.open(location.href.split('#')[0]+'#speaker')",userGesture:true});
  await until(`!!__p?.typstage`,'presenter initializes');
  await b.ev(`__p.rings=0;__p.document.querySelector('#ts-clock-sound').addEventListener('play',()=>__p.rings++)`);await schlaf(150);
  const presenter=await b.zweites();
  try {await presenter.taste('1');await schlaf(400);}finally{await presenter.ende();}
  await b.ruf('Page.bringToFront',{});await schlaf(150);
  await b.ev('typstage.pruef.uhr(75001)');await schlaf(500);
  assert.equal(await b.ev('rings'),2,'a new timer rings again');
  assert.equal(await b.ev('__p.rings'),0,'presenter does not ring');
  await b.ev('typstage.clock.stop()');
  await b.taste('Home');await b.taste('ArrowRight');await schlaf(600);
  const controls=await b.zweites();
  try {await controls.taste('k');await schlaf(300);}finally{await controls.ende();}
  assert(await b.ev(`!document.querySelector('.ts-audio audio').paused`),'presenter plays stage audio');
  assert(await b.ev(`(()=>{let a=__p.document.querySelector('.ts-audio audio');return a.paused||a.muted})()`),'presenter audio stays silent');
  await b.ev('__p.close()');
  console.log('PASS: local/URL audio, manual/reveal playback, PDF, optional alarm, exact zero, cancellation, restart and stage-only sound.');
 } finally {
  if(b)await b.ende();if(server)await new Promise(r=>server.close(r));
  fs.rmSync(tmp,{recursive:true,force:true});
 }
})().catch(e=>{console.error(e);process.exitCode=1});

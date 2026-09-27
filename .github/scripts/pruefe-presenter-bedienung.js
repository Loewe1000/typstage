// Regression: first reveals, resizing, stable columns, shortcut defaults and media.
const {starte, schlaf} = require('./decklauf/cdp.js');
const {execFileSync} = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path'), assert = require('assert');
const root = path.resolve(__dirname, '../..');
(async () => {
 const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'typstage-bedienung-'));
 let b;
 try {
  const pkg = path.join(tmp,'pkg/preview/typstage');
  fs.mkdirSync(pkg,{recursive:true}); fs.symlinkSync(root,path.join(pkg,'0.2.0'));
  fs.copyFileSync(path.join(root,'examples/demo.mp4'),path.join(tmp,'demo.mp4'));
  fs.copyFileSync(path.join(root,'examples/medien/airhorn.mp3'),path.join(tmp,'sound.mp3'));
  fs.writeFileSync(path.join(tmp,'deck.typ'), `#import "@preview/typstage:0.2.0": *
#show: presentation.with(title: [Regression], speaker-view: (shortcuts: false), room: (sounds: (a: "sound.mp3")))
== Cue
#cue("g", [A], [B], [C])
#speaker-note[Notes for testing the split.]
== Anim
#anim[A]
== Stagger
#stagger([A], [B])
== Alternatives
#alternatives([A], [B])
== Tiles
#tiles([A], [B])
== Build
#build(k => [Stage #k], steps: 2)
== Scene
#scene("s", t => box(width: 220pt, height: 40pt)[Frame #t], stops: (0, 1))
#scene-layer("s", 1)[Layer]
== Morph alternatives
#alternatives(morph: true, [A], [B])
== Explicit
#stagger(start: 1, [A], [B])
== Media
#video("demo.mp4", width: 200pt, height: 120pt)
#speaker-note[Media controls.]
`);
  execFileSync('typst',['compile','--format','html','--features','html','--package-path',path.join(tmp,'pkg'),'--root',tmp,path.join(tmp,'deck.typ'),path.join(tmp,'deck.html')],{stdio:'pipe'});
  const stepSource=fs.readFileSync(path.join(tmp,'deck.typ'),'utf8').replace('title: [Regression]', 'title: [Regression], pages: "step"');
  fs.writeFileSync(path.join(tmp,'step.typ'),stepSource);
  execFileSync('typst',['compile','--package-path',path.join(tmp,'pkg'),'--root',tmp,path.join(tmp,'step.typ'),path.join(tmp,'step.pdf')],{stdio:'pipe'});
  b = await starte(process.env.CHROME || (process.platform === 'darwin'
    ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' : 'google-chrome'));
  const url = 'file://'+path.join(tmp,'deck.html');
  await b.navigiere(url); await schlaf(1500);
  assert(await b.ev('!!window.typstage'), 'runtime initializes');
  const starts=await b.ev(`Array.from(document.querySelectorAll('.ts-slide')).slice(1,10).map(s=>Array.from(s.querySelectorAll('.ts-el[data-at]')).map(e=>e.dataset.adPlatz||e.dataset.at))`);
  starts.slice(0,8).forEach((v,i)=>assert(v.length && parseInt(v[0])===2, 'auto starts at 2: '+i+' '+v));
  assert(parseInt(starts[6][1])===2,'scene layer follows first stop');
  assert(parseInt(starts[8][0])===1,'explicit start 1 preserved');
  await b.taste('ArrowRight'); await schlaf(400);
  for(let i=1;i<=3;i++) { await b.taste('ArrowRight'); await schlaf(400);
   assert.equal(await b.ev(`document.querySelectorAll('.ts-slide')[1].querySelectorAll('.ts-el[data-ad][data-on="1"]').length`), i, 'cue arrow reveal'); }
  await b.taste('ArrowLeft'); await schlaf(300);
  assert.equal(await b.ev(`document.querySelectorAll('.ts-slide')[1].querySelectorAll('.ts-el[data-ad][data-on="1"]').length`),2,'cue reverse hides');
  await b.taste('ArrowRight'); await schlaf(300);
  assert.equal(await b.ev(`document.querySelectorAll('.ts-slide')[1].querySelectorAll('.ts-el[data-ad][data-on="1"]').length`),3,'cue forward again');
  await b.taste('End'); await schlaf(600); await b.taste('3');
  const clock=`(()=>{let b=document.querySelector('#ts-stage').getBoundingClientRect(),c=document.querySelector('#ts-clock').getBoundingClientRect();return [(c.left-b.left)/b.width,(c.top-b.top)/b.height,parseFloat(getComputedStyle(document.querySelector('.ts-clock-num')).fontSize)/b.width]})()`;
  let c0=await b.ev(clock);
  await b.ruf('Emulation.setDeviceMetricsOverride',{width:900,height:600,deviceScaleFactor:1,mobile:false}); await schlaf(500);
  let c1=await b.ev(clock); c0.forEach((n,i)=>assert(Math.abs(n-c1[i])<.004,'clock stage-relative '+i));
  await b.ev(`document.querySelector('video').pause(); document.querySelector('video').currentTime=0`);
  await b.taste('l'); await schlaf(150);
  const duration=await b.ev(`document.querySelector('video').duration`);
  assert(Math.abs(await b.ev(`document.querySelector('video').currentTime`)-Math.min(10,duration))<.2,'l seeks');
  await b.taste('j'); assert(await b.ev(`document.querySelector('video').currentTime`)<.2,'j seeks back');
  await b.taste('k'); await schlaf(300); assert.equal(await b.ev(`document.querySelector('video').paused`),false,'k plays');
  await b.taste('k'); assert.equal(await b.ev(`document.querySelector('video').paused`),true,'k pauses');
  await b.ev(`window.__p=window.open(location.href.split('#')[0]+'#speaker')`); await schlaf(2200);
  assert(await b.ev(`__p.typstage.kanal.verbunden()`),'presenter connected');
  await b.ev(`__p.dispatchEvent(new __p.KeyboardEvent('keydown',{key:'k',bubbles:true}))`); await schlaf(700);
  assert.equal(await b.ev(`document.querySelector('video').paused`),false,'presenter k plays stage');
  await b.ev(`__p.dispatchEvent(new __p.KeyboardEvent('keydown',{key:'k',bubbles:true}))`); await schlaf(500);
  assert.equal(await b.ev(`document.querySelector('video').paused`),true,'presenter k pauses stage');
  assert(await b.ev(`__p.document.querySelector('.ts-sp-medien input') !== null`),'presenter has timeline');
  await b.ev(`let slider=__p.document.querySelector('.ts-sp-medien input');slider.value='1';slider.dispatchEvent(new __p.Event('input',{bubbles:true}))`);await schlaf(500);
  assert(Math.abs(await b.ev(`document.querySelector('video').currentTime`)-Math.min(1,duration))<.2,'presenter slider seeks stage');
  await b.ev(`__p.dispatchEvent(new __p.KeyboardEvent('keydown',{key:'3',bubbles:true}))`);await schlaf(500);
  assert(await b.ev(`(()=>{let c=__p.document.querySelector('#ts-clock'),r=c.getBoundingClientRect();return !!__p.document.elementFromPoint(r.left+r.width/2,r.top+r.height/2)?.closest('#ts-clock')})()`),'pinned presenter clock can be dragged');
  const remote0=await b.ev(clock);
  await b.ruf('Emulation.setDeviceMetricsOverride',{width:1200,height:700,deviceScaleFactor:1,mobile:false});await schlaf(500);
  const remote1=await b.ev(clock);remote0.forEach((n,i)=>assert(Math.abs(n-remote1[i])<.004,'remote clock scales '+i));
  await b.ev(`__p.dispatchEvent(new __p.KeyboardEvent('keydown',{key:'b',bubbles:true}))`);await schlaf(300);
  assert(await b.ev(`(()=>{let c=document.querySelector('#ts-clock');while(c){if(getComputedStyle(c).opacity==='0')return false;c=c.parentElement}return true})()`),'pinned clock stays visible on blackout');
  await b.ev(`__p.dispatchEvent(new __p.KeyboardEvent('keydown',{key:'b',bubbles:true}))`);
  await b.ev(`__p.dispatchEvent(new __p.KeyboardEvent('keydown',{key:'a',bubbles:true}))`);await schlaf(350);
  assert.equal(await b.ev(`document.querySelector('audio.ts-sound').paused`),false,'presenter starts sound');
  await b.ev(`__p.dispatchEvent(new __p.KeyboardEvent('keydown',{key:'k',bubbles:true}))`);await schlaf(450);
  assert.equal(await b.ev(`document.querySelector('audio.ts-sound').paused`),true,'presenter pauses audio');
  assert(await b.ev(`__p.document.querySelectorAll('.ts-sp-medien input').length>=2`),'audio timeline present');
  await b.ev(`__p.close()`);await schlaf(300);
  await b.navigiere('about:blank'); await b.navigiere(url+'#speaker'); await schlaf(1800);
  assert(await b.ev(`document.querySelector('.ts-sp-hilfe').hidden`),'default hides shortcuts');
  const footerGone = `(()=>{let f=document.querySelector('.ts-sp-fuss'),s=document.querySelector('#ts-speaker');return f.getBoundingClientRect().height===0 && getComputedStyle(s).rowGap==='0px'})()`;
  assert(await b.ev(footerGone),'hidden shortcuts leave no footer height or gap');
  const fullHeight=await b.ev(`document.querySelector('.ts-sp-leib').getBoundingClientRect().height`);
  await b.taste('h'); assert.equal(await b.ev(`document.querySelector('.ts-sp-hilfe').hidden`),false,'h shows shortcuts');
  assert(await b.ev(`document.querySelector('.ts-sp-leib').getBoundingClientRect().height`)<fullHeight,'showing shortcuts uses layout space');
  await b.taste('h');
  assert(await b.ev(footerGone),'hiding shortcuts removes footer again');
  const ratio=`(()=>{let n=document.querySelector('.ts-sp-notizkasten').getBoundingClientRect(),v=document.querySelector('.ts-sp-naechst').getBoundingClientRect();return n.width/(n.width+v.width)})()`;
  const r0=await b.ev(ratio);
  await b.ev(`typstage.sprecher.teil(.4)`); await schlaf(250);
  assert(Math.abs(await b.ev(ratio)-r0)<.002,'row resize keeps column ratio');
  await b.ev(`document.querySelector('.ts-sp-spaltenteiler').focus()`); await b.taste('ArrowRight'); await schlaf(250);
  const r1=await b.ev(ratio); assert(r1>r0+.015,'column separator keyboard');
  await b.ruf('Emulation.setDeviceMetricsOverride',{width:1400,height:900,deviceScaleFactor:1,mobile:false}); await schlaf(400);
  assert(Math.abs(await b.ev(ratio)-r1)<.003,'resize keeps column ratio');
  await b.ruf('Page.reload',{}); await schlaf(1300);
  assert(await b.ev(`document.querySelector('.ts-sp-hilfe').hidden`),'hidden preference persists');
  assert(Math.abs(await b.ev(ratio)-r1)<.003,'column preference persists');
  await b.ev(`document.activeElement.blur()`); await b.taste('End'); await schlaf(800);
  assert.equal(await b.ev(`document.querySelector('.ts-sp-medien').hidden`),false,'media controls visible on presenter media slide');
  assert(await b.ev(footerGone),'media controls do not create a footer below hidden shortcuts');
  assert(await b.ev(`!!document.querySelector('.ts-sp-werkzeugleiste .ts-sp-medien')`),'media controls belong to the toolbar');
  if(process.env.TYPSTAGE_TEST_SCREENSHOT) fs.writeFileSync(process.env.TYPSTAGE_TEST_SCREENSHOT,Buffer.from(await b.bild(),'base64'));
  console.log('Presenter regression: auto/explicit reveals, cue round-trip, clock scaling, media j/k/l, divider ratio and shortcuts passed.');
 } finally { if(b) await b.ende(); fs.rmSync(tmp,{recursive:true,force:true}); }
})().catch(e=>{console.error(e);process.exit(1)});

// Deterministic two-window regression; --live uses the real external YouTube API.
const {starte,schlaf}=require('./decklauf/cdp.js');
const {execFileSync}=require('child_process');
const fs=require('fs'),os=require('os'),path=require('path'),http=require('http'),assert=require('assert');
const root=path.resolve(__dirname,'../..'),live=process.argv.includes('--live');
const chrome=process.env.CHROME || (process.platform==='darwin'?'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome':'google-chrome');
// Replace only the external provider in offline tests; commands, DOM, navigation,
// messaging and presenter controls are the real compiled runtime in both windows.
const fixture=`<script>
window.players=[];window.apiLoads=0;
const append=HTMLHeadElement.prototype.appendChild;
HTMLHeadElement.prototype.appendChild=function(n){
 if(n.src==='https://www.youtube.com/iframe_api'){
  window.apiLoads++;
  if(location.search.includes('fail')){setTimeout(()=>n.onerror(),20);return n;}
  setTimeout(()=>{window.YT={Player:function(f,opts){
   let loadedURL=f.src;f.removeAttribute('src');
   let p=this;p.url=loadedURL;p.frame=f;p.time=0;p.state=2;p.muted=false;p.calls=[];p.events=opts.events;
   p.getPlayerState=()=>p.state;p.getDuration=()=>120;p.getCurrentTime=()=>p.time;
   p.mute=()=>p.muted=true;p.unMute=()=>p.muted=false;
   p.playVideo=()=>{p.calls.push('play');p.state=1;opts.events.onStateChange({data:1});};
   p.pauseVideo=()=>{p.calls.push('pause');p.state=2;opts.events.onStateChange({data:2});};
   p.seekTo=t=>{p.calls.push('seek');if(p.seekDelay)setTimeout(()=>p.time=t,p.seekDelay);else p.time=t;};
   players.push(p);setTimeout(()=>opts.events.onReady({target:p}),400);
  }};window.onYouTubeIframeAPIReady();},30);return n;
 }return append.call(this,n);
};
</script>`;
(async()=>{
 let b,server;const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'typstage-youtube-'));
 try{
  const pkg=path.join(tmp,'pkg/preview/typstage');fs.mkdirSync(pkg,{recursive:true});fs.symlinkSync(root,path.join(pkg,'0.1.3'));
  fs.writeFileSync(path.join(tmp,'deck.typ'),`#import "@preview/typstage:0.1.3": *
#show: presentation.with(title: [YouTube])
== Video
#embed(url: "https://www.youtube.com/embed/M7lc1UVf-VE", width: 480pt, height: 270pt)
== Privacy
#embed(url: "https://www.youtube-nocookie.com/embed/M7lc1UVf-VE?controls=1", width: 480pt, height: 270pt, at: "2")
== Other
#embed(url: "https://youtube.com.example.org/embed/M7lc1UVf-VE")
`);
  execFileSync('typst',['compile','--features','html','--format','html','--package-path',path.join(tmp,'pkg'),'--root',tmp,path.join(tmp,'deck.typ'),path.join(tmp,'deck.html')],{stdio:'pipe'});
  let html=fs.readFileSync(path.join(tmp,'deck.html'),'utf8');
  assert.equal((html.match(/data-ts-youtube=/g)||[]).length,2,'recognize only official embed hosts');
  assert(html.includes('src="https://youtube.com.example.org/'),'generic embeds unchanged');
  if(!live)html=html.replace('<head>','<head>'+fixture);
  server=http.createServer((req,res)=>{res.setHeader('Content-Type','text/html');res.end(html);});
  await new Promise(r=>server.listen(0,'127.0.0.1',r));const url='http://127.0.0.1:'+server.address().port+'/deck.html';
  b=await starte(chrome);
  async function until(expression,label){
   for(let i=0;i<60;i++){if(await b.ev(expression))return;await schlaf(100);}
   assert.fail(label);
  }
  await b.navigiere(url);await schlaf(1100);
  assert(await b.ev('!!window.typstage'),'runtime initializes');
  if(!live)assert.equal(await b.ev('apiLoads'),0,'no API for hidden slides');
  await b.taste('ArrowRight');
  if(!live){
   await schlaf(100);await b.taste('k');await b.taste('l');await schlaf(900);
   assert.equal(await b.ev('players[0].state'),1,'play before ready is retained');
   assert.equal(await b.ev('players[0].time'),10,'seek before metadata is retained');
   await b.taste('k');await b.taste('j');
  }else await schlaf(12000);
  const frame=`document.querySelector('iframe[data-ts-youtube]')`;
  if(live){
   const status=await b.ev(`(()=>{let y=${frame}.tsYouTube;return {ready:y.ready,error:y.error,src:${frame}.src}})()`);
   console.log('Live API:',status);assert(status.ready,'real YouTube player ready: '+status.error);
   await b.taste('k');await schlaf(4000);
   const playback=await b.ev(`(()=>{let f=${frame};return {time:f.currentTime,paused:f.paused,error:f.tsYouTube.error,notice:f.tsYouTube.notice}})()`);
   console.log('Live playback:',playback);assert(!playback.paused&&playback.time>0,'real video plays');
   await b.ev(`window.__p=window.open(location.href.split('#')[0]+'#speaker')`);await schlaf(10000);
   assert(await b.ev(`__p.document.querySelector('iframe[data-ts-youtube]').tsYouTube.ready`),'live preview ready');
   assert(await b.ev(`__p.document.querySelector('iframe[data-ts-youtube]').tsYouTube.player.isMuted()`),'live preview muted');
   await b.ev(`__p.dispatchEvent(new __p.KeyboardEvent('keydown',{key:'k',bubbles:true}))`);await schlaf(1500);
   assert(await b.ev(`${frame}.paused`),'live presenter pauses stage');
   await b.ev(`let s=__p.document.querySelector('.ts-sp-medien input');s.value='30';s.dispatchEvent(new __p.Event('input',{bubbles:true}))`);await schlaf(2000);
   assert(Math.abs(await b.ev(`${frame}.currentTime`)-30)<1,'live presenter scrubs stage');
   assert(Math.abs(await b.ev(`__p.document.querySelector('iframe[data-ts-youtube]').currentTime`)-30)<1,'live preview follows seek');
   await b.ev(`__p.dispatchEvent(new __p.KeyboardEvent('keydown',{key:'k',bubbles:true}))`);await schlaf(2000);
   assert.equal(await b.ev(`${frame}.paused`),false,'live presenter resumes stage');
   await b.ev('__p.close()');console.log('PASS: real YouTube playback and two-window muted preview, pause, seek and resume.');
  }else{
   assert.equal(await b.ev('apiLoads'),1,'one external API load');
   assert.equal(await b.ev('players.length'),1,'only visible video constructed');
   assert(await b.ev(`new URL(players[0].url).searchParams.get('controls')==='0'`),'stage controls hidden by default');
   for(const [width,height,dpr] of [[900,600,1],[1905,1074,2],[1600,900,1]]){
    await b.ruf('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:dpr,mobile:false});await schlaf(300);
    assert(await b.ev(`(()=>{let f=document.querySelector('iframe[data-ts-youtube]'),r=f.getBoundingClientRect();return !f.style.transform&&Math.abs(f.contentWindow.innerWidth-r.width)<1.1&&Math.abs(f.contentWindow.innerHeight-r.height)<1.1&&f.contentWindow.devicePixelRatio===${dpr}})()`),'YouTube viewport uses display pixels and native DPR');
   }
   await b.ev(`window.__p=window.open(location.href.split('#')[0]+'#speaker')`);await schlaf(2100);
   assert(await b.ev('__p.typstage.kanal.verbunden()'),'presenter connected');
   assert(await b.ev('__p.players[0].muted'),'preview muted');
   assert.equal(await b.ev('players[0].muted'),false,'stage audible');
   const key=async k=>{await b.ev(`__p.dispatchEvent(new __p.KeyboardEvent('keydown',{key:${JSON.stringify(k)},bubbles:true}))`);await schlaf(650);};
   await key('k');assert.equal(await b.ev('players[0].state'),1,'presenter starts stage');assert.equal(await b.ev('__p.players[0].state'),1,'preview follows play');
   await key('k');assert.equal(await b.ev('players[0].state'),2,'presenter pauses stage');
   await key('l');assert.equal(await b.ev('players[0].time'),10,'l forward ten seconds');assert.equal(await b.ev('__p.players[0].time'),10,'preview follows seek');
   await key('j');assert.equal(await b.ev('players[0].time'),0,'j backwards');
   await b.ev(`let s=__p.document.querySelector('.ts-sp-medien input');s.value='37';s.dispatchEvent(new __p.Event('input',{bubbles:true}))`);await schlaf(600);
   assert.equal(await b.ev('players[0].time'),37,'presenter timeline');
   // Real pointer drag, with delayed provider acknowledgements in both windows.
   const presenter=await b.zweites();
   try {
    await b.ev(`players[0].seekDelay=900;players[0].calls=[];__p.players[0].seekDelay=900;__p.players[0].calls=[]`);
    const rect=await presenter.ev(`(()=>{let r=document.querySelector('.ts-sp-medien input').getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height}})()`);
    const move=async x=>presenter.ruf('Input.dispatchMouseEvent',{type:'mouseMoved',x,y:rect.y+rect.h/2,buttons:1});
    await presenter.ruf('Input.dispatchMouseEvent',{type:'mousePressed',x:rect.x+rect.w*.3,y:rect.y+rect.h/2,button:'left',clickCount:1});
    for(let i=0;i<20;i++)await move(rect.x+rect.w*(.3+i*.025));
    const target=await presenter.ev(`+document.querySelector('.ts-sp-medien input').value`);
    assert(target>85&&target<105,'drag moves the thumb to the pointer, not just the initial click: '+target);
    await schlaf(1100);
    assert.equal(await b.ev(`players[0].calls.filter(c=>c==='seek').length`),0,'drag does not flood stage with seeks');
    assert.equal(await presenter.ev(`+document.querySelector('.ts-sp-medien input').value`),target,'feedback cannot pull the thumb back while dragging');
    await presenter.ruf('Input.dispatchMouseEvent',{type:'mouseReleased',x:rect.x+rect.w*.775,y:rect.y+rect.h/2,button:'left',clickCount:1});
    await until(`Math.abs(players[0].time-${target})<1`,'final drag target reached');
    await until(`Math.abs(__p.players[0].time-${target})<1`,'preview settles at final drag target');
    assert.equal(await b.ev(`players[0].calls.filter(c=>c==='seek').length`),1,'one seek on release');
    assert.equal(await b.ev(`__p.players[0].calls.filter(c=>c==='seek').length`),1,'delayed preview seek is not restarted');
    await b.ev(`players[0].seekDelay=0;__p.players[0].seekDelay=0;players[0].time=42`);
    await until(`Math.abs(+__p.document.querySelector('.ts-sp-medien input').value-42)<1`,'focused slider resumes following playback after drag');
    // Touch uses the same owned gesture; cancellation must not seek.
    await b.ev('players[0].calls=[]');
    await presenter.ruf('Emulation.setTouchEmulationEnabled',{enabled:true});
    const touch=async(type,fraction)=>presenter.ruf('Input.dispatchTouchEvent',{type,touchPoints:fraction==null?[]:[{x:rect.x+rect.w*fraction,y:rect.y+rect.h/2}]});
    await touch('touchStart',.2);await touch('touchMove',.6);
    assert(await presenter.ev(`+document.querySelector('.ts-sp-medien input').value>65`),'touch drag follows finger');
    await touch('touchCancel');await schlaf(250);
    assert.equal(await b.ev(`players[0].calls.filter(c=>c==='seek').length`),0,'cancelled touch does not seek');
    await touch('touchStart',.3);await touch('touchMove',.7);await touch('touchEnd');
    await until('players[0].time>78&&players[0].time<90','touch release commits dragged position');
    assert.equal(await b.ev(`players[0].calls.filter(c=>c==='seek').length`),1,'touch release sends one seek');
    await presenter.ruf('Emulation.setTouchEmulationEnabled',{enabled:false});
   } finally {await presenter.ende();}
   await b.ev(`__p.document.querySelector('.ts-sp-medien button').click()`);await schlaf(600);
   assert.equal(await b.ev('players[0].state'),1,'presenter play button');
   await key('b');assert.equal(await b.ev('players[0].state'),2,'black pauses');await key('b');assert.equal(await b.ev('players[0].state'),1,'unblack resumes');
   await b.ev('typstage.goto(2)');await schlaf(600);assert.equal(await b.ev('players[0].state'),2,'slide exit pauses');
   assert.equal(await b.ev('players.length'),1,'unrevealed player remains unloaded');
   await b.taste('ArrowRight');await schlaf(1000);assert.equal(await b.ev('players.length'),2,'reveal loads privacy player');assert(await b.ev(`new URL(players[1].url).searchParams.get('controls')==='1'`),'explicit stage controls remain available');assert.equal(await b.ev('apiLoads'),1,'reuse API');
   await key('k');assert.equal(await b.ev('players[1].state'),1,'second stable media ID');
   await b.ev('typstage.goto(2)');await schlaf(900);assert.equal(await b.ev('players[1].state'),2,'hiding reveal pauses');
   await b.ev('typstage.goto(1)');await schlaf(500);
   await b.ev(`players[0].events.onAutoplayBlocked();window.beforeCalls=players[0].calls.length`);await schlaf(1000);
   assert.equal(await b.ev('players[0].calls.length'),await b.ev('beforeCalls'),'no autoplay retry loop');
   assert(await b.ev(`__p.document.querySelector('.ts-sp-medien output').textContent.includes('Play')`),'blocked notice visible');
   await b.ev(`players[0].events.onError({data:153})`);await until(`__p.document.querySelector('.ts-sp-medien output').textContent.includes('153')`,'provider error shown');
   assert(await b.ev(`__p.document.querySelector('.ts-sp-medien button').disabled`),'unavailable player disabled');
   await b.ev('__p.close()');await b.navigiere(url+'?fail');await schlaf(700);await b.taste('ArrowRight');await schlaf(700);
   assert(await b.ev(`${frame}.tsYouTube.error.length>0`),'failed external API surfaced');
   console.log('PASS: lazy loading, official hosts, two-window controls, muted preview, seeking, slide/reveal/black lifecycle, API failure and provider errors.');
  }
 }finally{if(b)await b.ende();if(server){server.closeAllConnections();await new Promise(r=>server.close(r));};fs.rmSync(tmp,{recursive:true,force:true});}
})().catch(e=>{console.error(e);process.exitCode=1;});

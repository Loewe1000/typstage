const {starte,schlaf}=require('./decklauf/cdp.js');
const fs=require('fs'),os=require('os'),path=require('path'),http=require('http'),assert=require('assert');
const {execFileSync}=require('child_process');
const root=path.resolve(__dirname,'../..');
const fixture=`<script>
window.players=[];
const append=HTMLHeadElement.prototype.appendChild;
HTMLHeadElement.prototype.appendChild=function(n){
 if(n.src==='https://www.youtube.com/iframe_api'){
  setTimeout(()=>{window.YT={Player:function(f,o){
   let loadedURL=f.src;f.removeAttribute('src');let p=this;p.url=loadedURL;p.time=0;p.state=2;p.seeks=0;
   p.getDuration=()=>120;p.getCurrentTime=()=>p.time;p.getPlayerState=()=>p.state;
   p.mute=()=>{};p.unMute=()=>{};
   p.seekTo=t=>{p.time=t;p.seeks++};
   p.playVideo=()=>{p.state=1;o.events.onStateChange({data:1})};
   p.pauseVideo=()=>{p.state=2;o.events.onStateChange({data:2})};
   p.end=()=>{p.time=120;p.state=0;o.events.onStateChange({data:0})};
   players.push(p);setTimeout(()=>o.events.onReady({target:p}),30);
  }};window.onYouTubeIframeAPIReady()},10);return n;
 }return append.call(this,n);
};
</script>`;
(async()=>{
 const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'typstage-clips-'));
 let b,server,html='';
 try {
  // Three seconds of generated PCM: no provider or codec-dependent fixture.
  const wav=Buffer.alloc(44+48000*3*2);wav.write('RIFF');wav.writeUInt32LE(wav.length-8,4);wav.write('WAVEfmt ',8);wav.writeUInt32LE(16,16);wav.writeUInt16LE(1,20);wav.writeUInt16LE(1,22);wav.writeUInt32LE(48000,24);wav.writeUInt32LE(96000,28);wav.writeUInt16LE(2,32);wav.writeUInt16LE(16,34);wav.write('data',36);wav.writeUInt32LE(wav.length-44,40);
  const video=fs.readFileSync(path.join(root,'examples/demo.mp4'));
  server=http.createServer((req,res)=>{let data=req.url.endsWith('.wav')?wav:req.url.endsWith('.mp4')?video:null;if(data){res.setHeader('Content-Type',req.url.endsWith('.wav')?'audio/wav':'video/mp4');res.setHeader('Accept-Ranges','bytes');let m=/bytes=(\d+)-(\d*)/.exec(req.headers.range||'');if(m){let a=+m[1],z=m[2]?+m[2]:data.length-1;res.statusCode=206;res.setHeader('Content-Range','bytes '+a+'-'+z+'/'+data.length);data=data.subarray(a,z+1)}res.setHeader('Content-Length',data.length);res.end(data)}else{res.setHeader('Content-Type','text/html');res.end(html)}});
  await new Promise(r=>server.listen(0,'127.0.0.1',r));const url='http://127.0.0.1:'+server.address().port;
  const pkg=path.join(tmp,'pkg/preview/typstage');fs.mkdirSync(pkg,{recursive:true});fs.symlinkSync(root,path.join(pkg,'0.2.0'));
  const source=`#import "@preview/typstage:0.2.0": *
#show: presentation.with(title: [Clips])
== Video
#video("demo.mp4", start: 0.5, end: 1.2, autoplay: false)
== Audio
#audio("sound.wav", start: 0.3, end: 0.8, loop: true)
== YouTube
#embed(url: "https://www.youtube.com/embed/M7lc1UVf-VE?start=10&end=40&loop=0", start: 30, end: 75, loop: true)
== URL parameters
#embed(url: "https://www.youtube.com/embed/M7lc1UVf-VE?start=20&end=50")
== Duration clamp
#audio("sound.wav", start: 1, end: 20)
== Timed clip
#video("demo.mp4", start: 0.5, end: 1.5, ends-at: "08:15")
`;
  const compile=(s,name,extra=[])=>{fs.writeFileSync(path.join(tmp,name+'.typ'),s);return execFileSync('typst',['compile','--package-path',path.join(tmp,'pkg'),'--root',tmp,path.join(tmp,name+'.typ'),path.join(tmp,name+'.html'),'--features','html','--format','html',...extra],{stdio:'pipe'})};
  compile(source,'deck');html=fs.readFileSync(path.join(tmp,'deck.html'),'utf8').replace('<head>','<head>'+fixture);
  execFileSync('typst',['compile','--package-path',path.join(tmp,'pkg'),'--root',tmp,path.join(tmp,'deck.typ'),path.join(tmp,'deck.pdf')],{stdio:'pipe'});
  for(const params of ['start: -1','start: 2, end: 2','start: 3, end: 2','end: "75"','loop: 2']){
   assert.throws(()=>compile('#import "@preview/typstage:0.2.0": *\n#show: presentation\n== Invalid\n#audio("a.wav", '+params+')','bad'),undefined,'reject '+params);
  }
  b=await starte(process.env.CHROME||(process.platform==='darwin'?'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome':'google-chrome'));
  await b.navigiere(url);await schlaf(700);
  async function until(js,label){for(let i=0;i<100;i++){if(await b.ev(js))return;await schlaf(50)}console.log(await b.ev(`(()=>{let v=document.querySelector('video');return {t:v.currentTime,d:v.duration,ready:v.readyState,seeking:v.seeking,clip:v.tsClipReady,attrs:{...v.closest(".ts-el").dataset},seekable:v.seekable.length,error:v.error?.message}})()`));assert.fail(label)}
  await b.taste('ArrowRight');
  await until(`Math.abs(document.querySelector('video').currentTime-.5)<.02`,'video starts at clip offset');
  await b.taste('j');assert(Math.abs(await b.ev(`document.querySelector('video').currentTime`)-.5)<.02,'seek backward clamps');
  await b.taste('l');await schlaf(100);assert(Math.abs(await b.ev(`document.querySelector('video').currentTime`)-1.2)<.02,'seek forward clamps');
  await b.taste('k');await schlaf(100);
  assert(await b.ev(`document.querySelector('video').currentTime<1`),'play at end restarts clip');
  await until(`document.querySelector('video').paused&&Math.abs(document.querySelector('video').currentTime-1.2)<.03`,'video stops at selected end');
  await b.taste('ArrowRight');await schlaf(200);await b.taste('k');await schlaf(1400);
  assert(await b.ev(`(()=>{let a=document.querySelector('.ts-audio audio');return !a.paused&&a.currentTime>=.29&&a.currentTime<=.85})()`),'audio loops only its segment');
  await b.taste('ArrowRight');await until('players.length===1','YouTube constructed');
  await until('players[0].time===30','YouTube starts at 30');
  assert(await b.ev(`(()=>{let u=new URL(players[0].url);return u.searchParams.get('start')==='30'&&!u.searchParams.has('end')&&u.searchParams.get('loop')==='0'})()`),'explicit options override provider URL bounds');
  await b.taste('k');await b.ev('players[0].time=75');
  await until('players[0].time===30&&players[0].state===1','YouTube clip loops');
  await b.taste('k');await b.taste('j');assert.equal(await b.ev('players[0].time'),30,'YouTube lower seek bound');
  await b.ruf('Runtime.evaluate',{expression:"window.__p=window.open(location.href.split('#')[0]+'#speaker')",userGesture:true});
  await until(`__p?.typstage?.kanal.verbunden()`,'presenter connected');
  await until(`__p.document.querySelector('.ts-sp-medien input')?.min==='30'&&__p.document.querySelector('.ts-sp-medien input')?.max==='75'`,'presenter slider shows segment');
  await b.ev(`let s=__p.document.querySelector('.ts-sp-medien input');s.value=75;s.dispatchEvent(new __p.Event('input',{bubbles:true}));s.dispatchEvent(new __p.Event('change',{bubbles:true}))`);
  await until('players[0].time===75','presenter seeks to clip end');
  await b.ev('__p.close()');await b.ruf('Page.bringToFront',{});
  await b.taste('ArrowRight');await until('players.length===2&&players[1].time===20','legacy URL start supported');
  await b.taste('k');await b.ev('players[1].time=51');
  await until('players[1].state===2&&players[1].time===50','nonloop YouTube stops at end');
  await b.taste('ArrowRight');await b.taste('l');await schlaf(100);
  assert.equal(await b.ev(`document.querySelectorAll('.ts-audio audio')[1].currentTime`),3,'end clamps to source duration');
  await b.ev(`typstage.pruef.wanduhr(new Date(2026,0,1,8,14,58).getTime())`);
  await b.taste('ArrowRight');await schlaf(150);
  assert(await b.ev(`(()=>{let v=document.querySelectorAll('video')[1];return v.paused&&Math.abs(v.currentTime-.5)<.03})()`),'scheduled clip waits at its own start');
  await b.taste('ArrowLeft');
  await b.ev(`typstage.pruef.wanduhr(new Date(2026,0,1,8,14,59,500).getTime())`);
  await b.taste('ArrowRight');await schlaf(100);
  assert(await b.ev(`(()=>{let v=document.querySelectorAll('video')[1];return !v.paused&&v.currentTime>=1&&v.currentTime<1.5})()`),'ends-at schedules using clip end');
  console.log('PASS: native and YouTube clips, loop/stop/replay, seeking bounds, presenter timeline, URL compatibility, duration clamp, validation and PDF.');
 }finally{if(b)await b.ende();if(server)await new Promise(r=>server.close(r));fs.rmSync(tmp,{recursive:true,force:true})}
})().catch(e=>{console.error(e);process.exitCode=1});

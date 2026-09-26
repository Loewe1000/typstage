// Check painted glyph bounds, not just declared Typst block sizes.
const {starte,schlaf}=require('./decklauf/cdp.js');
const {execFileSync}=require('child_process');
const fs=require('fs'),os=require('os'),path=require('path'),assert=require('assert');
const root=path.resolve(__dirname,'../..');
(async()=>{
 const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'typstage-cards-'));let b;
 try{
  assert(execFileSync('typst',['fonts'],{encoding:'utf8'}).split('\n').includes('DejaVu Sans'),'Install DejaVu Sans to exercise the fallback-font regression');
  const pkg=path.join(tmp,'pkg/preview/typstage');fs.mkdirSync(pkg,{recursive:true});fs.symlinkSync(root,path.join(pkg,'0.1.3'));
  b=await starte(process.env.CHROME||(process.platform==='darwin'?'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome':'google-chrome'));
  for(const name of ['vortragen','0.1.3-ho-vortragen'])for(const font of ['default','DejaVu Sans']){
   let source=fs.readFileSync(path.join(root,'examples',name+'.typ'),'utf8');
   if(font!=='default')source=source.replace('#let t = themes.lesson','#let t = themes.lesson + (font: "DejaVu Sans",)');
   const file=path.join(tmp,'deck.typ'),html=path.join(tmp,'deck.html');fs.writeFileSync(file,source);
   execFileSync('typst',['compile','--package-path',path.join(tmp,'pkg'),'--root',tmp,'--features','html','--format','html','--input','typstage-overflow=error',file,html],{stdio:'pipe'});
   execFileSync('typst',['compile','--package-path',path.join(tmp,'pkg'),'--root',tmp,file,path.join(tmp,'deck.pdf')],{stdio:'pipe'});
   await b.navigiere('file://'+html);await schlaf(400);
   await b.ev(`window.cardsSlide=typstage.slides.findIndex(s=>s.dataset.titel==='The three that do not fit');typstage.goto(typstage.steps.findIndex(x=>x.slide===cardsSlide),true)`);
   const measure=`(()=>{let stage=document.querySelector('#ts-stage').getBoundingClientRect();return Array.from(typstage.slides[cardsSlide].querySelectorAll('.ts-el svg')).slice(-3).map(s=>{let b=s.getBBox(),v=s.viewBox.baseVal,r=s.getBoundingClientRect();return {x:b.x,y:b.y,right:b.x+b.width,bottom:b.y+b.height,w:v.width,h:v.height,left:r.left-stage.left,top:r.top-stage.top,screenRight:r.right-stage.left,screenBottom:r.bottom-stage.top,stageW:stage.width,stageH:stage.height}})})()`;
   for(const width of [900,1706]){
    await b.ruf('Emulation.setDeviceMetricsOverride',{width,height:Math.round(width*9/16),deviceScaleFactor:1,mobile:false});await schlaf(200);
    const before=await b.ev(measure);assert.equal(before.length,3,'three cards');
    for(const key of ['3','1','2']){
     await b.taste(key);await schlaf(250);
     const cards=await b.ev(measure);
     cards.forEach((c,i)=>{
      assert(c.x>=-.6&&c.y>=-.6&&c.right<=c.w+.6&&c.bottom<=c.h+.6,`${name}/${font}: text overflows card ${i+1}: ${JSON.stringify(c)}`);
      assert(c.left>=-1&&c.top>=-1&&c.screenRight<=c.stageW+1&&c.screenBottom<=c.stageH+1,'card stays on stage');
      assert(Math.abs(c.h-cards[0].h)<.01,'equal card heights');
      assert(Math.abs(c.top-before[i].top)<.1&&Math.abs(c.left-before[i].left)<.1,'reveals preserve positions');
     });
    }
   }
   console.log(name+' / '+font+': text inside all cards; stable reveals; HTML and PDF fit.');
  }
 }finally{if(b)await b.ende();fs.rmSync(tmp,{recursive:true,force:true})}
})().catch(e=>{console.error(e);process.exitCode=1});

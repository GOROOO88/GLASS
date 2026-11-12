const $=s=>document.querySelector(s);
const dialog=$("#appDialog"),content=$("#dialogContent");
const themes={Violet:["#a78bfa","167,139,250"],Ocean:["#78b9e8","120,185,232"],Emerald:["#77d7b0","119,215,176"],Rose:["#e6a0bd","230,160,189"]};
const defaults={theme:"Violet",opacity:7.5,blur:24,radius:24};
const read=(key,fallback)=>{try{return JSON.parse(localStorage.getItem(key))??fallback}catch{return fallback}};
const write=(key,value)=>localStorage.setItem(key,JSON.stringify(value));
let appearance={...defaults,...read("glass-appearance",{})};
const defaultSpaces=[{name:"Personal",icon:"◈",color:"#a78bfa"},{name:"Gaming",icon:"⌁",color:"#a47cff"},{name:"Work",icon:"▤",color:"#68a9d8"},{name:"Shopping",icon:"◇",color:"#e2a0b8"}];
let spaces=read("glass-spaces",defaultSpaces);
if(!Array.isArray(spaces)||!spaces.length)spaces=defaultSpaces.map(x=>({...x}));
spaces=spaces.map(x=>typeof x==="string"?{name:x,icon:"◈",color:"#a78bfa"}:x).filter(x=>x&&x.name);
if(!spaces.some(x=>x.name==="Personal"))spaces.unshift({...defaultSpaces[0]});
write("glass-spaces",spaces);
let activeSpace=localStorage.getItem("glass-space")||spaces[0].name;
if(!spaces.some(x=>x.name===activeSpace))activeSpace=spaces[0].name;
let activeSection="home";
const safe=s=>String(s).replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
function applyAppearance(patch={}){
 appearance={...appearance,...patch};write("glass-appearance",appearance);
 const [color,rgb]=themes[appearance.theme]||themes.Violet,root=document.documentElement;
 root.style.setProperty("--accent",color);root.style.setProperty("--accent-rgb",rgb);
 root.style.setProperty("--opacity",appearance.opacity/100);root.style.setProperty("--blur",appearance.blur+"px");root.style.setProperty("--radius",appearance.radius+"px");
}
applyAppearance();
function show(html){content.innerHTML=html;if(!dialog.open)dialog.showModal()}
function close(){if(dialog.open)dialog.close()}
$("#closeDialog").addEventListener("click",close);
dialog.addEventListener("click",e=>{if(e.target===dialog)close()});
function panelHead(kicker,title,copy=""){return '<p class="eyebrow">'+kicker+'</p><h2 class="dialog-title">'+title+'</h2>'+(copy?'<p class="dialog-copy">'+copy+'</p>':"")}
function action(label,id,extra=""){return '<button class="dialog-action" id="'+id+'" '+extra+'>'+label+'</button>'}
function persistSpaces(){write("glass-spaces",spaces)}
function syncSpaceButton(){const item=spaces.find(x=>x.name===activeSpace)||spaces[0];$("#spaceButton").innerHTML='<span class="space-dot" style="background:'+safe(item.color)+'"></span><span>'+safe(item.name)+'</span><span class="chevron">⌄</span>'}
function setSpace(name){if(!spaces.some(x=>x.name===name))return;activeSpace=name;localStorage.setItem("glass-space",name);syncSpaceButton();close()}
syncSpaceButton();
function spaceEditor(index=-1){
 const editing=index>=0,item=editing?spaces[index]:{name:"",icon:"◈",color:"#a78bfa"};
 show(panelHead(editing?"WORKSPACE SETTINGS":"NEW WORKSPACE",editing?"Edit space":"Create a space","Give this space its own name, icon and accent color.")+
 '<label class="setting">Name<input class="dialog-input" id="spaceName" maxlength="24" placeholder="e.g. Research" value="'+safe(item.name)+'"></label>'+
 '<label class="setting">Icon<input class="dialog-input" id="spaceIcon" maxlength="3" placeholder="◈" value="'+safe(item.icon)+'"></label>'+
 '<label class="setting">Accent color<input class="space-color" id="spaceColor" type="color" value="'+safe(item.color)+'"></label>'+
 action(editing?"Save changes":"Create space","saveSpace")+
 (editing&&item.name!=="Personal"?'<button class="dialog-action danger-action" id="deleteSpace">Delete space</button>':""));
 $("#saveSpace").addEventListener("click",()=>{
  const name=$("#spaceName").value.trim(),icon=$("#spaceIcon").value.trim()||"◈",color=$("#spaceColor").value;
  if(!name)return;
  if(spaces.some((x,i)=>i!==index&&x.name.toLowerCase()===name.toLowerCase())){const input=$("#spaceName");input.setCustomValidity("A space with this name already exists.");input.reportValidity();return}
  if(editing){const old=spaces[index].name;spaces[index]={name,icon,color};if(activeSpace===old){activeSpace=name;localStorage.setItem("glass-space",name)};const tabs=read("glass-tabs",[]);tabs.forEach(t=>{if(t.space===old)t.space=name});write("glass-tabs",tabs)}
  else spaces.push({name,icon,color});
  persistSpaces();syncSpaceButton();spacesPanel();
 });
 $("#deleteSpace")?.addEventListener("click",()=>{
  const removed=spaces[index].name,target=spaces.find(x=>x.name==="Personal")||spaces[0];
  if(!target||target.name===removed)return;
  const tabs=read("glass-tabs",[]);tabs.forEach(t=>{if(t.space===removed)t.space=target.name});write("glass-tabs",tabs);
  spaces.splice(index,1);if(activeSpace===removed){activeSpace=target.name;localStorage.setItem("glass-space",activeSpace)}
  persistSpaces();syncSpaceButton();spacesPanel();
 });
}
function spacesPanel(){
 show(panelHead("YOUR WORKSPACES","Spaces","Create separate spaces and give each its own identity.")+
 '<div class="panel-list">'+spaces.map((x,i)=>'<div class="workspace-row"><button class="panel-row workspace-select" data-space="'+safe(x.name)+'"><span class="row-icon" style="color:'+safe(x.color)+';background:'+safe(x.color)+'22;border-color:'+safe(x.color)+'55">'+safe(x.icon)+'</span><span class="row-main"><strong>'+safe(x.name)+'</strong><small>'+(x.name===activeSpace?"Currently active":"Switch workspace")+'</small></span><span class="row-trail">'+(x.name===activeSpace?"✓":"›")+'</span></button><button class="workspace-edit" data-edit-space="'+i+'" aria-label="Edit '+safe(x.name)+'">•••</button></div>').join("")+'</div>'+
 action("＋ Create space","createSpace"));
 $("#createSpace").addEventListener("click",()=>spaceEditor());
 content.querySelectorAll("[data-edit-space]").forEach(b=>b.addEventListener("click",()=>spaceEditor(Number(b.dataset.editSpace))));
}
}
function appearancePanel(){
 const p=appearance;
 show(panelHead("GLASS DESIGN SYSTEM","Appearance","One profile controls the visual language across every screen.")+
 '<div class="theme-grid">'+Object.entries(themes).map(([n,v])=>'<button class="theme-choice '+(p.theme===n?"selected":"")+'" data-theme="'+n+'"><i style="--swatch:'+v[0]+'"></i><span>'+n+'</span></button>').join("")+'</div>'+
 '<label class="setting">Glass opacity <output id="opacityValue">'+p.opacity+'%</output><input id="opacityControl" type="range" min="3" max="18" step=".5" value="'+p.opacity+'"></label>'+
 '<label class="setting">Background blur <output id="blurValue">'+p.blur+' px</output><input id="blurControl" type="range" min="8" max="40" value="'+p.blur+'"></label>'+
 '<label class="setting">Corner radius <output id="radiusValue">'+p.radius+' px</output><input id="radiusControl" type="range" min="12" max="34" value="'+p.radius+'"></label>'+
 '<div class="panel-preview"><span class="preview-dot"></span><div><strong>Live preview</strong><small>Buttons · Cards · Panels · Menus</small></div><button class="preview-chip">GLASS</button></div>'+action("Done","doneAppearance"));
 content.querySelectorAll("[data-theme]").forEach(b=>b.addEventListener("click",()=>{applyAppearance({theme:b.dataset.theme});appearancePanel()}));
 [["opacityControl","opacity","opacityValue","%"],["blurControl","blur","blurValue"," px"],["radiusControl","radius","radiusValue"," px"]].forEach(([id,key,out,suffix])=>$("#"+id).addEventListener("input",e=>{const val=Number(e.target.value);applyAppearance({[key]:val});$("#"+out).textContent=val+suffix}));
 $("#doneAppearance").addEventListener("click",close);
}
function menuPanel(){show(panelHead("GLASS","Control center","Everything in one place.")+
 '<div class="panel-list">'+[
 ["⌗","Tabs","Manage open tabs","tabs"],["◈","Spaces","Switch browsing spaces","spaces"],["◷","History","Recently visited pages","history"],["☆","Saved","Bookmarks and reading list","saved"],["▤","Library","Your browsing collection","library"],["⚙","Settings","Appearance and preferences","settings"]
 ].map(x=>'<button class="panel-row" data-panel="'+x[3]+'"><span class="row-icon">'+x[0]+'</span><span class="row-main"><strong>'+x[1]+'</strong><small>'+x[2]+'</small></span><span class="row-trail">›</span></button>').join("")+'</div>')}
function listPanel(type){
 if(type==="tabs"){tabsPanel();return}
 const data=read("glass-"+type,[]);
 const title=type==="history"?"History":type==="saved"?"Saved pages":type==="tabs"?"Tabs":"Library";
 const kicker=type==="history"?"YOUR ACTIVITY":type==="saved"?"BOOKMARKS":type==="tabs"?"BROWSING":"COLLECTION";
 const rows=data.length?data.map((x,i)=>'<div class="panel-row"><span class="row-icon">'+(type==="history"?"◷":"◇")+'</span><span class="row-main"><strong>'+safe(x.title||x.url)+'</strong><small>'+safe(x.url||"")+'</small></span><button class="row-remove" data-remove="'+i+'" aria-label="Remove">×</button></div>').join(""):'<div class="empty-panel"><span>◌</span><strong>Nothing here yet</strong><small>Your '+title.toLowerCase()+' will appear here.</small></div>';
 show(panelHead(kicker,title,"A consistent place for your browsing data.")+'<div class="panel-list">'+rows+'</div>'+(data.length?action("Clear all","clearList"):""));
 $("#clearList")?.addEventListener("click",()=>{write("glass-"+type,[]);listPanel(type)});
 content.querySelectorAll("[data-remove]").forEach(b=>b.addEventListener("click",()=>{data.splice(Number(b.dataset.remove),1);write("glass-"+type,data);listPanel(type)}));
}
function tabsPanel(filter=""){
 const tabs=read("glass-tabs",[]);
 const query=filter.trim().toLowerCase();
 const visible=tabs.filter(t=>(!query||((t.title||"")+" "+(t.url||"")+" "+(t.space||"")).toLowerCase().includes(query)));
 const spaceNames=spaces.map(x=>x.name);
 const cards=spaces.map(spaceItem=>{const space=spaceItem.name;
  const group=visible.filter(t=>t.space===space);
  if(!group.length)return "";
  return '<section class="tab-group"><div class="tab-group-head"><div><p class="eyebrow">SPACE</p><h3>'+safe(space)+'</h3></div><span class="tab-count">'+group.length+'</span></div><div class="tab-card-list">'+group.map(t=>'<article class="tab-card"><div class="tab-favicon">'+safe((new URL(t.url)).hostname.replace(/^www\./,"").slice(0,1).toUpperCase())+'</div><div class="tab-card-main"><strong>'+safe(t.title||t.url)+'</strong><small>'+safe(t.url)+'</small><select class="tab-move" data-move="'+safe(t.id)+'" aria-label="Move tab to space">'+spaceNames.map(n=>'<option '+(n===t.space?"selected":"")+'>'+n+'</option>').join("")+'</select></div><div class="tab-card-actions"><button class="tab-open" data-open="'+safe(t.id)+'" aria-label="Open tab">↗</button><button class="tab-close" data-close="'+safe(t.id)+'" aria-label="Close tab">×</button></div></article>').join("")+'</div></section>';
 }).join("");
 show(panelHead("YOUR BROWSING","Tabs",tabs.length+" saved tab entries · grouped by space")+
 '<input class="dialog-input tab-search" id="tabFilter" placeholder="Search tabs and websites…" value="'+safe(filter)+'">'+
 '<div class="tab-add-row"><input class="dialog-input" id="newTabUrl" placeholder="Paste a website address"><select class="tab-space-select" id="newTabSpace" aria-label="Choose space">'+spaces.map(n=>'<option '+(n===activeSpace?"selected":"")+'>'+n+'</option>').join("")+'</select><button class="dialog-action" id="addTab">＋ Add</button></div>'+
 (cards||'<div class="empty-panel"><span>⌗</span><strong>'+(tabs.length?"No matching tabs":"No saved tabs yet")+'</strong><small>Add a website or search from the home screen.</small></div>')+
 (tabs.length?action("Close all tabs","closeAllTabs"):""));
 $("#tabFilter").addEventListener("input",e=>{const pos=e.target.selectionStart;tabsPanel(e.target.value);const el=$("#tabFilter");el.focus();el.setSelectionRange(pos,pos)});
 $("#addTab").addEventListener("click",()=>{const raw=$("#newTabUrl").value.trim();if(!raw)return;const url=normalizeUrl(raw);if(!/^https?:\/\//i.test(url))return;tabs.unshift({id:"t"+Date.now(),title:new URL(url).hostname,url,space:$("#newTabSpace").value,created:Date.now()});write("glass-tabs",tabs);tabsPanel(filter)});
 content.querySelectorAll("[data-open]").forEach(b=>b.addEventListener("click",()=>{const t=tabs.find(x=>x.id===b.dataset.open);if(t)window.location.assign(t.url)}));
 content.querySelectorAll("[data-close]").forEach(b=>b.addEventListener("click",()=>{write("glass-tabs",tabs.filter(x=>x.id!==b.dataset.close));tabsPanel(filter)}));
 content.querySelectorAll("[data-move]").forEach(b=>b.addEventListener("change",()=>{const t=tabs.find(x=>x.id===b.dataset.move);if(t)t.space=b.value;write("glass-tabs",tabs);tabsPanel(filter)}));
 $("#closeAllTabs")?.addEventListener("click",()=>{write("glass-tabs",[]);tabsPanel()});
}
function settingsPanel(){show(panelHead("PREFERENCES","Settings","Tune the browser without leaving its visual system.")+
 '<div class="panel-list"><button class="panel-row" id="settingsAppearance"><span class="row-icon">◐</span><span class="row-main"><strong>Appearance</strong><small>Theme, blur, transparency and shape</small></span><span class="row-trail">›</span></button><div class="panel-row static-row"><span class="row-icon">☼</span><span class="row-main"><strong>Reduce motion</strong><small>Respect device accessibility setting</small></span><span class="row-trail">Auto</span></div><div class="panel-row static-row"><span class="row-icon">☁</span><span class="row-main"><strong>Sync</strong><small>Cloud sync will be connected later</small></span><span class="row-trail">Soon</span></div></div>')}
$("#menuButton").addEventListener("click",menuPanel);
$("#spaceButton").addEventListener("click",spacesPanel);
$("#manageSpaces").addEventListener("click",spacesPanel);
$("#libraryButton").addEventListener("click",()=>listPanel("library"));
$("#bookmarksButton").addEventListener("click",()=>listPanel("saved"));
$("#historyButton").addEventListener("click",()=>listPanel("history"));
$("#dialogContent").addEventListener("click",e=>{
 const b=e.target.closest("button");if(!b)return;
 if(b.dataset.space)setSpace(b.dataset.space);
 if(b.dataset.panel==="spaces")spacesPanel();
 if(b.dataset.panel==="settings")settingsPanel();
 if(b.dataset.panel==="tabs")listPanel("tabs");
 if(b.dataset.panel==="history")listPanel("history");
 if(b.dataset.panel==="saved")listPanel("saved");
 if(b.dataset.panel==="library")listPanel("library");
 if(b.id==="settingsAppearance")appearancePanel();
 if(b.id==="doneAppearance")close();
 if(b.id==="manageSpaceInfo")spacesPanel();
});
document.querySelectorAll(".space-card").forEach(card=>card.addEventListener("click",()=>{setSpace(card.dataset.space);listPanel("tabs")}));
function normalizeUrl(q){return /^https?:\/\//i.test(q)?q:/^[\w-]+\.[a-z]{2,}(\/.*)?$/i.test(q)?"https://"+q:"https://www.google.com/search?q="+encodeURIComponent(q)}
function search(q){q=q.trim();if(!q)return;const url=normalizeUrl(q);const data=read("glass-history",[]);data.unshift({title:q,url,at:Date.now()});write("glass-history",data.slice(0,100));const tabs=read("glass-tabs",[]);tabs.unshift({id:"t"+Date.now(),title:q,url,space:activeSpace,created:Date.now()});write("glass-tabs",tabs.slice(0,100));window.location.assign(url)}
$("#searchForm").addEventListener("submit",e=>{e.preventDefault();search($("#searchInput").value)});
$("#askButton").addEventListener("click",()=>{const input=$("#searchInput");input.placeholder="Ask anything…";input.focus();if(input.value.trim())search(input.value)});
function voice(){const SR=window.SpeechRecognition||window.webkitSpeechRecognition;if(!SR){show(panelHead("VOICE INPUT","Unavailable","Speech recognition is not supported by this browser. Use the search field instead."));return}const r=new SR();r.lang="ru-RU";r.onresult=e=>{const q=e.results[0][0].transcript;$("#searchInput").value=q;search(q)};r.start()}
$("#voiceButton").addEventListener("click",voice);$("#searchVoice").addEventListener("click",voice);
$("#backButton").addEventListener("click",()=>history.back());$("#forwardButton").addEventListener("click",()=>history.forward());
$("#clearRecent").addEventListener("click",()=>{$("#recentList").innerHTML='<span class="empty-symbol">◷</span><span>No recently closed tabs yet.</span>'});
$("#addShortcut").addEventListener("click",()=>show(panelHead("QUICK ACCESS","Add shortcut","Add a site to your home screen.")+'<input class="dialog-input" id="shortcutName" placeholder="Name"><input class="dialog-input" id="shortcutUrl" placeholder="https://example.com">'+action("Add shortcut","saveShortcut")));
$("#dialogContent").addEventListener("click",e=>{if(e.target.id==="saveShortcut"){const name=$("#shortcutName").value.trim(),url=$("#shortcutUrl").value.trim();if(!name||!url)return;const href=/^https?:\/\//i.test(url)?url:"https://"+url;const a=document.createElement("a");a.className="quick-link";a.href=href;a.innerHTML='<span class="quick-icon">↗</span><span></span>';a.lastElementChild.textContent=name;$("#quickLinks").insertBefore(a,$("#addShortcut"));close()}});
if("serviceWorker"in navigator)window.addEventListener("load",()=>navigator.serviceWorker.register("/sw.js").catch(()=>{}));

const CACHE="glass-shell-v3";
const ASSETS=["./","./index.html","./styles.css?v=cdecd5f","./app.js?v=cdecd5f","./manifest.webmanifest"];
self.addEventListener("install",event=>event.waitUntil((async()=>{const cache=await caches.open(CACHE);await cache.addAll(ASSETS);await self.skipWaiting()})()));
self.addEventListener("activate",event=>event.waitUntil((async()=>{const keys=await caches.keys();await Promise.all(keys.filter(key=>key!==CACHE).map(key=>caches.delete(key)));await self.clients.claim()})()));
self.addEventListener("fetch",event=>{
 if(event.request.method!=="GET")return;
 const url=new URL(event.request.url);
 const shell=url.pathname.endsWith("/")||/\.(html|css|js|webmanifest)$/.test(url.pathname);
 if(!shell)return;
 event.respondWith((async()=>{
  const cache=await caches.open(CACHE);
  try{
   const response=await fetch(event.request,{cache:"no-store"});
   if(response.ok)await cache.put(event.request,response.clone());
   return response;
  }catch(error){
   return await cache.match(event.request)||await cache.match("./index.html");
  }
 })());
});
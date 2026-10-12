/* PolyTrack 0.6.0 UI mods. Physics cheats require separate WASM-engine hooks. */
(() => {
  if (window.__polyTrackModsLoaded) return;
  window.__polyTrackModsLoaded = true;
  const style = document.createElement('style');
  style.textContent = `
    #pt-mods-button { position:fixed; z-index:2147483647; left:max(12px, env(safe-area-inset-left)); bottom:max(12px, env(safe-area-inset-bottom)); border:1px solid #5689a1; border-radius:10px; padding:9px 12px; color:#eefaff; background:rgba(10,18,28,.94); font:700 13px -apple-system,BlinkMacSystemFont,sans-serif; box-shadow:0 3px 16px #0008; }
    #pt-mods-panel { position:fixed; z-index:2147483647; left:max(12px, env(safe-area-inset-left)); bottom:max(58px, calc(env(safe-area-inset-bottom) + 58px)); width:min(290px,calc(100vw - 24px)); max-height:62vh; overflow:auto; box-sizing:border-box; padding:12px; border-radius:14px; border:1px solid #3c6278; color:#f2f8ff; background:rgba(8,13,22,.97); box-shadow:0 8px 28px #000b; font:14px -apple-system,BlinkMacSystemFont,sans-serif; }
    #pt-mods-panel[hidden] { display:none !important; } #pt-mods-panel h3 { margin:0 0 5px; font-size:16px; } #pt-mods-panel p { margin:6px 0 10px; color:#b9c9d7; font-size:12px; line-height:1.35; }
    .pt-mod-row { display:flex; align-items:center; justify-content:space-between; gap:8px; padding:9px 0; border-top:1px solid #ffffff22; } .pt-mod-row span { flex:1; } .pt-mod-row button { min-width:54px; color:white; background:#24475d; border:1px solid #5ca5c9; border-radius:8px; padding:7px 10px; } .pt-mod-row button:disabled { opacity:.4; }
  `;
  document.documentElement.appendChild(style);
  const open = document.createElement('button'); open.id='pt-mods-button'; open.type='button'; open.textContent='MODS'; open.setAttribute('aria-label','Open PolyTrack UI mods');
  const panel = document.createElement('section'); panel.id='pt-mods-panel'; panel.hidden=true;
  panel.innerHTML='<h3>PolyTrack Mods · 0.6.0</h3><p>Interface options for this version. The physics engine changed in 0.6.0, so classic physics cheats are not exposed until they can be hooked safely.</p>';
  open.addEventListener('click',()=>{panel.hidden=!panel.hidden;});
  document.addEventListener('keydown',e=>{if(e.key==='Escape')panel.hidden=true;});
  document.body.append(open,panel);
  function toggle(label,on,off) {
    const row=document.createElement('div'), name=document.createElement('span'), button=document.createElement('button');
    row.className='pt-mod-row'; name.textContent=label; button.type='button'; button.textContent='OFF'; let active=false;
    button.addEventListener('click',()=>{active=!active; try { (active?on:off)(); button.textContent=active?'ON':'OFF'; } catch(err) { active=false; button.textContent='ERR'; console.warn('[PolyTrack mods]',err); }});
    row.append(name,button); panel.append(row);
  }
  toggle('Hide game HUD',()=>{const e=document.getElementById('ui');if(e)e.style.visibility='hidden';},()=>{const e=document.getElementById('ui');if(e)e.style.visibility='';});
  toggle('High-contrast HUD',()=>{const e=document.getElementById('ui');if(e)e.style.filter='contrast(1.4) brightness(1.15)';},()=>{const e=document.getElementById('ui');if(e)e.style.filter='';});
  toggle('Larger touch controls',()=>{document.documentElement.style.setProperty('--pt-touch-scale','1.2');let s=document.getElementById('pt-touch-style');if(!s){s=document.createElement('style');s.id='pt-touch-style';document.head.appendChild(s);}s.textContent='#ui button,#ui [role=button]{transform:scale(1.15);transform-origin:center;}';},()=>{document.documentElement.style.removeProperty('--pt-touch-scale');const s=document.getElementById('pt-touch-style');if(s)s.remove();});
  toggle('Hide MODS button',()=>{open.style.display='none';panel.hidden=true;},()=>{open.style.display='';});
  window.PolyTrackMods=Object.freeze({version:'0.6.0-ui',addStyle(css){const s=document.createElement('style');s.textContent=String(css);document.documentElement.appendChild(s);return s;}});
  console.info('[PolyTrack mods] 0.6.0 UI mods loaded');
})();

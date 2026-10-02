let m=false;const s=new Set();const $=x=>document.querySelector(x)
function ref(){st.textContent=AxNative.backendName()+' · '+(AxNative.isReady()?'已连接':'未连接');const A=JSON.parse(AxNative.listApps());list.innerHTML=A.map(a=>`<div class="card ${s.has(a.pkg)?'sel':''}" onclick="tap('${a.pkg}')"><div><b>${a.name}</b><br><small>${a.pkg} · ${a.enabled?'启用':'禁用'}${a.lvl==2?' · 受保护':a.lvl==1?' · 关键':''}</small></div><div class=acts><button onclick="event.stopPropagation();ac('freeze','${a.pkg}',${a.lvl})">冻</button><button onclick="event.stopPropagation();ac('enable','${a.pkg}',${a.lvl})">启</button></div></div>`).join('')}
function tap(p){if(m){s.has(p)?s.delete(p):s.add(p);ref();return}location.href='detail.html?pkg='+encodeURIComponent(p)}
function ac(f,p,l){if(l==2){alert('受保护：'+AxNative.detail(p).reason);return}if(l==1&&!confirm('关键组件，确认'+f+'？'))return;alert(AxNative[f](p));ref()}
function toggle(){m=!m;s.clear();mb();ref()}
function mb(){let b=document.getElementById('mb');if(!m&&b){b.remove();return}if(!b){b=document.createElement('div');b.id='mb';b.className='mb';document.body.appendChild(b)}b.innerHTML=`<span style=flex:1>已选 ${s.size}</span><button onclick="bt('freeze')">冻</button><button onclick="bt('enable')">启</button><button onclick="bt('clear')">清</button><button class=danger onclick="bt('uninstall')">卸</button><button onclick="toggle()">退出</button>`}
function bt(o){if(!s.size)return;if(!confirm('批量'+o+' '+s.size+'项？受保护项自动跳过'))return;alert(AxNative.batch(o,JSON.stringify([...s])));s.clear();ref()}
window.onload=()=>setTimeout(ref,400)

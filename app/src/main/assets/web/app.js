var multi = false;
var sel = {};
var $ = function (s) { return document.querySelector(s); };

function refresh() {
  var st = $('#st');
  st.textContent = AxNative.backendName() + ' · ' + (AxNative.isReady() ? '已连接' : '未连接');
  var arr = JSON.parse(AxNative.listApps());
  var html = '';
  for (var i = 0; i < arr.length; i++) {
    var a = arr[i];
    var tag = '';
    if (a.lvl == 2) tag = '<span class="tag hard">受保护</span>';
    else if (a.lvl == 1) tag = '<span class="tag soft">关键</span>';
    html += '<div class="card ' + (sel[a.pkg] ? 'sel' : '') + '" onclick="tap('' + esc(a.pkg) + '')">'
      + '<div class="meta"><b>' + esc(a.name) + '</b><br><small>' + esc(a.pkg) + ' · ' + (a.enabled ? '启用' : '禁用') + tag + '</small></div>'
      + '<div class="acts">'
      + '<button onclick="event.stopPropagation();ac('freeze','' + esc(a.pkg) + '',' + a.lvl + ')">冻</button>'
      + '<button onclick="event.stopPropagation();ac('enable','' + esc(a.pkg) + '',' + a.lvl + ')">启</button>'
      + '</div></div>';
  }
  $('#list').innerHTML = html;
}

function esc(s) { return String(s).replace(/'/g, "\'"); }

function tap(pkg) {
  if (multi) {
    if (sel[pkg]) { delete sel[pkg]; } else { sel[pkg] = 1; }
    refresh(); return;
  }
  location.href = 'detail.html?pkg=' + encodeURIComponent(pkg);
}

function ac(fn, pkg, lvl) {
  if (lvl == 2) { alert('受保护应用，禁止操作'); return; }
  if (lvl == 1 && !confirm('关键系统组件，确认 ' + fn + '？')) return;
  alert(AxNative[fn](pkg));
  refresh();
}

function toggleMulti() {
  multi = !multi;
  if (!multi) sel = {};
  renderBar();
  refresh();
}

function renderBar() {
  var b = document.getElementById('mb');
  if (!multi && b) { b.remove(); return; }
  if (!b) {
    b = document.createElement('div');
    b.id = 'mb'; b.className = 'mb';
    document.body.appendChild(b);
  }
  var keys = [];
  for (var k in sel) keys.push(k);
  b.innerHTML = '<span style="flex:1;align-self:center">已选 ' + keys.length + '</span>'
    + '<button onclick="bt('freeze')">冻结</button>'
    + '<button onclick="bt('enable')">启用</button>'
    + '<button onclick="bt('clear')">清数据</button>'
    + '<button class="danger" onclick="bt('uninstall')">卸载</button>'
    + '<button onclick="toggleMulti()">退出</button>';
}

function bt(op) {
  var keys = [];
  for (var k in sel) keys.push(k);
  if (!keys.length) return;
  if (!confirm('批量 ' + op + ' ' + keys.length + ' 项？受保护项自动跳过')) return;
  alert(AxNative.batch(op, JSON.stringify(keys)));
  sel = {};
  refresh();
}

window.onload = function () { setTimeout(refresh, 400); };

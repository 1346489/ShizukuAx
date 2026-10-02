#!/bin/bash
# gen.sh —— 在 CI 中自动生成 AxShizuku 全部源码
set -e
D=app/src/main
J=$D/java/me/x/shizukuax
mkdir -p $J $D/res/layout $D/res/values $D/res/drawable $D/assets/web gradle/wrapper

cat > settings.gradle.kts <<'K'
pluginManagement{repositories{google();mavenCentral();gradlePluginPortal()}}
dependencyResolutionManagement{repositories{google();mavenCentral()}}
rootProject.name="ShizukuAx"
include(":app")
K

cat > build.gradle.kts <<'K'
plugins{id("com.android.application")version"8.2.2"apply false;id("org.jetbrains.kotlin.android")version"1.9.22"apply false}
K

cat > gradle.properties <<'K'
org.gradle.jvmargs=-Xmx1536m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
K

cat > app/build.gradle.kts <<'K'
import java.util.Properties
plugins{id("com.android.application");id("org.jetbrains.kotlin.android")}
android{
 namespace="me.x.shizukuax";compileSdk=34
 defaultConfig{applicationId="me.x.shizukuax";minSdk=26;targetSdk=34;versionCode=1;versionName="1.0.0"}
 buildFeatures{viewBinding=true}
 compileOptions{sourceCompatibility=JavaVersion.VERSION_17;targetCompatibility=JavaVersion.VERSION_17}
 kotlinOptions{jvmTarget="17"}
 signingConfigs{create("dbg"){storeFile=file("debug.keystore");storePassword="a";keyPassword="a";keyAlias="a"}}
 buildTypes{debug{signingConfig=signingConfigs.getByName("dbg")}}
}
dependencies{
 implementation("dev.rikka.shizuku:api:13.1.5")
 implementation("androidx.webkit:webkit:1.10.0")
 implementation("androidx.core:core-ktx:1.12.0")
 implementation("androidx.appcompat:appcompat:1.6.1")
 implementation("com.google.android.material:material:1.11.0")
 implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
K

# ---------- AndroidManifest.xml ----------
cat > $D/AndroidManifest.xml <<'K'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"/>
<uses-permission android:name="android.permission.CLEAR_APP_USER_DATA"/>
<application android:theme="@style/AxTheme" android:label="Ax·Shizuku" android:icon="@drawable/ic_launcher">
<activity android:name=".MainActivity" android:exported="true">
<intent-filter><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent-filter>
</activity></application></manifest>
K

cat > $D/res/values/themes.xml <<'K'
<resources><style name="AxTheme" parent="Theme.Material3.DayNight.NoActionBar"><item name="android:windowBackground">#0b0d12</item><item name="android:statusBarColor">#0b0d12</item></style></resources>
K
cat > $D/res/drawable/ic_launcher.xml <<'K'
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="#7C5CFF" android:pathData="M24,24h60v60h-60z"/></vector>
K
cat > $D/res/layout/activity_main.xml <<'K'
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/scrim" android:layout_width="match_parent" android:layout_height="match_parent">
<WebView android:id="@+id/web" android:layout_width="match_parent" android:layout_height="match_parent"/>
<FrameLayout android:id="@+id/detailPanel" android:layout_width="320dp" android:layout_height="match_parent" android:layout_gravity="end" android:background="#11141D" android:visibility="gone" android:translationX="320dp"><WebView android:id="@+id/detailWeb" android:layout_width="match_parent" android:layout_height="match_parent"/></FrameLayout>
</FrameLayout>
K

# ---------- Kotlin 源码 ----------
cat > $J/MainActivity.kt <<'K'
package me.x.shizukuax
import android.os.Bundle
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity
import dev.rikka.shizuku.Shizuku
import me.x.shizukuax.databinding.ActivityMainBinding
class MainActivity : AppCompatActivity() {
    private lateinit var b: ActivityMainBinding
    private lateinit var drawer: DetailDrawer
    override fun onCreate(s: Bundle?) {
        super.onCreate(s)
        b = ActivityMainBinding.inflate(layoutInflater)
        setContentView(b.root)
        if (!Shizuku.isPreV11()) Shizuku.requestPermission(0)
        Shizuku.addRequestPermissionResultListener { _, r -> if (r == Shizuku.PERMISSION_GRANTED) ShizukuGate.ensure() }
        setupWebView(b.web)
        val dw = findViewById<WebView>(R.id.detailWeb)
        setupWebView(dw)
        drawer = DetailDrawer(b.scrim, b.detailPanel)
        b.scrim.setOnClickListener { drawer.hide() }
    }
    private fun setupWebView(w: WebView) {
        w.settings.javaScriptEnabled = true
        w.settings.allowFileAccess = true
        w.settings.domStorageEnabled = true
        w.addJavascriptInterface(AppBridge(this), "AxNative")
    }
    override fun onBackPressed() { if (drawer.isOpen()) drawer.hide() else super.onBackPressed() }
}
K

cat > $J/ShizukuGate.kt <<'K'
package me.x.shizukuax
import android.os.IBinder
import android.os.ServiceManager
import dev.rikka.shizuku.Shizuku
import rikka.shizuku.ShizukuBinderWrapper
object ShizukuGate {
    var ready: Boolean = false
    fun ensure(): Boolean { ready = runCatching { Shizuku.pingBinder() }.getOrDefault(false); return ready }
    fun packageBinder(): IBinder? = if (!ensure()) null else ShizukuBinderWrapper(ServiceManager.getService("package"))
}
K

cat > $J/BackendDetect.kt <<'K'
package me.x.shizukuax
import android.content.Context
enum class Backend { SHIZUKU, ROOT, NONE }
object BackendDetect {
    fun cur(c: Context): Backend =
        if (ShizukuGate.ensure()) Backend.SHIZUKU else if (canSu()) Backend.ROOT else Backend.NONE
    private fun canSu(): Boolean = runCatching {
        val p = Runtime.getRuntime().exec(arrayOf("su", "-c", "id"))
        val out = p.inputStream.bufferedReader().readText()
        p.waitFor()
        out.contains("uid=0")
    }.getOrDefault(false)
    fun name(c: Context): String = when (cur(c)) {
        Backend.SHIZUKU -> "Shizuku"
        Backend.ROOT -> "KernelSU/Magisk"
        Backend.NONE -> "未连接"
    }
}
K

cat > $J/RootBackend.kt <<'K'
package me.x.shizukuax
object RootBackend {
    private fun su(cmd: String): String = runCatching {
        val p = Runtime.getRuntime().exec(arrayOf("su", "-c", cmd))
        val out = p.inputStream.bufferedReader().readText()
        val err = p.errorStream.bufferedReader().readText()
        p.waitFor()
        (out + err).trim()
    }.getOrDefault("err")
    fun setEnabled(pkg: String, en: Boolean) = su("pm ${if (en) "enable $pkg" else "disable-user --user current $pkg"}")
    fun clear(pkg: String) = su("pm clear --user current $pkg")
    fun uninstall(pkg: String) = su("pm uninstall --user current $pkg")
}
K

cat > $J/IPackageManagerCompat.kt <<'K'
package me.x.shizukuax
import android.os.IBinder
import android.os.Parcel
import java.lang.reflect.Field
object IPackageManagerCompat {
    private val TRANS_setEnabled: Int = tx("setApplicationEnabledSetting", 21)
    private val TRANS_clear: Int = tx("clearApplicationUserData", 22)
    private fun tx(name: String, fb: Int): Int = try {
        val cls = Class.forName("android.content.pm.IPackageManager\$Stub")
        cls.declaredFields.firstOrNull { it.name == "TRANSACTION_$name" }?.getInt(null) ?: fb
    } catch (_: Exception) { fb }
    private fun b(): IBinder = ShizukuGate.packageBinder() ?: throw IllegalStateException("no shizuku binder")
    fun setEnabled(pkg: String, en: Boolean) {
        val d = Parcel.obtain(); val r = Parcel.obtain()
        try {
            d.writeInterfaceToken("android.content.pm.IPackageManager")
            d.writeString(pkg)
            d.writeInt(if (en) 1 else 2)
            d.writeInt(0)
            d.writeString("me.x.shizukuax")
            b().transact(TRANS_setEnabled, d, r, 0)
            r.readException()
        } finally { d.recycle(); r.recycle() }
    }
    fun clear(pkg: String) {
        val d = Parcel.obtain(); val r = Parcel.obtain()
        try {
            d.writeInterfaceToken("android.content.pm.IPackageManager")
            d.writeString(pkg)
            d.writeStrongBinder(null)
            d.writeInt(0)
            b().transact(TRANS_clear, d, r, 0)
            r.readException()
        } finally { d.recycle(); r.recycle() }
    }
}
K

cat > $J/ProtectedPackages.kt <<'K'
package me.x.shizukuax
object ProtectedPackages {
    private val HARD = setOf(
        "com.android.systemui", "com.android.settings",
        "com.android.packageinstaller", "com.google.android.packageinstaller",
        "android", "android.permission", "com.android.permissioncontroller",
        "me.x.shizukuax"
    )
    private val SOFT = listOf(
        "com.android.phone", "com.android.mms", "com.android.contacts", "com.android.dialer",
        "com.google.android.gms", "com.google.android.gsf",
        "com.samsung.", "com.miui.", "com.coloros.", "com.heytap.",
        "com.huawei.", "com.vivo.", "com.oppo."
    )
    fun level(pkg: String): Int =
        if (HARD.contains(pkg)) 2 else if (SOFT.any { pkg.startsWith(it) }) 1 else 0
    fun blocked(pkg: String): Boolean = level(pkg) == 2
}
K

cat > $J/PmFacade.kt <<'K'
package me.x.shizukuax
import android.content.Context
import android.content.IntentSender
class PmFacade(private val c: Context) {
    private val a get() = c as MainActivity
    fun setEnabled(pkg: String, en: Boolean): String =
        if (ProtectedPackages.blocked(pkg)) "blocked" else when (BackendDetect.cur(c)) {
            BackendDetect.Backend.SHIZUKU -> runCatching { IPackageManagerCompat.setEnabled(pkg, en); "ok" }.getOrElse { it.message ?: "err" }
            BackendDetect.Backend.ROOT -> RootBackend.setEnabled(pkg, en)
            BackendDetect.Backend.NONE -> "no-backend"
        }
    fun clear(pkg: String): String =
        if (ProtectedPackages.blocked(pkg)) "blocked" else when (BackendDetect.cur(c)) {
            BackendDetect.Backend.SHIZUKU -> runCatching { IPackageManagerCompat.clear(pkg); "ok" }.getOrElse { it.message ?: "err" }
            BackendDetect.Backend.ROOT -> RootBackend.clear(pkg)
            BackendDetect.Backend.NONE -> "no-backend"
        }
    fun uninstall(pkg: String): String =
        if (ProtectedPackages.blocked(pkg)) "blocked" else when (BackendDetect.cur(c)) {
            BackendDetect.Backend.SHIZUKU -> runCatching {
                a.packageManager.packageInstaller.uninstall(pkg, IntentSender(null)); "ok"
            }.getOrElse { RootBackend.uninstall(pkg) }
            BackendDetect.Backend.ROOT -> RootBackend.uninstall(pkg)
            BackendDetect.Backend.NONE -> "no-backend"
        }
}
K

cat > $J/DetailDrawer.kt <<'K'
package me.x.shizukuax
import android.animation.ValueAnimator
import android.view.View
import android.widget.FrameLayout
import android.view.animation.DecelerateInterpolator
class DetailDrawer(private val scrim: FrameLayout, private val panel: View) {
    var open: Boolean = false
    fun show() { open = true; panel.visibility = View.VISIBLE; scrim.alpha = 0.5f; anim(0f) }
    fun hide() { open = false; scrim.alpha = 1f; anim(panel.width.toFloat().coerceAtLeast(1f)) }
    fun isOpen(): Boolean = open
    private fun anim(targetX: Float) {
        val w = panel.width.toFloat().coerceAtLeast(1f)
        ValueAnimator.ofFloat(panel.translationX, targetX).apply {
            duration = if (targetX == 0f) 300L else 260L
            interpolator = DecelerateInterpolator()
            addUpdateListener { panel.translationX = it.animatedValue as Float }
            start()
        }
    }
}
K

cat > $J/ProfileStore.kt <<'K'
package me.x.shizukuax
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
object ProfileStore {
    fun dir(c: Context) = File(c.getExternalFilesDir("profiles")!!).also { it.mkdirs() }
    fun list(c: Context): List<String> = dir(c).list()?.filter { it.endsWith(".json") }?.map { it.removeSuffix(".json") } ?: emptyList()
    fun save(c: Context, name: String, acts: JSONArray) = File(dir(c), "$name.json").writeText(JSONObject().put("name", name).put("acts", acts).toString(2))
    fun load(c: Context, name: String): JSONObject { val f = File(dir(c), "$name.json"); return if (f.exists()) JSONObject(f.readText()) else JSONObject() }
    fun delete(c: Context, name: String) { File(dir(c), "$name.json").delete() }
}
K

cat > $J/AppBridge.kt <<'K'
package me.x.shizukuax
import android.content.Context
import android.webkit.JavascriptInterface
import org.json.JSONArray
import org.json.JSONObject
class AppBridge(private val a: MainActivity) {
    private val pm = PmFacade(a)
    private val c: Context get() = a
    @JavascriptInterface fun backendName(): String = BackendDetect.name(c)
    @JavascriptInterface fun isReady(): Boolean = BackendDetect.cur(c) != BackendDetect.Backend.NONE
    @JavascriptInterface fun listApps(): String {
        val pm2 = a.packageManager
        val arr = JSONArray()
        for (p in pm2.getInstalledPackages(0)) {
            val ai = p.applicationInfo ?: continue
            val lvl = ProtectedPackages.level(p.packageName)
            arr.put(JSONObject()
                .put("pkg", p.packageName)
                .put("name", ai.loadLabel(pm2).toString())
                .put("enabled", ai.enabled)
                .put("system", (ai.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0)
                .put("lvl", lvl)
            )
        }
        return arr.toString()
    }
    @JavascriptInterface fun detail(pkg: String): String {
        val p = c.packageManager.getPackageInfo(pkg, 0)
        val ai = p.applicationInfo
        val lvl = ProtectedPackages.level(pkg)
        return JSONObject().apply {
            put("pkg", pkg)
            put("name", ai.loadLabel(c.packageManager))
            put("enabled", ai.enabled)
            put("ver", p.versionName ?: "")
            put("tgt", ai.targetSdkVersion)
            put("inst", p.firstInstallTime)
            put("upd", p.lastUpdateTime)
            put("path", ai.sourceDir ?: "")
            put("lvl", lvl)
        }.toString()
    }
    @JavascriptInterface fun freeze(pkg: String): String = pm.setEnabled(pkg, false)
    @JavascriptInterface fun enable(pkg: String): String = pm.setEnabled(pkg, true)
    @JavascriptInterface fun clearData(pkg: String): String = pm.clear(pkg)
    @JavascriptInterface fun uninstall(pkg: String): String = pm.uninstall(pkg)
    @JavascriptInterface fun batch(op: String, js: String): String {
        val L = JSONArray(js); var skip = 0
        for (i in 0 until L.length()) {
            val pkg = L.getString(i)
            if (ProtectedPackages.blocked(pkg)) { skip++; continue }
            when (op) {
                "freeze" -> pm.setEnabled(pkg, false)
                "enable" -> pm.setEnabled(pkg, true)
                "clear" -> pm.clear(pkg)
                "uninstall" -> pm.uninstall(pkg)
            }
        }
        return "ok skip=$skip"
    }
    @JavascriptInterface fun profiles(): String = JSONArray(ProfileStore.list(c)).toString()
    @JavascriptInterface fun saveProfile(name: String, acts: String) = ProfileStore.save(c, name, JSONArray(acts))
    @JavascriptInterface fun runProfile(name: String): String {
        val acts = ProfileStore.load(c, name).optJSONArray("acts") ?: return "empty"
        for (i in 0 until acts.length()) {
            val o = acts.getJSONObject(i)
            val pkg = o.getString("pkg")
            if (ProtectedPackages.blocked(pkg)) continue
            when (o.getString("op")) {
                "freeze" -> pm.setEnabled(pkg, false)
                "enable" -> pm.setEnabled(pkg, true)
                "clear" -> pm.clear(pkg)
                "uninstall" -> pm.uninstall(pkg)
            }
        }
        return "ok"
    }
}
K

# ---------- Web 前端 ----------
cat > $D/assets/web/index.html <<'K'
<!doctype html><html><head><meta charset=utf8><meta name=viewport content="width=device-width,initial-scale=1"><link rel=stylesheet href=style.css></head><body>
<div class=bar><span class=logo>Ax·Shizuku</span><span id=st class=badge>…</span><button class=mini onclick=toggle()>多选</button></div>
<div id=list class=grid></div><script src=app.js></script></body></html>
K

cat > $D/assets/web/detail.html <<'K'
<!doctype html><html><head><meta charset=utf8><link rel=stylesheet href=style.css></head><body class=detail>
<div class=dhead><div class=ava></div><div><b id=n></b><br><small id=p></small></div></div>
<div id=st class=badge></div><div class=rows id=r></div><div class=acts id=acts></div>
<script src=app.js></script><script>
var q=(location.search.split('pkg=')[1]||'');var d=JSON.parse(AxNative.detail(decodeURIComponent(q)));
n.textContent=d.name;p.textContent=d.pkg;st.textContent=d.enabled?'已启用':'已禁用';
r.innerHTML='<div>版本 '+d.ver+'</div><div>TargetSDK '+d.tgt+'</div><div>安装 '+new Date(d.inst).toLocaleDateString()+'</div><div>更新 '+new Date(d.upd).toLocaleDateString()+'</div><div class=path>'+d.path+'</div>';
if(d.lvl==2){st.textContent+=' · 受保护';acts.innerHTML='<i style=opacity:.5>白名单保护，禁止写操作</i>';}
else acts.innerHTML='<button onclick="g(\'freeze\')">冻结</button><button onclick="g(\'enable\')">启用</button><button onclick="g(\'clearData\')">清数据</button><button class=danger onclick="g(\'uninstall\')">卸载</button>';
function g(o){if(d.lvl==1&&!confirm('关键组件，确认'+o+'？'))return;alert(AxNative[o](d.pkg));location.reload();}
</script></body></html>
K

cat > $D/assets/web/style.css <<'K'
:root{--bg:#0b0d12;--card:linear-gradient(145deg,#1b2030,#11141d);--acc:#7c5cff;--t:#e8eaf0}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--t);font:14px/1.45 system-ui;-webkit-tap-highlight-color:transparent}
.bar{padding:16px 18px;display:flex;gap:10px;align-items:center}
.logo{font-weight:800;font-size:18px;background:linear-gradient(90deg,#7c5cff,#4dd0ff);-webkit-background-clip:text;color:transparent;flex:1}
.badge{padding:4px 10px;border-radius:99px;background:#1c2230;font-size:12px}
.mini{background:#232a3d;border:0;color:var(--t);border-radius:10px;padding:6px 10px;font-size:12px}
.grid{padding:12px;display:grid;gap:10px}
.card{background:var(--card);border-radius:16px;padding:14px;display:flex;justify-content:space-between;align-items:center;box-shadow:0 6px 20px #0006;transition:transform .15s,outline .1s}
.card:active{transform:scale(.98)}
.card.sel{outline:2px solid var(--acc);box-shadow:0 0 18px #7c5cff55}
.card small{opacity:.6}
.acts button{background:#232a3d;color:var(--t);border:0;border-radius:10px;padding:6px 9px;margin-left:6px;font-size:12px}
.acts .danger{background:linear-gradient(135deg,#ff5c7c,#ff8a5c)}
.mb{position:fixed;bottom:0;left:0;right:0;background:#12151f;display:flex;gap:6px;padding:10px;flex-wrap:wrap;border-top:1px solid #232a3d;animation:u .2s ease}
.mb button{padding:7px 10px;border-radius:10px;border:0;background:#232a3d;color:var(--t);font-size:12px}
.mb .danger{background:linear-gradient(135deg,#ff5c7c,#ff8a5c)}
@keyframes u{from{transform:translateY(100%)}to{transform:translateY(0)}}
.detail{padding:18px}.dhead{display:flex;gap:12px;align-items:center;margin-bottom:12px}
.ava{width:48px;height:48px;border-radius:14px;background:linear-gradient(135deg,#7c5cff,#4dd0ff)}
.rows div{padding:6px 0;border-bottom:1px solid #1c2230;font-size:13px}
.rows .path{opacity:.5;font-size:11px;word-break:break-all}
#acts{margin-top:16px;display:flex;gap:8px;flex-wrap:wrap}
#acts button{background:#232a3d;color:var(--t);border:0;border-radius:10px;padding:8px 12px}
K

cat > $D/assets/web/app.js <<'K'
var m=false;var s=new Set();function $(x){return document.querySelector(x)}
function ref(){
 st.textContent=AxNative.backendName()+' · '+(AxNative.isReady()?'已连接':'未连接');
 var A=JSON.parse(AxNative.listApps());
 list.innerHTML=A.map(function(a){
  return '<div class="card '+(s.has(a.pkg)?'sel':'')+'" onclick="tap(\''+a.pkg+'\')">'+
   '<div><b>'+a.name+'</b><br><small>'+a.pkg+' · '+(a.enabled?'启用':'禁用')+(a.lvl==2?' · 受保护':a.lvl==1?' · 关键':'')+'</small></div>'+
   '<div class=acts><button onclick="event.stopPropagation();ac(\'freeze\',\''+a.pkg+'\','+a.lvl+')">冻</button><button onclick="event.stopPropagation();ac(\'enable\',\''+a.pkg+'\','+a.lvl+')">启</button></div></div>';
 }).join('');
}
function tap(p){if(m){if(s.has(p))s.delete(p);else s.add(p);ref();return}location.href='detail.html?pkg='+encodeURIComponent(p)}
function ac(f,p,l){if(l==2){alert('受保护');return}if(l==1&&!confirm('关键组件，确认'+f+'？'))return;alert(AxNative[f](p));ref()}
function toggle(){m=!m;s.clear();mb();ref()}
function mb(){var b=document.getElementById('mb');if(!m&&b){b.remove();return}if(!b){b=document.createElement('div');b.id='mb';b.className='mb';document.body.appendChild(b)}
 b.innerHTML='<span style=flex:1>已选 '+s.size+'</span><button onclick="bt(\'freeze\')">冻</button><button onclick="bt(\'enable\')">启</button><button onclick="bt(\'clear\')">清</button><button class=danger onclick="bt(\'uninstall\')">卸</button><button onclick="toggle()">退出</button>'}
function bt(o){if(!s.size)return;if(!confirm('批量'+o+' '+s.size+'项？受保护项跳过'))return;alert(AxNative.batch(o,JSON.stringify(Array.from(s))));s.clear();ref()}
window.onload=function(){setTimeout(ref,400)}
K

chmod +x gradlew 2>/dev/null || true
echo "==> gen.sh ok"

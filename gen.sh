#!/bin/bash
# gen.sh —— 在 CI 中自动生成完整 Android 工程源码
set -e
D=app/src/main
mkdir -p $D/java/me/x/shizukuax $D/res/layout $D/res/values $D/res/drawable $D/assets/web gradle/wrapper

cat > settings.gradle.kts <<'K'
pluginManagement{repositories{google();mavenCentral();gradlePluginPortal()}}
dependencyResolutionManagement{repositories{google();mavenCentral()}}
rootProject.name="ShizukuAx";include(":app")
K

cat > build.gradle.kts <<'K'
plugins{id("com.android.application")version"8.2.2"apply false;id("org.jetbrains.kotlin.android")version"1.9.22"apply false}
K

cat > gradle.properties <<'K'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
K

cat > gradle/wrapper/gradle-wrapper.properties <<'K'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.5-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
K

cat > app/build.gradle.kts <<'K'
plugins{id("com.android.application");id("org.jetbrains.kotlin.android")}
android{
 namespace="me.x.shizukuax";compileSdk=34
 defaultConfig{applicationId="me.x.shizukuax";minSdk=26;targetSdk=34;versionCode=1;versionName="1.0.0"}
 buildFeatures{viewBinding=true}
 compileOptions{sourceCompatibility=JavaVersion.VERSION_17;targetCompatibility=JavaVersion.VERSION_17}
 kotlinOptions{jvmTarget="17"}
 signingConfigs{getByName("debug"){storeFile=file("$rootDir/debug.keystore")}}
}
dependencies{
 implementation("dev.rikka.shizuku:api:13.1.5")
 implementation("androidx.webkit:webkit:1.10.0")
 implementation("androidx.core:core-ktx:1.12.0")
 implementation("androidx.appcompat:appcompat:1.6.1")
 implementation("com.google.android.material:material:1.11.0")
 implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
 implementation("org.json:json:20231013")
}
K

cat > $D/AndroidManifest.xml <<'K'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"/>
<uses-permission android:name="android.permission.REQUEST_DELETE_PACKAGES"/>
<uses-permission android:name="android.permission.CLEAR_APP_USER_DATA"/>
<application android:theme="@style/T" android:label="Ax·Shizuku" android:icon="@drawable/ic" android:usesCleartextTraffic="true">
<activity android:name=".MainActivity" android:exported="true">
<intent-filter><action android:name="android.intent.action.MAIN"/>
<category android:name="android.intent.category.LAUNCHER"/></intent-filter>
</activity></application></manifest>
K

cat > $D/res/values/themes.xml <<'K'
<resources><style name="T" parent="Theme.Material3.DayNight.NoActionBar">
<item name="android:windowBackground">#0b0d12</item>
<item name="android:statusBarColor">#0b0d12</item>
</style></resources>
K

cat > $D/res/values/colors.xml <<'K'
<resources>
<color name="ax_bg">#0b0d12</color>
<color name="ax_acc">#7c5cff</color>
</resources>
K

cat > $D/res/drawable/ic.xml <<'K'
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="#7c5cff" android:pathData="M24,24h60v60h-60z"/></vector>
K

cat > $D/res/layout/activity_main.xml <<'K'
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/scrim" android:layout_width="match_parent" android:layout_height="match_parent">
<WebView android:id="@+id/web" android:layout_width="match_parent" android:layout_height="match_parent"/>
<FrameLayout android:id="@+id/detailPanel" android:layout_width="320dp" android:layout_height="match_parent" android:layout_gravity="end" android:background="#11141d" android:visibility="gone" android:translationX="320dp">
<WebView android:id="@+id/detailWeb" android:layout_width="match_parent" android:layout_height="match_parent"/></FrameLayout>
</FrameLayout>
K

cat > $D/java/me/x/shizukuax/MainActivity.kt <<'K'
package me.x.shizukuax
import android.os.Bundle
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity
import dev.rikka.shizuku.Shizuku
import me.x.shizukuax.databinding.ActivityMainBinding
class MainActivity : AppCompatActivity(){
 private lateinit var b:ActivityMainBinding
 private val dr by lazy { DetailDrawer(b.scrim,b.detailPanel) }
 override fun onCreate(s:Bundle?){super.onCreate(s)
  b=ActivityMainBinding.inflate(layoutInflater);setContentView(b.root)
  if(!Shizuku.isPreV11())Shizuku.requestPermission(0)
  Shizuku.addRequestPermissionResultListener{_,r->if(r==Shizuku.PERMISSION_GRANTED)ShizukuGate.ensure()}
  b.web.settings.javaScriptEnabled=true;b.web.settings.allowFileAccess=true
  b.web.addJavascriptInterface(AppBridge(this),"AxNative")
  b.web.loadUrl("file:///android_asset/web/index.html")
  val dw=findViewById<WebView>(R.id.detailWeb)
  dw.settings.javaScriptEnabled=true
  dw.addJavascriptInterface(AppBridge(this),"AxNative")
  b.scrim.setOnClickListener{dr.hide()}
 }
 override fun onBackPressed(){if(dr.isOpen())dr.hide()else super.onBackPressed()}
}
K

cat > $D/java/me/x/shizukuax/ShizukuGate.kt <<'K'
package me.x.shizukuax
import android.os.IBinder
import android.os.ServiceManager
import dev.rikka.shizuku.Shizuku
import rikka.shizuku.ShizukuBinderWrapper
object ShizukuGate{
 var ready=false
 fun ensure():Boolean{ready=runCatching{Shizuku.pingBinder()}.getOrDefault(false);return ready}
 fun pb():IBinder?=if(!ensure())null else ShizukuBinderWrapper(ServiceManager.getService("package"))
}
K

cat > $D/java/me/x/shizukuax/BackendDetect.kt <<'K'
package me.x.shizukuax
import android.content.Context
enum class Backend{SHIZUKU,ROOT,NONE}
object BackendDetect{
 fun cur(c:Context)=if(ShizukuGate.ensure())Backend.SHIZUKU else if(canSu())Backend.ROOT else Backend.NONE
 private fun canSu()=runCatching{Runtime.getRuntime().exec(arrayOf("su","-c","id")).inputStream.bufferedReader().readText().contains("uid=0")}.getOrDefault(false)
 fun name(c:Context)=when(cur(c)){Backend.SHIZUKU->"Shizuku";Backend.ROOT->"KernelSU/Magisk";Backend.NONE->"未连接"}
}
K

cat > $D/java/me/x/shizukuax/RootBackend.kt <<'K'
package me.x.shizukuax
object RootBackend{
 private fun su(c:String)=runCatching{val p=Runtime.getRuntime().exec(arrayOf("su","-c",c));p.waitFor();(p.inputStream.bufferedReader().readText()+p.errorStream.bufferedReader().readText()).trim()}.getOrDefault("err")
 fun setEnabled(p:String,e:Boolean)=su("pm ${if(e)"enable $p" else "disable-user --user current $p"}")
 fun clear(p:String)=su("pm clear --user current $p")
 fun uninstall(p:String)=su("pm uninstall --user current $p")
}
K

cat > $D/java/me/x/shizukuax/IPackageManagerCompat.kt <<'K'
package me.x.shizukuax
import android.os.*
object IPackageManagerCompat{
 private val TE=tx("setApplicationEnabledSetting",21)
 private val TC=tx("clearApplicationUserData",22)
 private fun tx(n:String,f:Int)=try{Class.forName("android.content.pm.IPackageManager\$Stub").declaredFields.firstOrNull{it.name=="TRANSACTION_$n"}?.getInt(null)?:f}catch(_:Exception){f}
 private fun b()=ShizukuGate.pb()?:throw IllegalStateException("no-binder")
 fun setEnabled(p:String,e:Boolean){val d=Parcel.obtain();val r=Parcel.obtain();try{d.writeInterfaceToken("android.content.pm.IPackageManager");d.writeString(p);d.writeInt(if(e)1 else 2);d.writeInt(0);d.writeString("me.x.shizukuax");b().transact(TE,d,r,0);r.readException()}finally{d.recycle();r.recycle()}}
 fun clear(p:String){val d=Parcel.obtain();val r=Parcel.obtain();try{d.writeInterfaceToken("android.content.pm.IPackageManager");d.writeString(p);d.writeStrongBinder(null);d.writeInt(0);b().transact(TC,d,r,0);r.readException()}finally{d.recycle();r.recycle()}}
}
K

cat > $D/java/me/x/shizukuax/ProtectedPackages.kt <<'K'
package me.x.shizukuax
object ProtectedPackages{
 private val HARD=setOf("com.android.systemui","com.android.settings","com.android.packageinstaller","com.google.android.packageinstaller","android","android.permission","com.android.permissioncontroller","me.x.shizukuax")
 private val SOFT=listOf("com.android.phone","com.android.mms","com.android.contacts","com.android.dialer","com.google.android.gms","com.google.android.gsf","com.samsung.","com.miui.","com.coloros.","com.heytap.","com.huawei.","com.vivo.","com.oppo.")
 fun level(p:String):Int=if(HARD.contains(p))2 else if(SOFT.any{p.startsWith(it)})1 else 0
 fun blocked(p:String)=level(p)==2
 fun reason(p:String):String=when(level(p)){2->"系统核心，操作会导致系统崩溃";1->"系统关键服务，可能影响通话/账号/框架";else->""}
}
K

cat > $D/java/me/x/shizukuax/PmFacade.kt <<'K'
package me.x.shizukuax
import android.content.Context
class PmFacade(private val c:Context){
 private val a get()=c as MainActivity
 fun setEnabled(p:String,e:Boolean):String=if(ProtectedPackages.blocked(p))"blocked:${ProtectedPackages.reason(p)}" else when(BackendDetect.cur(c)){Backend.SHIZUKU->runCatching{IPackageManagerCompat.setEnabled(p,e);"ok"}.getOrElse{it.message?:"err"};Backend.ROOT->RootBackend.setEnabled(p,e);Backend.NONE->"no-backend"}
 fun clear(p:String):String=if(ProtectedPackages.blocked(p))"blocked" else when(BackendDetect.cur(c)){Backend.SHIZUKU->runCatching{IPackageManagerCompat.clear(p);"ok"}.getOrElse{it.message?:"err"};Backend.ROOT->RootBackend.clear(p);Backend.NONE->"no-backend"}
 fun uninstall(p:String):String=if(ProtectedPackages.blocked(p))"blocked" else when(BackendDetect.cur(c)){Backend.SHIZUKU->runCatching{a.packageManager.packageInstaller.uninstall(p,null);"ok"}.getOrElse{it.message?:"err"};Backend.ROOT->RootBackend.uninstall(p);Backend.NONE->"no-backend"}
}
K

cat > $D/java/me/x/shizukuax/DetailDrawer.kt <<'K'
package me.x.shizukuax
import android.animation.ValueAnimator
import android.view.View
import android.widget.FrameLayout
class DetailDrawer(private val root:FrameLayout,private val p:View){
 var open=false
 fun show(){open=true;anim(0f);p.visibility=View.VISIBLE;root.alpha=0.5f}
 fun hide(){open=false;anim(p.width.toFloat().coerceAtLeast(1f));root.alpha=1f}
 fun isOpen()=open
 private fun anim(x:Float){ValueAnimator.ofFloat(p.translationX,x).apply{duration=if(x==0f)300 else 260;interpolator=android.view.animation.DecelerateInterpolator();addUpdateListener{p.translationX=it.animatedValue as Float;if(x>0f&&it.animatedFraction==1f)p.visibility=View.GONE};start()}}
}
K

cat > $D/java/me/x/shizukuax/AppBridge.kt <<'K'
package me.x.shizukuax
import android.content.Context
import android.webkit.JavascriptInterface
import org.json.JSONArray
import org.json.JSONObject
class AppBridge(private val a:MainActivity){
 private val pm=PmFacade(a);val c:Context get()=a
 @JavascriptInterface fun backendName()=BackendDetect.name(c)
 @JavascriptInterface fun isReady()=BackendDetect.cur(c)!=BackendDetect.Backend.NONE
 @JavascriptInterface fun listApps():String{val p=a.packageManager;val A=JSONArray();p.getInstalledPackages(0).forEach{val ai=it.applicationInfo;val l=ProtectedPackages.level(it.packageName);A.put(JSONObject().put("pkg",it.packageName).put("name",ai.loadLabel(p)).put("enabled",ai.enabled).put("system",(ai.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM)!=0).put("lvl",l).put("reason",ProtectedPackages.reason(it.packageName)))};return A.toString()}
 @JavascriptInterface fun detail(pkg:String):String{val p=c.packageManager.getPackageInfo(pkg,0);val ai=p.applicationInfo;val l=ProtectedPackages.level(pkg);return JSONObject().apply{put("pkg",pkg);put("name",ai.loadLabel(c.packageManager));put("enabled",ai.enabled);put("ver",p.versionName);put("tgt",ai.targetSdkVersion);put("inst",p.firstInstallTime);put("upd",p.lastUpdateTime);put("path",ai.sourceDir);put("lvl",l);put("reason",ProtectedPackages.reason(pkg))}.toString()}
 @JavascriptInterface fun freeze(p:String)=pm.setEnabled(p,false)
 @JavascriptInterface fun enable(p:String)=pm.setEnabled(p,true)
 @JavascriptInterface fun clearData(p:String)=pm.clear(p)
 @JavascriptInterface fun uninstall(p:String)=pm.uninstall(p)
 @JavascriptInterface fun batch(op:String,js:String):String{val L=JSONArray(js);var sk=0;for(i in 0 until L.length()){val p=L.getString(i);if(ProtectedPackages.blocked(p)){sk++;continue};when(op){"freeze"->pm.setEnabled(p,false);"enable"->pm.setEnabled(p,true);"clear"->pm.clear(p);"uninstall"->pm.uninstall(p)}};"ok skip=$sk"}
 @JavascriptInterface fun profiles()=JSONArray(ProfileStore.list(c)).toString()
 @JavascriptInterface fun saveProfile(n:String,acts:String)=ProfileStore.save(c,n,JSONArray(acts))
 @JavascriptInterface fun runProfile(n:String):String{val A=ProfileStore.load(c,n).optJSONArray("acts")?:return"empty";for(i in 0 until A.length()){val o=A.getJSONObject(i);val p=o.getString("pkg");if(ProtectedPackages.blocked(p))continue;when(o.getString("op")){"freeze"->pm.setEnabled(p,false);"enable"->pm.setEnabled(p,true);"clear"->pm.clear(p);"uninstall"->pm.uninstall(p)}};"ok"}
}
K

cat > $D/java/me/x/shizukuax/ProfileStore.kt <<'K'
package me.x.shizukuax
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
object ProfileStore{
 fun dir(c:Context)=File(c.getExternalFilesDir("profiles")).also{it.mkdirs()}
 fun list(c:Context)=dir(c).list()?.filter{it.endsWith(".json")}?.map{it.removeSuffix(".json")}?:emptyList()
 fun save(c:Context,n:String,acts:JSONArray)=File(dir(c),"$n.json").writeText(JSONObject().put("name",n).put("acts",acts).toString(2))
 fun load(c:Context,n:String):JSONObject{val f=File(dir(c),"$n.json");return if(f.exists())JSONObject(f.readText())else JSONObject()}
 fun delete(c:Context,n:String)=File(dir(c),"$n.json").delete()
}
K

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
const q=(location.search.split('pkg=')[1]||'');const d=JSON.parse(AxNative.detail(decodeURIComponent(q)));
n.textContent=d.name;p.textContent=d.pkg;st.textContent=d.enabled?'已启用':'已禁用';
r.innerHTML=`<div>版本 ${d.ver}</div><div>TargetSDK ${d.tgt}</div><div>安装 ${new Date(d.inst).toLocaleDateString()}</div><div>更新 ${new Date(d.upd).toLocaleDateString()}</div><div class=path>${d.path}</div>`;
if(d.lvl==2){st.textContent+=' · 受保护';acts.innerHTML='<i>白名单保护，禁止写操作</i>'}
else acts.innerHTML=`<button onclick="g('freeze')">冻结</button><button onclick="g('enable')">启用</button><button onclick="g('clearData')">清数据</button><button class=danger onclick="g('uninstall')">卸载</button>`;
function g(o){if(d.lvl==1&&!confirm('关键组件，确认'+o+'？\n'+d.reason))return;alert(AxNative[o](d.pkg));location.reload()}
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
#acts .danger{background:linear-gradient(135deg,#ff5c7c,#ff8a5c)}
K

cat > $D/assets/web/app.js <<'K'
let m=false;const s=new Set();const $=x=>document.querySelector(x)
function ref(){st.textContent=AxNative.backendName()+' · '+(AxNative.isReady()?'已连接':'未连接');const A=JSON.parse(AxNative.listApps());list.innerHTML=A.map(a=>`<div class="card ${s.has(a.pkg)?'sel':''}" onclick="tap('${a.pkg}')"><div><b>${a.name}</b><br><small>${a.pkg} · ${a.enabled?'启用':'禁用'}${a.lvl==2?' · 受保护':a.lvl==1?' · 关键':''}</small></div><div class=acts><button onclick="event.stopPropagation();ac('freeze','${a.pkg}',${a.lvl})">冻</button><button onclick="event.stopPropagation();ac('enable','${a.pkg}',${a.lvl})">启</button></div></div>`).join('')}
function tap(p){if(m){s.has(p)?s.delete(p):s.add(p);ref();return}location.href='detail.html?pkg='+encodeURIComponent(p)}
function ac(f,p,l){if(l==2){alert('受保护：'+AxNative.detail(p).reason);return}if(l==1&&!confirm('关键组件，确认'+f+'？'))return;alert(AxNative[f](p));ref()}
function toggle(){m=!m;s.clear();mb();ref()}
function mb(){let b=document.getElementById('mb');if(!m&&b){b.remove();return}if(!b){b=document.createElement('div');b.id='mb';b.className='mb';document.body.appendChild(b)}b.innerHTML=`<span style=flex:1>已选 ${s.size}</span><button onclick="bt('freeze')">冻</button><button onclick="bt('enable')">启</button><button onclick="bt('clear')">清</button><button class=danger onclick="bt('uninstall')">卸</button><button onclick="toggle()">退出</button>`}
function bt(o){if(!s.size)return;if(!confirm('批量'+o+' '+s.size+'项？受保护项自动跳过'))return;alert(AxNative.batch(o,JSON.stringify([...s])));s.clear();ref()}
window.onload=()=>setTimeout(ref,400)
K

echo "gen ok"
chmod +x gradlew 2>/dev/null || true

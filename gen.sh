#!/bin/bash
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
distributionUrl=https\://services.gradle.org/distributions/gradle-8.5-bin.zip
K
cat > app/build.gradle.kts <<'K'
plugins{id("com.android.application");id("org.jetbrains.kotlin.android")}
android{
 namespace="me.x.shizukuax";compileSdk=34
 defaultConfig{applicationId="me.x.shizukuax";minSdk=26;targetSdk=34;versionCode=1;versionName="1.0.0"}
 buildFeatures{viewBinding=true}
 compileOptions{sourceCompatibility=JavaVersion.VERSION_17;targetCompatibility=JavaVersion.VERSION_17}
 kotlinOptions{jvmTarget="17"}
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
<uses-permission android:name="android.permission.CLEAR_APP_USER_DATA"/>
<application android:theme="@style/T" android:label="Ax·Shizuku" android:icon="@drawable/ic">
<activity android:name=".MainActivity" android:exported="true">
<intent-filter><action android:name="android.intent.action.MAIN"/>
<category android:name="android.intent.category.LAUNCHER"/></intent-filter>
</activity></application></manifest>
K
cat > $D/res/values/themes.xml <<'K'
<resources><style name="T" parent="Theme.Material3.DayNight.NoActionBar">
<item name="android:windowBackground">#0b0d12</item></style></resources>
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
 override fun onCreate(s:Bundle?){super.onCreate(s)
  b=ActivityMainBinding.inflate(layoutInflater);setContentView(b.root)
  if(!Shizuku.isPreV11())Shizuku.requestPermission(0)
  Shizuku.addRequestPermissionResultListener{_,r->if(r==Shizuku.PERMISSION_GRANTED)ShizukuGate.ensure()}
  b.web.settings.javaScriptEnabled=true;b.web.settings.allowFileAccess=true
  b.web.addJavascriptInterface(AppBridge(this),"AxNative")
  b.web.loadUrl("file:///android_asset/web/index.html")
  val dw=findViewById<WebView>(R.id.detailWeb);dw.settings.javaScriptEnabled=true
  dw.addJavascriptInterface(AppBridge(this),"AxNative")
  val dr=DetailDrawer(b.scrim,b.detailPanel)
  b.scrim.setOnClickListener{dr.hide()}
 }
 override fun onBackPressed(){if(drawer().isOpen())drawer().hide()else super.onBackPressed()}
 private fun drawer():DetailDrawer=DetailDrawer(b.scrim,b.detailPanel)
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
 private fun b()=ShizukuGate.pb()?:throw IllegalStateException("no binder")
 fun setEnabled(p:String,e:Boolean){val d=Parcel.obtain();val r=Parcel.obtain();try{d.writeInterfaceToken("android.content.pm.IPackageManager");d.writeString(p);d.writeInt(if(e)1 else 2);d.writeInt(0);d.writeString("me.x.shizukuax");b().transact(TE,d,r,0);r.readException()}finally{d.recycle();r.recycle()}}
 fun clear(p:String){val d=Parcel.obtain();val r=Parcel.obtain();try{d.writeInterfaceToken("android.content.pm.IPackageManager");d.writeString(p);d.writeStrongBinder(null);d.writeInt(0);b().transact(TC,d,r,0);r.readException()}finally{d.recycle();r.recycle()}}
}
K

cat > $D/java/me/x/shizukuax/ProtectedPackages.kt <<'K'
package me.x.shizukuax
object ProtectedPackages{
 private val HARD=setOf("com.android.systemui","com.android.settings","com.android.packageinstaller","com.google.android.packageinstaller","android","android.permission","com.android.permissioncontroller","me.x.shizukuax")
 private val SOFT=listOf("com.android.phone","com.android.mms","com.android.contacts","com.android.dialer","com.google.android.gms","com.google.android.gsf","com.samsung.","com.miui.","com.coloros.","com.heytap.","com.huawei.","com.vivo.","com.oppo.")
 fun level(p:String)=when{if(HARD.contains(p))2 else if(SOFT.any{p.startsWith(it)})1 else 0}
 fun blocked(p:String)=level(p)==2
}
K

cat > $D/java/me/x/shizukuax/PmFacade.kt <<'K'
package me.x.shizukuax
import android.content.Context
class PmFacade(private val c:Context){
 private val a get()=c as MainActivity
 fun setEnabled(p:String,e:Boolean)=if(ProtectedPackages.blocked(p))"blocked" else when(BackendDetect.cur(c)){Backend.SHIZUKU->runCatching{IPackageManagerCompat.setEnabled(p,e);"ok"}.getOrElse{it.message?:"err"};Backend.ROOT->RootBackend.setEnabled(p,e);Backend.NONE->"no-backend"}
 fun clear(p:String)=if(ProtectedPackages.blocked(p))"blocked" else when(BackendDetect.cur(c)){Backend.SHIZUKU->runCatching{IPackageManagerCompat.clear(p);"ok"}.getOrElse{it.message?:"err"};Backend.ROOT->RootBackend.clear(p);Backend.NONE->"no-backend"}
 fun uninstall(p:String)=if(ProtectedPackages.blocked(p))"blocked" else when(BackendDetect.cur(c)){Backend.SHIZUKU->runCatching{a.packageManager.packageInstaller.uninstall(p,null);"ok"}.getOrElse{it.message?:"err"};Backend.ROOT->RootBackend.uninstall(p);Backend.NONE->"no-backend"}
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
 @Javas

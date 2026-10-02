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

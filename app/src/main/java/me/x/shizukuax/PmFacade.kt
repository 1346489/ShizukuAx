package me.x.shizukuax
import android.content.Context
class PmFacade(private val c:Context){
 private val a get()=c as MainActivity
 fun setEnabled(p:String,e:Boolean):String=if(ProtectedPackages.blocked(p))"blocked:${ProtectedPackages.reason(p)}" else when(BackendDetect.cur(c)){Backend.SHIZUKU->runCatching{IPackageManagerCompat.setEnabled(p,e);"ok"}.getOrElse{it.message?:"err"};Backend.ROOT->RootBackend.setEnabled(p,e);Backend.NONE->"no-backend"}
 fun clear(p:String):String=if(ProtectedPackages.blocked(p))"blocked" else when(BackendDetect.cur(c)){Backend.SHIZUKU->runCatching{IPackageManagerCompat.clear(p);"ok"}.getOrElse{it.message?:"err"};Backend.ROOT->RootBackend.clear(p);Backend.NONE->"no-backend"}
 fun uninstall(p:String):String=if(ProtectedPackages.blocked(p))"blocked" else when(BackendDetect.cur(c)){
  Backend.SHIZUKU->runCatching{
    val pi=a.packageManager.packageInstaller
    val si=android.content.IntentSender(null)
    pi.uninstall(p,si);"ok"
  }.getOrElse{ RootBackend.uninstall(p) }
  Backend.ROOT->RootBackend.uninstall(p)
  Backend.NONE->"no-backend"
 }
}

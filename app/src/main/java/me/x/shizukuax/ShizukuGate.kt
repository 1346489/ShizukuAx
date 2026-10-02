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

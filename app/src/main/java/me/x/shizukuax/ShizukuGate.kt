package me.x.shizukuax

import android.os.IBinder
import android.os.ServiceManager
import dev.rikka.shizuku.Shizuku
import rikka.shizuku.ShizukuBinderWrapper

object ShizukuGate {

    var ready: Boolean = false

    fun ensure(): Boolean {
        ready = try { Shizuku.pingBinder() } catch (e: Exception) { false }
        return ready
    }

    fun pb(): IBinder? {
        if (!ensure()) return null
        return ShizukuBinderWrapper(ServiceManager.getService("package"))
    }
}

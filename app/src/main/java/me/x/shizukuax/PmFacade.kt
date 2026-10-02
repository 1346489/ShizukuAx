package me.x.shizukuax

import android.content.Context
import android.content.IntentSender

class PmFacade(private val ctx: Context) {

    fun setEnabled(pkg: String, enable: Boolean): String {
        if (ProtectedPackages.blocked(pkg)) return "blocked"
        return when (BackendDetect.cur(ctx)) {
            BackendDetect.Backend.SHIZUKU -> {
                try { IPackageManagerCompat.setEnabled(pkg, enable); "ok" }
                catch (e: Exception) { e.message ?: "err" }
            }
            BackendDetect.Backend.ROOT -> RootBackend.setEnabled(pkg, enable)
            BackendDetect.Backend.NONE -> "no-backend"
        }
    }

    fun clear(pkg: String): String {
        if (ProtectedPackages.blocked(pkg)) return "blocked"
        return when (BackendDetect.cur(ctx)) {
            BackendDetect.Backend.SHIZUKU -> {
                try { IPackageManagerCompat.clear(pkg); "ok" }
                catch (e: Exception) { e.message ?: "err" }
            }
            BackendDetect.Backend.ROOT -> RootBackend.clear(pkg)
            BackendDetect.Backend.NONE -> "no-backend"
        }
    }

    fun uninstall(pkg: String): String {
        if (ProtectedPackages.blocked(pkg)) return "blocked"
        return when (BackendDetect.cur(ctx)) {
            BackendDetect.Backend.SHIZUKU -> {
                try {
                    val pi = (ctx as MainActivity).packageManager.packageInstaller
                    pi.uninstall(pkg, IntentSender(null))
                    "ok"
                } catch (e: Exception) {
                    // SELinux 可能拦截普通 shell 的卸载，降级走 su
                    RootBackend.uninstall(pkg)
                }
            }
            BackendDetect.Backend.ROOT -> RootBackend.uninstall(pkg)
            BackendDetect.Backend.NONE -> "no-backend"
        }
    }
}

package me.x.shizukuax

import android.content.Context
import android.content.pm.PackageManager
import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * 后端探测：
 *  优先级：KernelSU / Magisk (root su)  >  Shizuku  >  NONE
 *
 * - 有 root (KernelSU / Magisk / 普通 su) 时：走 `su -c 'pm ...'`，效果等同 adb shell
 * - 有 Shizuku 时：走 Binder 代理
 * - 都没有：所有写操作返回 "no-backend"
 */
enum class Backend { ROOT_SU, SHIZUKU, NONE }

object BackendDetect {

    @Volatile
    private var cachedRoot: Boolean? = null

    fun current(ctx: Context): Backend {
        if (ShizukuGate.ensure()) return Backend.SHIZUKU
        if (hasRoot()) return Backend.ROOT_SU
        return Backend.NONE
    }

    fun backendName(ctx: Context): String = when (current(ctx)) {
        Backend.ROOT_SU -> if (hasKernelSu(ctx)) "KernelSU" else "Magisk / su"
        Backend.SHIZUKU -> "Shizuku"
        Backend.NONE -> "未连接"
    }

    /** 是否具备 root (KernelSU / Magisk / 普通 su) */
    private fun hasRoot(): Boolean {
        cachedRoot?.let { return it }
        val ok = runCatching {
            val p = Runtime.getRuntime().exec(arrayOf("su", "-c", "id -u"))
            val out = p.inputStream.bufferedReader().readText().trim()
            p.waitFor() == 0 && out == "0"
        }.getOrDefault(false)
        cachedRoot = ok
        return ok
    }

    /** 是否 KernelSU（通过 /proc 或包名判断） */
    private fun hasKernelSu(ctx: Context): Boolean {
        return runCatching {
            ctx.packageManager.getPackageInfo("me.weishu.kernelsu", 0)
            true
        }.getOrDefault(false)
                || runCatching {
            FileExists("/system/bin/kernelsu") || FileExists("/system/xbin/kernelsu")
        }.getOrDefault(false)
    }

    @Suppress("SameParameterValue")
    private fun FileExists(path: String): Boolean =
        runCatching { Runtime.getRuntime().exec(arrayOf("test", "-f", path)).waitFor() == 0 }
            .getOrDefault(false)
}

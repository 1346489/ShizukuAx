package me.x.shizukuax

import android.content.Context

enum class Backend { SHIZUKU, ROOT, NONE }

object BackendDetect {

    fun cur(c: Context): Backend {
        if (ShizukuGate.ensure()) return Backend.SHIZUKU
        if (canSu()) return Backend.ROOT
        return Backend.NONE
    }

    private fun canSu(): Boolean {
        return try {
            val p = Runtime.getRuntime().exec(arrayOf("su", "-c", "id"))
            p.waitFor()
            p.inputStream.bufferedReader().readText().contains("uid=0")
        } catch (e: Exception) {
            false
        }
    }

    fun name(c: Context): String {
        return when (cur(c)) {
            Backend.SHIZUKU -> "Shizuku"
            Backend.ROOT -> "KernelSU / Magisk"
            Backend.NONE -> "未连接"
        }
    }
}

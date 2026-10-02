package me.x.shizukuax
import android.content.Context
enum class Backend{SHIZUKU,ROOT,NONE}
object BackendDetect{
 fun cur(c:Context)=if(ShizukuGate.ensure())Backend.SHIZUKU else if(canSu())Backend.ROOT else Backend.NONE
 private fun canSu()=runCatching{Runtime.getRuntime().exec(arrayOf("su","-c","id")).inputStream.bufferedReader().readText().contains("uid=0")}.getOrDefault(false)
 fun name(c:Context)=when(cur(c)){Backend.SHIZUKU->"Shizuku";Backend.ROOT->"KernelSU/Magisk";Backend.NONE->"未连接"}
}

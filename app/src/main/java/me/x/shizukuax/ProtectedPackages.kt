package me.x.shizukuax
object ProtectedPackages{
 private val HARD=setOf("com.android.systemui","com.android.settings","com.android.packageinstaller","com.google.android.packageinstaller","android","android.permission","com.android.permissioncontroller","me.x.shizukuax")
 private val SOFT=listOf("com.android.phone","com.android.mms","com.android.contacts","com.android.dialer","com.google.android.gms","com.google.android.gsf","com.samsung.","com.miui.","com.coloros.","com.heytap.","com.huawei.","com.vivo.","com.oppo.")
 fun level(p:String):Int=if(HARD.contains(p))2 else if(SOFT.any{p.startsWith(it)})1 else 0
 fun blocked(p:String)=level(p)==2
 fun reason(p:String):String=when(level(p)){2->"系统核心，操作会导致系统崩溃";1->"系统关键服务，可能影响通话/账号/框架";else->""}
}

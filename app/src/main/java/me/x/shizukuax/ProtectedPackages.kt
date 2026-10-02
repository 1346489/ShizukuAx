package me.x.shizukuax

object ProtectedPackages {

    private val HARD: Set<String> = setOf(
        "com.android.systemui",
        "com.android.settings",
        "com.android.packageinstaller",
        "com.google.android.packageinstaller",
        "android",
        "android.permission",
        "com.android.permissioncontroller",
        "me.x.shizukuax"
    )

    private val SOFT: List<String> = listOf(
        "com.android.phone",
        "com.android.mms",
        "com.android.contacts",
        "com.android.dialer",
        "com.google.android.gms",
        "com.google.android.gsf",
        "com.samsung.",
        "com.miui.",
        "com.coloros.",
        "com.heytap.",
        "com.huawei.",
        "com.vivo.",
        "com.oppo."
    )

    fun level(pkg: String): Int {
        if (HARD.contains(pkg)) return 2
        for (p in SOFT) {
            if (pkg.startsWith(p)) return 1
        }
        return 0
    }

    fun blocked(pkg: String): Boolean = level(pkg) == 2

    fun reason(pkg: String): String {
        return when (level(pkg)) {
            2 -> "系统核心组件，禁止写操作，防止变砖"
            1 -> "系统关键服务，操作可能影响通话 / 账号 / 框架"
            else -> ""
        }
    }
}

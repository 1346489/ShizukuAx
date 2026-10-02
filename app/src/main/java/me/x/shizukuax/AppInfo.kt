package me.x.shizukuax

import org.json.JSONObject

/**
 * 应用信息。字段与 Web 端约定一致。
 */
data class AppInfo(
    val pkg: String,
    val name: String,
    val versionName: String,
    val versionCode: Long,
    val enabled: Boolean,
    val system: Boolean,
    val installTime: Long,
    val updateTime: Long,
    val targetSdk: Int,
    val permissions: List<String>,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("pkg", pkg)
        put("name", name)
        put("versionName", versionName)
        put("versionCode", versionCode)
        put("enabled", enabled)
        put("system", system)
        put("installTime", installTime)
        put("updateTime", updateTime)
        put("targetSdk", targetSdk)
        put("permissions", permissions.joinToString(","))
    }
}

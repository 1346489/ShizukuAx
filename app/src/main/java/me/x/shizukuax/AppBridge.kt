package me.x.shizukuax

import android.content.Context
import android.webkit.JavascriptInterface
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

class AppBridge(private val a: MainActivity) {

    private val pm: PmFacade = PmFacade(a)
    private val ctx: Context get() = a

    @JavascriptInterface
    fun backendName(): String = BackendDetect.name(ctx)

    @JavascriptInterface
    fun isReady(): Boolean = BackendDetect.cur(ctx) != BackendDetect.Backend.NONE

    @JavascriptInterface
    fun listApps(): String {
        val pkgManager = ctx.packageManager
        val arr = JSONArray()
        val pkgs = pkgManager.getInstalledPackages(0)
        for (info in pkgs) {
            val ai = info.applicationInfo
            val lvl = ProtectedPackages.level(info.packageName)
            val o = JSONObject()
            o.put("pkg", info.packageName)
            o.put("name", ai.loadLabel(pkgManager).toString())
            o.put("enabled", ai.enabled)
            o.put("system", (ai.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0)
            o.put("lvl", lvl)
            o.put("reason", ProtectedPackages.reason(info.packageName))
            arr.put(o)
        }
        return arr.toString()
    }

    @JavascriptInterface
    fun detail(pkg: String): String {
        val pm2 = ctx.packageManager
        val info = pm2.getPackageInfo(pkg, 0)
        val ai = info.applicationInfo
        val lvl = ProtectedPackages.level(pkg)
        val o = JSONObject()
        o.put("pkg", pkg)
        o.put("name", ai.loadLabel(pm2).toString())
        o.put("enabled", ai.enabled)
        o.put("ver", info.versionName)
        o.put("tgt", ai.targetSdkVersion)
        o.put("inst", info.firstInstallTime)
        o.put("upd", info.lastUpdateTime)
        o.put("path", ai.sourceDir)
        o.put("lvl", lvl)
        o.put("reason", ProtectedPackages.reason(pkg))
        return o.toString()
    }

    @JavascriptInterface
    fun freeze(pkg: String): String = pm.setEnabled(pkg, false)

    @JavascriptInterface
    fun enable(pkg: String): String = pm.setEnabled(pkg, true)

    @JavascriptInterface
    fun clearData(pkg: String): String = pm.clear(pkg)

    @JavascriptInterface
    fun uninstall(pkg: String): String = pm.uninstall(pkg)

    @JavascriptInterface
    fun batch(op: String, js: String): String {
        val list = JSONArray(js)
        var skip = 0
        for (i in 0 until list.length()) {
            val pkg = list.getString(i)
            if (ProtectedPackages.blocked(pkg)) { skip++; continue }
            when (op) {
                "freeze" -> pm.setEnabled(pkg, false)
                "enable" -> pm.setEnabled(pkg, true)
                "clear" -> pm.clear(pkg)
                "uninstall" -> pm.uninstall(pkg)
            }
        }
        return "ok skip=" + skip
    }

    @JavascriptInterface
    fun profiles(): String = JSONArray(ProfileStore.list(ctx)).toString()

    @JavascriptInterface
    fun saveProfile(name: String, acts: String) {
        ProfileStore.save(ctx, name, JSONArray(acts))
    }

    @JavascriptInterface
    fun runProfile(name: String): String {
        val j = ProfileStore.load(ctx, name)
        val acts = j.optJSONArray("acts") ?: return "empty"
        for (i in 0 until acts.length()) {
            val o = acts.getJSONObject(i)
            val pkg = o.getString("pkg")
            if (ProtectedPackages.blocked(pkg)) continue
            when (o.getString("op")) {
                "freeze" -> pm.setEnabled(pkg, false)
                "enable" -> pm.setEnabled(pkg, true)
                "clear" -> pm.clear(pkg)
                "uninstall" -> pm.uninstall(pkg)
            }
        }
        return "ok"
    }
}

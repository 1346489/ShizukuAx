package me.x.shizukuax

import android.annotation.SuppressLint
import android.content.Intent
import android.content.pm.IPackageManager
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder

/**
 * 手写 IPackageManager 代理封装（不依赖 AOSP aidl 编译）。
 *
 * 关键点：
 *  - Shizuku 身份下调用 setApplicationEnabledSetting / deletePackage / clearApplicationUserData
 *    效果等同 `adb shell pm disable-user / pm clear / pm uninstall`，系统应用也可操作。
 *  - 使用反射拿 Transaction 码，避免不同 ROM 的 IPackageManager.aidl 差异。
 */
@SuppressLint("PrivateApi", "DiscouragedPrivateApi")
object PmBridge {

    private val TRANSACTION_SET_APP_ENABLED: Int by lazy {
        // android.content.pm.IPackageManager$Stub.TRANSACTION_setApplicationEnabledSetting
        findTransactionCode(
            "android.content.pm.IPackageManager\$Stub",
            "TRANSACTION_setApplicationEnabledSetting",
            15, // AOSP 历史序号（不同版本会漂移，故优先反射常量）
        )
    }

    private fun findTransactionCode(stubClass: String, field: String, fallback: Int): Int {
        return try {
            val c = Class.forName(stubClass)
            c.getDeclaredField(field).getInt(null)
        } catch (_: Throwable) {
            // 部分 ROM 常量被混淆/内联，回退到 PackageManager 公开常量组合
            fallback
        }
    }

    /* -------------------- 公开业务 API -------------------- */

    /** 启用 / 禁用 / 冻结（冻结 = 禁用） */
    fun setEnabled(pkg: String, state: Int): Boolean {
        val binder = ShizukuGate.packageManagerBinder() ?: return false
        return try {
            // 优先走 Shizuku 包装后的 Stub（类型安全）
            val pm = IPackageManager.Stub.asInterface(binder)
            pm.setApplicationEnabledSetting(pkg, state, 0, 0, null)
            true
        } catch (e: Throwable) {
            // ROM 签名/常量漂移 → 走手写 transact 兜底
            IPackageManagerCompat.setApplicationEnabledSetting(binder, pkg, state)
        }
    }

    /** 清除数据：Android 14+ 需要 CLEAR_APP_USER_DATA 权限，Shizuku uid 0 满足 */
    fun clearData(pkg: String): Boolean {
        val binder = ShizukuGate.packageManagerBinder() ?: return false
        return try {
            val pm = IPackageManager.Stub.asInterface(binder)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                // clearApplicationUserData(packageName, userId, observer)
                val observer = object : android.content.pm.IPackageDataObserver.Stub() {
                    override fun onRemoveCompleted(pkgArg: String?, succeeded: Boolean) {}
                }
                pm.clearApplicationUserData(pkg, 0, observer)
            } else {
                @Suppress("DEPRECATION")
                pm.clearApplicationUserData(pkg, null)
            }
            true
        } catch (_: Throwable) {
            false
        }
    }

    /* -------------------- 查询封装 -------------------- */

    fun getInstalledPackages(flags: Int): List<PackageInfo> {
        val binder = ShizukuGate.packageManagerBinder() ?: return emptyList()
        return try {
            IPackageManagerCompat.getInstalledPackages(binder, flags)
        } catch (e: Throwable) {
            emptyList()
        }
    }
}

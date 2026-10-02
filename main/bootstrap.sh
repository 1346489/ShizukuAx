#!/bin/bash
set -e
echo "==> 生成 ShizukuAx 工程树"

mkdir -p app/src/main/java/me/x/shizukuax
mkdir -p app/src/main/res/layout app/src/main/res/values app/src/main/res/drawable
mkdir -p app/src/main/assets/web
mkdir -p .github/workflows
mkdir -p gradle/wrapper

############ 根文件 ############
cat > settings.gradle.kts <<'K'
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
    repositories { google(); mavenCentral() }
}
rootProject.name = "ShizukuAx"
include(":app")
K

cat > build.gradle.kts <<'K'
plugins {
    id("com.android.application") version "8.2.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}
K

cat > gradle.properties <<'K'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
K

cat > local.properties.example <<'K'
sdk.dir=/path/to/Android/Sdk
K

cat > build-apk.sh <<'K'
#!/usr/bin/env bash
set -e
chmod +x gradlew
./gradlew clean assembleDebug
cp app/build/outputs/apk/debug/app-debug.apk ./AxShizuku-debug.apk
echo "==> AxShizuku-debug.apk ready"
K
chmod +x build-apk.sh

############ app/build.gradle.kts ############
cat > app/build.gradle.kts <<'K'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "me.x.shizukuax"
    compileSdk = 34
    defaultConfig {
        applicationId = "me.x.shizukuax"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
    buildFeatures { viewBinding = true }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
    kotlinOptions { jvmTarget = "17" }
    signingConfigs {
        getByName("debug") { storeFile = file("$rootDir/debug.keystore") }
    }
}

dependencies {
    implementation("dev.rikka.shizuku:api:13.1.5")
    implementation("androidx.webkit:webkit:1.10.0")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.json:json:20231013")
}
K

############ Manifest ############
cat > app/src/main/AndroidManifest.xml <<'K'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"/>
    <uses-permission android:name="android.permission.REQUEST_DELETE_PACKAGES"/>
    <uses-permission android:name="android.permission.CLEAR_APP_USER_DATA"/>
    <application
        android:theme="@style/Theme.AxDark"
        android:label="Ax·Shizuku"
        android:icon="@drawable/ic_launcher"
        android:usesCleartextTraffic="true">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
K

############ Kotlin 源码 ############
cat > app/src/main/java/me/x/shizukuax/AppInfo.kt <<'K'
package me.x.shizukuax
data class AppInfo(
    val pkg: String, val name: String, val enabled: Boolean,
    val system: Boolean, val version: String, val targetSdk: Int,
    val firstInstall: Long, val lastUpdate: Long, val apkPath: String
)
K

cat > app/src/main/java/me/x/shizukuax/ShizukuGate.kt <<'K'
package me.x.shizukuax
import android.os.IBinder
import android.os.ServiceManager
import dev.rikka.shizuku.Shizuku
import rikka.shizuku.ShizukuBinderWrapper

object ShizukuGate {
    var ready = false
    fun ping(): Boolean = runCatching { Shizuku.pingBinder() }.getOrDefault(false)
    fun ensure(): Boolean { ready = ping(); return ready }
    fun packageBinder(): IBinder? {
        if (!ensure()) return null
        return ShizukuBinderWrapper(ServiceManager.getService("package"))
    }
}
K

cat > app/src/main/java/me/x/shizukuax/BackendDetect.kt <<'K'
package me.x.shizukuax
import android.content.Context
enum class Backend { SHIZUKU, ROOT_SU, NONE }
object BackendDetect {
    fun current(ctx: Context): Backend {
        if (ShizukuGate.ensure()) return Backend.SHIZUKU
        if (hasKsu(ctx)) return Backend.ROOT_SU
        if (canSu()) return Backend.ROOT_SU
        return Backend.NONE
    }
    private fun hasKsu(ctx: Context) = runCatching {
        ctx.packageManager.getPackageInfo("me.weishu.kernelsu", 0); true
    }.getOrDefault(false)
    private fun canSu(): Boolean = runCatching {
        val p = Runtime.getRuntime().exec(arrayOf("su","-c","id"))
        p.inputStream.bufferedReader().readText().contains("uid=0")
    }.getOrDefault(false)
    fun name(ctx: Context) = when(current(ctx)){
        Backend.SHIZUKU -> "Shizuku"
        Backend.ROOT_SU -> if(hasKsu(ctx)) "KernelSU" else "Magisk"
        Backend.NONE -> "未连接"
    }
}
K

cat > app/src/main/java/me/x/shizukuax/RootBackend.kt <<'K'
package me.x.shizukuax
object RootBackend {
    private fun su(cmd: String): String = runCatching {
        val p = Runtime.getRuntime().exec(arrayOf("su","-c", cmd))
        val out = p.inputStream.bufferedReader().readText()
        val err = p.errorStream.bufferedReader().readText()
        p.waitFor()
        "$out$err".trim()
    }.getOrDefault("err")
    fun setEnabled(pkg: String, en: Boolean) =
        su("pm ${if(en) "enable $pkg" else "disable-user --user current $pkg"}")
    fun clearData(pkg: String) = su("pm clear --user current $pkg")
    fun uninstall(pkg: String) = su("pm uninstall --user current $pkg")
}
K

cat > app/src/main/java/me/x/shizukuax/IPackageManagerCompat.kt <<'K'
package me.x.shizukuax
import android.os.*
import java.lang.reflect.Field
object IPackageManagerCompat {
    private val TRANS_ENABLE = findTx("setApplicationEnabledSetting", 21)
    private val TRANS_CLEAR = findTx("clearApplicationUserData", 22)
    private fun findTx(name: String, fallback: Int): Int = try {
        val f = Class.forName("android.content.pm.IPackageManager\$Stub")
            .declaredFields.firstOrNull { it.name == "TRANSACTION_$name" }
        f?.getInt(null) ?: fallback
    } catch (_: Exception){ fallback }
    private fun pm(): IBinder = ShizukuGate.packageBinder()
        ?: throw IllegalStateException("no shizuku binder")
    fun setEnabled(pkg: String, en: Boolean) {
        val b = pm(); val data = Parcel.obtain(); val reply = Parcel.obtain()
        try {
            data.writeInterfaceToken("android.content.pm.IPackageManager")
            data.writeString(pkg)
            data.writeInt(if(en) 1 else 2)
            data.writeInt(0)
            data.writeString("me.x.shizukuax")
            b.transact(TRANS_ENABLE, data, reply, 0)
            reply.readException()
        } finally { data.recycle(); reply.recycle() }
    }
    fun clearData(pkg: String) {
        val b = pm(); val data = Parcel.obtain(); val reply = Parcel.obtain()
        try {
            data.writeInterfaceToken("android.content.pm.IPackageManager")
            data.writeString(pkg)
            data.writeStrongBinder(null)
            data.writeInt(0)
            b.transact(TRANS_CLEAR, data, reply, 0)
            reply.readException()
        } finally { data.recycle(); reply.recycle() }
    }
}
K

cat > app/src/main/java/me/x/shizukuax/ProtectedPackages.kt <<'K'
package me.x.shizukuax
object ProtectedPackages {
    private val HARD = setOf(
        "com.android.systemui","com.android.settings",
        "com.android.packageinstaller","com.google.android.packageinstaller",
        "android","android.permission","com.android.permissioncontroller",
        "me.x.shizukuax"
    )
    private val SOFT_PREFIX = listOf(
        "com.android.phone","com.android.mms","com.android.contacts",
        "com.android.dialer","com.google.android.gms","com.google.android.gsf",
        "com.samsung.","com.miui.","com.coloros.","com.heytap.",
        "com.huawei.","com.vivo.","com.oppo."
    )
    fun level(pkg: String): Pair<Int,String> {
        if (HARD.contains(pkg)) return 2 to "系统核心组件，冻结会导致系统崩溃"
        if (SOFT_PREFIX.any { pkg.startsWith(it) }) return 1 to "系统关键服务，操作可能影响通话/账号/框架"
        return 0 to ""
    }
    fun blocked(pkg: String) = level(pkg).first == 2
}
K

cat > app/src/main/java/me/x/shizukuax/PmFacade.kt <<'K'
package me.x.shizukuax
import android.content.Context
class PmFacade(private val ctx: Context) {
    private val act get() = ctx as MainActivity
    fun backend() = BackendDetect.current(ctx)
    fun setEnabled(pkg: String, en: Boolean): String {
        val lvl = ProtectedPackages.level(pkg)
        if (lvl.first == 2) return "blocked:${lvl.second}"
        return when(backend()){
            Backend.SHIZUKU -> runCatching{ IPackageManagerCompat.setEnabled(pkg,en); "ok" }.getOrElse { it.message?:"err" }
            Backend.ROOT_SU -> RootBackend.setEnabled(pkg,en)
            Backend.NONE -> "no-backend"
        }
    }
    fun clearData(pkg: String): String {
        if (ProtectedPackages.blocked(pkg)) return "blocked"
        return when(backend()){
            Backend.SHIZUKU -> runCatching{ IPackageManagerCompat.clearData(pkg); "ok" }.getOrElse { it.message?:"err" }
            Backend.ROOT_SU -> RootBackend.clearData(pkg)
            Backend.NONE -> "no-backend"
        }
    }
    fun uninstall(pkg: String): String {
        if (ProtectedPackages.blocked(pkg)) return "blocked"
        return when(backend()){
            Backend.SHIZUKU -> runCatching{
                act.packageManager.packageInstaller.uninstall(pkg, android.content.IntentSender(null)); "ok"
            }.getOrElse { it.message?:"err" }
            Backend.ROOT_SU -> RootBackend.uninstall(pkg)
            Backend.NONE -> "no-backend"
        }
    }
}
K

cat > app/src/main/java/me/x/shizukuax/Profi

# Ax·Shizuku

仿 AxManager 的 Android 应用管理工具：暗色渐变卡 + 动画 + WebView JS Bridge。
通过 **Shizuku / KernelSU / Magisk** 身份对应用执行：冻结、启用、清除数据、卸载、批量操作、Profile 配置。

## 功能
- 应用列表 / 应用详情抽屉（右滑进入，300ms 动画）
- 冻结 = `pm disable-user`、启用 = `pm enable`、清数据 = `pm clear`、卸载 = `pm uninstall`
- 多选批量操作，受保护包自动跳过
- 防误冻白名单：硬拦截 systemui / settings / 包安装器 / 框架 / 自身；软警告 gms、厂商框架、电话/通讯录
- Profile：新建（自动写入当前已冻结应用）/ 删除 / 一键执行 / 导出
- 后端自动探测：KernelSU / Magisk (su) > Shizuku > 未连接

## 一键出 APK（无电脑也能）
1. 建 GitHub 仓库 `ShizukuAx`
2. 把本工程全部文件推上去（或网页 Add file 逐个粘）
3. 仓库 → **Actions** → 等绿勾（约 5-8 分钟）
4. Artifacts → 下载 `AxShizuku-debug.apk` → 手机安装

> 手机无电脑方案：仓库页按 `.` 进入 **GitHub Codespaces**（网页版 VS Code），终端执行
> `bash gen.sh && gradle wrapper --gradle-version 8.5 && git add . && git commit -m init && git push`
> 回 GitHub 网页 → Actions 即出包。

## 本地编译
```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export ANDROID_HOME=$HOME/Android/Sdk
keytool -genkey -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Ax"
echo "sdk.dir=$ANDROID_HOME" > local.properties
./gradlew assembleDebug
# 产物：app/build/outputs/apk/debug/app-debug.apk
adb install -r app-debug.apk
```

## 注意事项
- **卸载**在 Shizuku 下可能因"非记录中的安装器"被 SELinux 拦截，属 Android 安全模型；
  需无弹窗卸载请用 KernelSU / Magisk 后端（`su -c pm uninstall`）。
- `QUERY_ALL_PACKAGES` 仅用于枚举应用，不赋予写权限；写操作靠 Shizuku / root 身份。
- 勿对 `com.android.systemui` 等点冻结/卸载，白名单已拦截。

## 文件清单
```
.github/workflows/build.yml   CI 自动出 APK
gen.sh                        CI 自举：自动生成全部源码
gradlew + gradle-wrapper.properties
build.gradle.kts / settings.gradle.kts / gradle.properties
app/build.gradle.kts
app/src/main/AndroidManifest.xml
app/src/main/res/...          layout / values / drawable
app/src/main/assets/web/      index.html / detail.html / style.css / app.js
app/src/main/java/me/x/shizukuax/
   MainActivity.kt
   ShizukuGate.kt              Shizuku 绑定 + Binder
   BackendDetect.kt            运行时后端探测
   RootBackend.kt              su -c 'pm ...'
   IPackageManagerCompat.kt    手写 transact 兜底
   ProtectedPackages.kt        防误冻白名单
   PmFacade.kt                 统一门面（选后端 + 过白名单）
   AppBridge.kt                JS Bridge = window.AxNative
   DetailDrawer.kt             右滑抽屉动画
   ProfileStore.kt             Profile JSON
```

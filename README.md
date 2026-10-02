# AxShizuku

仿 AxManager 的 Shizuku / KernelSU / Magisk 应用管理前端（冻结 / 启用 / 清数据 / 卸载 / 多选批量 / Profile / 防误冻白名单）。

## 没电脑也能出 APK（手机网页操作）

1. 手机浏览器开 github.com，建仓库 `ShizukuAx`（Public）。
2. 把本仓库文件按路径上传（或直接 Import）。
3. 仓库 → Actions → 等 5~8 分钟 → 绿勾 → Artifacts 下载 `AxShizuku-debug.apk`。
4. 装到手机 → 给 Shizuku 授权（或 KernelSU 给 root）→ 顶部显示「Shizuku · 已连接」即可用。

## 后端优先级

- Shizuku 已授权 → 走 `IPackageManager` Binder 反射（`pm disable-user` / `pm clear` 级别）
- 否则有 `su` → 走 `KernelSU / Magisk`（`su -c pm ...`），支持无弹窗卸载
- 否则 → 未连接

## 已知限制（Android 安全模型，非 bug）

- 冻结 / 启用：Shizuku 身份稳定生效
- 清数据：需 root / adb 身份，Shizuku uid 0 满足，生效
- 卸载：Shizuku 下 `PackageInstaller.uninstall` 可能被 SELinux 拦（普通 shell 不是"记录中的安装者"），代码已自动降级 `su -c pm uninstall`；若仍失败请改用 KernelSU / Magisk 后端
- `QUERY_ALL_PACKAGES` 仅用于"看到应用"，不赋予写权限

## 白名单（永远禁止写操作，防变砖）

- 硬拦截：systemui / settings / 包安装器 / android 框架 / 本应用自身
- 软提示（需二次确认）：电话、短信、联系人、拨号、GMS、厂商框架

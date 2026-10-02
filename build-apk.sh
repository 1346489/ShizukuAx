#!/usr/bin/env bash
# 本地一键构建 APK（Linux / macOS / WSL / Termux）
# 依赖：JDK 17 (export JAVA_HOME) + Android SDK (export ANDROID_HOME 或 sdkmanager 在 PATH)
set -e

cd "$(dirname "$0")"

echo "==> 1/4 校验工程"
python3 ci-verify.py

echo "==> 2/4 检查 JDK"
java -version 2>&1 | head -n 1
if ! java -version 2>&1 | grep -q '17'; then
  echo "[warn] 推荐 JDK 17，当前非 17 可能编译失败"
fi

echo "==> 3/4 下载 Gradle 依赖并编译"
chmod +x gradlew
./gradlew assembleDebug --no-daemon --stacktrace

echo "==> 4/4 产物"
ls -lh app/build/outputs/apk/debug/app-debug.apk
cp app/build/outputs/apk/debug/app-debug.apk ./AxShizuku-debug.apk
echo "✅ 已生成: $(pwd)/AxShizuku-debug.apk"
echo ""
echo "安装：adb install -r AxShizuku-debug.apk"

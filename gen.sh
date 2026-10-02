#!/usr/bin/env bash
set -e
PKG="me/x/shizukuax"
DIR="app/src/main/java/$PKG"
RES="app/src/main/res"
mkdir -p "$DIR" "$RES/layout" "$RES/values"

# 清理旧业务代码，仅留主类
rm -f "$DIR"/*.kt
touch "$DIR/MainActivity.kt"
cat > "$DIR/MainActivity.kt" <<'EOF'
package me.x.shizukuax
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.widget.TextView
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tv = TextView(this).apply { text = "AxShizuku Debug Build OK" }
        setContentView(tv)
    }
}
EOF

# 占位业务类（防依赖报错，全为空壳）
for f in PmFacade AppBridge DetailDrawer ShizukuService BinderUtil Prefs AppList Loader Uninstaller Installer BridgeJs WebHost; do
cat > "$DIR/$f.kt" <<EOF
package me.x.shizukuax
// stub for $f
object $f
EOF
done

# 资源兜底
echo '<resources><style name="Theme.AppCompat.DayNight.NoActionBar" parent="android:style/Theme.Material.NoActionBar"/></resources>' > "$RES/values/styles.xml"
echo '<?xml version="1.0"?><layout/>' > "$RES/layout/activity_main.xml"
echo '<?xml version="1.0" encoding="utf-8"?><manifest/>' > "$RES/values/strings.xml"

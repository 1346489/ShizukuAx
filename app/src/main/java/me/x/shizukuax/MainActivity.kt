package me.x.shizukuax

import android.os.Bundle
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity
import dev.rikka.shizuku.Shizuku

class MainActivity : AppCompatActivity() {

    private lateinit var drawer: DetailDrawer

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val web = findViewById<WebView>(R.id.web)
        web.settings.javaScriptEnabled = true
        web.settings.allowFileAccess = true
        web.addJavascriptInterface(AppBridge(this), "AxNative")
        web.loadUrl("file:///android_asset/web/index.html")

        val detailWeb = findViewById<WebView>(R.id.detailWeb)
        detailWeb.settings.javaScriptEnabled = true
        detailWeb.addJavascriptInterface(AppBridge(this), "AxNative")

        val scrim = findViewById<android.widget.FrameLayout>(R.id.scrim)
        val panel = findViewById<android.widget.FrameLayout>(R.id.detailPanel)
        drawer = DetailDrawer(scrim, panel)
        scrim.setOnClickListener { drawer.hide() }

        if (!Shizuku.isPreV11()) {
            Shizuku.requestPermission(0)
        }
        Shizuku.addRequestPermissionResultListener { _, result ->
            if (result == Shizuku.PERMISSION_GRANTED) {
                ShizukuGate.ensure()
            }
        }
    }

    override fun onBackPressed() {
        if (drawer.isOpen()) {
            drawer.hide()
        } else {
            super.onBackPressed()
        }
    }
}

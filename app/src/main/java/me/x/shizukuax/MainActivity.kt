package me.x.shizukuax
import android.os.Bundle
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity
import dev.rikka.shizuku.Shizuku
import me.x.shizukuax.databinding.ActivityMainBinding
class MainActivity : AppCompatActivity(){
 private lateinit var b:ActivityMainBinding
 private val dr by lazy { DetailDrawer(b.scrim,b.detailPanel) }
 override fun onCreate(s:Bundle?){super.onCreate(s)
  b=ActivityMainBinding.inflate(layoutInflater);setContentView(b.root)
  if(!Shizuku.isPreV11())Shizuku.requestPermission(0)
  Shizuku.addRequestPermissionResultListener{_,r->if(r==Shizuku.PERMISSION_GRANTED)ShizukuGate.ensure()}
  b.web.settings.javaScriptEnabled=true;b.web.settings.allowFileAccess=true
  b.web.addJavascriptInterface(AppBridge(this),"AxNative")
  b.web.loadUrl("file:///android_asset/web/index.html")
  val dw=findViewById<WebView>(R.id.detailWeb)
  dw.settings.javaScriptEnabled=true
  dw.addJavascriptInterface(AppBridge(this),"AxNative")
  b.scrim.setOnClickListener{dr.hide()}
 }
 override fun onBackPressed(){if(dr.isOpen())dr.hide()else super.onBackPressed()}
}

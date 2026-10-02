package me.x.shizukuax
object RootBackend{
 private fun su(c:String)=runCatching{val p=Runtime.getRuntime().exec(arrayOf("su","-c",c));p.waitFor();(p.inputStream.bufferedReader().readText()+p.errorStream.bufferedReader().readText()).trim()}.getOrDefault("err")
 fun setEnabled(p:String,e:Boolean)=su("pm ${if(e)"enable $p" else "disable-user --user current $p"}")
 fun clear(p:String)=su("pm clear --user current $p")
 fun uninstall(p:String)=su("pm uninstall --user current $p")
}

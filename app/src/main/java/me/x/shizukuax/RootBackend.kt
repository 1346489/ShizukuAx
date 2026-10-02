package me.x.shizukuax

object RootBackend {

    private fun su(cmd: String): String {
        return try {
            val p = Runtime.getRuntime().exec(arrayOf("su", "-c", cmd))
            p.waitFor()
            val out = p.inputStream.bufferedReader().readText()
            val err = p.errorStream.bufferedReader().readText()
            (out + err).trim()
        } catch (e: Exception) {
            "err"
        }
    }

    fun setEnabled(pkg: String, enable: Boolean): String {
        val op = if (enable) "enable $pkg" else "disable-user --user current $pkg"
        return su("pm $op")
    }

    fun clear(pkg: String): String = su("pm clear --user current $pkg")

    fun uninstall(pkg: String): String = su("pm uninstall --user current $pkg")
}

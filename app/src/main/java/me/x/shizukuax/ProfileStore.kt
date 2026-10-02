package me.x.shizukuax

import org.json.JSONArray
import org.json.JSONObject
import java.io.File

object ProfileStore {

    fun dir(c: Context): File {
        val f = c.getExternalFilesDir("profiles")
        if (f != null) f.mkdirs()
        return f ?: File(c.filesDir, "profiles").also { it.mkdirs() }
    }

    fun list(c: Context): List<String> {
        val names = dir(c).list() ?: return emptyList()
        return names.filter { it.endsWith(".json") }.map { it.removeSuffix(".json") }
    }

    fun save(c: Context, name: String, acts: JSONArray) {
        File(dir(c), name + ".json").writeText(
            JSONObject().put("name", name).put("acts", acts).toString(2)
        )
    }

    fun load(c: Context, name: String): JSONObject {
        val f = File(dir(c), name + ".json")
        if (!f.exists()) return JSONObject()
        return JSONObject(f.readText())
    }
}

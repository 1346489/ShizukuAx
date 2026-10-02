package me.x.shizukuax
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
object ProfileStore{
 fun dir(c:Context)=File(c.getExternalFilesDir("profiles")).also{it.mkdirs()}
 fun list(c:Context)=dir(c).list()?.filter{it.endsWith(".json")}?.map{it.removeSuffix(".json")}?:emptyList()
 fun save(c:Context,n:String,acts:JSONArray)=File(dir(c),"$n.json").writeText(JSONObject().put("name",n).put("acts",acts).toString(2))
 fun load(c:Context,n:String):JSONObject{val f=File(dir(c),"$n.json");return if(f.exists())JSONObject(f.readText())else JSONObject()}
 fun delete(c:Context,n:String)=File(dir(c),"$n.json").delete()
}

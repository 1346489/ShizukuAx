package me.x.shizukuax

import android.os.IBinder
import android.os.Parcel

object IPackageManagerCompat {

    private val TE: Int = tx("setApplicationEnabledSetting", 21)
    private val TC: Int = tx("clearApplicationUserData", 22)

    private fun tx(name: String, fallback: Int): Int {
        return try {
            val cls = Class.forName("android.content.pm.IPackageManager\$Stub")
            val fields = cls.declaredFields
            val f = fields.firstOrNull { it.name == "TRANSACTION_" + name }
            f?.getInt(null) ?: fallback
        } catch (e: Exception) {
            fallback
        }
    }

    private fun binder(): IBinder {
        return ShizukuGate.pb() ?: throw IllegalStateException("no shizuku binder")
    }

    fun setEnabled(pkg: String, enable: Boolean) {
        val b = binder()
        val data = Parcel.obtain()
        val reply = Parcel.obtain()
        try {
            data.writeInterfaceToken("android.content.pm.IPackageManager")
            data.writeString(pkg)
            data.writeInt(if (enable) 1 else 2)
            data.writeInt(0)
            data.writeString("me.x.shizukuax")
            b.transact(TE, data, reply, 0)
            reply.readException()
        } finally {
            data.recycle()
            reply.recycle()
        }
    }

    fun clear(pkg: String) {
        val b = binder()
        val data = Parcel.obtain()
        val reply = Parcel.obtain()
        try {
            data.writeInterfaceToken("android.content.pm.IPackageManager")
            data.writeString(pkg)
            data.writeStrongBinder(null)
            data.writeInt(0)
            b.transact(TC, data, reply, 0)
            reply.readException()
        } finally {
            data.recycle()
            reply.recycle()
        }
    }
}

package me.x.shizukuax
import android.os.*
object IPackageManagerCompat{
 private val TE=tx("setApplicationEnabledSetting",21)
 private val TC=tx("clearApplicationUserData",22)
 private fun tx(n:String,f:Int)=try{Class.forName("android.content.pm.IPackageManager\$Stub").declaredFields.firstOrNull{it.name=="TRANSACTION_$n"}?.getInt(null)?:f}catch(_:Exception){f}
 private fun b()=ShizukuGate.pb()?:throw IllegalStateException("no-binder")
 fun setEnabled(p:String,e:Boolean){val d=Parcel.obtain();val r=Parcel.obtain();try{d.writeInterfaceToken("android.content.pm.IPackageManager");d.writeString(p);d.writeInt(if(e)1 else 2);d.writeInt(0);d.writeString("me.x.shizukuax");b().transact(TE,d,r,0);r.readException()}finally{d.recycle();r.recycle()}}
 fun clear(p:String){val d=Parcel.obtain();val r=Parcel.obtain();try{d.writeInterfaceToken("android.content.pm.IPackageManager");d.writeString(p);d.writeStrongBinder(null);d.writeInt(0);b().transact(TC,d,r,0);r.readException()}finally{d.recycle();r.recycle()}}
}

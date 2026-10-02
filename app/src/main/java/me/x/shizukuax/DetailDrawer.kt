package me.x.shizukuax
import android.animation.ValueAnimator
import android.view.View
import android.widget.FrameLayout
class DetailDrawer(private val root:FrameLayout,private val p:View){
 var open=false
 fun show(){open=true;anim(0f);p.visibility=View.VISIBLE;root.alpha=0.5f}
 fun hide(){open=false;anim(p.width.toFloat().coerceAtLeast(1f));root.alpha=1f}
 fun isOpen()=open
 private fun anim(x:Float){ValueAnimator.ofFloat(p.translationX,x).apply{duration=if(x==0f)300 else 260;interpolator=android.view.animation.DecelerateInterpolator();addUpdateListener{p.translationX=it.animatedValue as Float;if(x>0f&&it.animatedFraction==1f)p.visibility=View.GONE};start()}}
}

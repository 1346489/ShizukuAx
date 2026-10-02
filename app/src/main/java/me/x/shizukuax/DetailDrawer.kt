package me.x.shizukuax

import android.animation.ValueAnimator
import android.view.View
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout

class DetailDrawer(private val root: FrameLayout, private val panel: View) {

    private var open = false

    fun show() {
        open = true
        anim(0f)
        panel.visibility = View.VISIBLE
        root.alpha = 0.5f
    }

    fun hide() {
        open = false
        anim(panel.width.toFloat().coerceAtLeast(1f))
        root.alpha = 1f
    }

    fun isOpen(): Boolean = open

    private fun anim(toX: Float) {
        val from = panel.translationX
        val a = ValueAnimator.ofFloat(from, toX)
        a.duration = if (toX == 0f) 300L else 260L
        a.interpolator = DecelerateInterpolator()
        a.addUpdateListener {
            panel.translationX = it.animatedValue as Float
            if (toX > 0f && it.animatedFraction == 1f) {
                panel.visibility = View.GONE
            }
        }
        a.start()
    }
}

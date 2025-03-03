package io.agora.scene.common.util

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.res.Resources
import android.util.DisplayMetrics
import android.util.TypedValue
import android.view.View
import android.view.WindowManager

val Number.dp
    get() = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        this.toFloat(),
        Resources.getSystem().displayMetrics
    )

fun Context.getStatusBarHeight(): Int? {
    val resources = resources
    val resourceId = resources.getIdentifier("status_bar_height", "dimen", "android")
    return if (resourceId > 0) resources.getDimensionPixelSize(resourceId) else null
}

fun Context.copyToClipboard(text: String) {
    val cm: ClipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager ?: return
    cm.setPrimaryClip(ClipData.newPlainText(null, text))
}

/**
 * Gets the distance from a view to each screen edge
 * @return DistanceFromEdges containing distances to top, bottom, left and right edges
 */
@Suppress("DEPRECATION")
fun View.getDistanceFromScreenEdges(): DistanceFromEdges {
    val location = IntArray(2)
    getLocationOnScreen(location)

    val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
        ?: return DistanceFromEdges(0, 0, 0, 0)

    val screenSize = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
        val metrics = windowManager.currentWindowMetrics
        metrics.bounds.run { 
            android.util.Size(right - left, bottom - top)
        }
    } else {
        val metrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(metrics)
        android.util.Size(metrics.widthPixels, metrics.heightPixels)
    }

    return DistanceFromEdges(
        top = location[1],
        left = location[0],
        right = screenSize.width - (location[0] + width),
        bottom = screenSize.height - (location[1] + height)
    )
}

data class DistanceFromEdges(
    val top: Int,
    val left: Int,
    val right: Int,
    val bottom: Int
)
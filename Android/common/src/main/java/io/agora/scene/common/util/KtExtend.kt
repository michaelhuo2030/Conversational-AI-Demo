package io.agora.scene.common.util

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.res.Resources
import android.util.TypedValue

val Number.dp
    get() = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        this.toFloat(),
        Resources.getSystem().displayMetrics
    )

fun Context.copyToClipboard(text: String) {
    val cm: ClipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager ?: return
    cm.setPrimaryClip(ClipData.newPlainText(null, text))
}

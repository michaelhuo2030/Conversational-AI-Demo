package io.agora.scene.common.ui.widget

import android.content.Context
import android.graphics.drawable.Drawable
import android.util.AttributeSet
import android.util.Log
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageButton
import androidx.appcompat.content.res.AppCompatResources
import androidx.core.view.contains
import androidx.core.view.isVisible
import io.agora.scene.common.R
import io.agora.scene.common.databinding.CommonDraggableViewBinding
import io.agora.scene.common.util.dp

class DraggableView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private val TAG = "DraggableView"
    private val binding: CommonDraggableViewBinding
    private var startX = 0f
    private var startY = 0f

    private var onViewClick: (() -> Unit)? = null
    private var touchDownTime: Long = 0
    private val clickInterval = 150

    init {
        val inflater = context.getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
        binding = CommonDraggableViewBinding.inflate(inflater, this, true)
        setupDragAction()
    }

    fun setUserName(name: String, isRemote: Boolean) {
        binding.tvUserName.text = name
        if (isRemote) {
            setUserIcon(null)
            binding.ivUserAudio.isVisible = true
        } else {
            setUserIcon(AppCompatResources.getDrawable(context, R.drawable.common_ic_mic))
            binding.ivUserAudio.isVisible = false
        }
    }

    fun setUserAvatar(isMute: Boolean) {
        val name = binding.tvUserName.text.toString()
        binding.ivUserAvatar.isVisible = isMute
        binding.ivUserAvatar.text = (name.getOrNull(0) ?: "").toString()
    }

    private fun setUserIcon(icon: Drawable?) {
        binding.tvUserName.setCompoundDrawablesWithIntrinsicBounds(icon, null, null, null)
        binding.tvUserName.compoundDrawablePadding = if (icon == null) 0 else 4.dp.toInt()
    }

    fun setSmallType(small: Boolean) {
        binding.ivUserAvatar.visibility = if (small) View.GONE else View.VISIBLE
        binding.llContainer.clipToOutline = small
    }

    val canvasContainer: ViewGroup get() = binding.llContainer
    val switchCamera: ImageButton get() = binding.btnSwitchCamera

    fun canvasContainerAddView(view: View) {
        if (!canvasContainer.contains(view)) {
            if (canvasContainer.childCount > 0) {
                canvasContainer.removeAllViews()
            }
            canvasContainer.addView(view)
        }
        canvasContainer.isVisible = true
    }

    fun setOnViewClick(action: (() -> Unit)?) {
        onViewClick = action
    }

    private fun setupDragAction() {
        setOnTouchListener(object : OnTouchListener {
            override fun onTouch(v: View?, event: MotionEvent): Boolean {
                Log.d(TAG, "draggabel view action $event)")
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        // Record the initial position when pressed
                        startX = event.rawX
                        startY = event.rawY

                        touchDownTime = System.currentTimeMillis()
                        return true
                    }

                    MotionEvent.ACTION_MOVE -> {
                        // Calculate offset
                        val offsetX = event.rawX - startX
                        val offsetY = event.rawY - startY

                        // Get parent view's width and height
                        val parent = parent as ViewGroup
                        val parentWidth = parent.width
                        val parentHeight = parent.height

                        // Get this view's width and height
                        val width = width
                        val height = height

                        // Calculate position after dragging, constrained within parent view
                        val left = (left + offsetX).coerceIn(0f, (parentWidth - width).toFloat())
                        val top = (top + offsetY).coerceIn(0f, (parentHeight - height).toFloat())
                        val right = left + width
                        val bottom = top + height

                        // Move this view to new position
                        layout(left.toInt(), top.toInt(), right.toInt(), bottom.toInt())

                        // Update initial position
                        startX = event.rawX
                        startY = event.rawY
                        return true
                    }

                    MotionEvent.ACTION_UP -> {
                        val currentTime = System.currentTimeMillis()
                        if (currentTime - touchDownTime < clickInterval) {
                            onViewClick?.invoke()
                        }
                        return true
                    }

                    else -> {
                        return false
                    }
                }
                return true
            }
        })
    }
}
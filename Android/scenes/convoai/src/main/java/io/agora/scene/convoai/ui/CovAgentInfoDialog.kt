package io.agora.scene.convoai.ui

import android.app.Dialog
import android.view.Gravity
import android.view.WindowManager
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.content.DialogInterface
import android.graphics.PorterDuff
import android.os.Build
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.animation.Animation
import android.view.animation.AnimationUtils
import androidx.activity.OnBackPressedCallback
import androidx.fragment.app.DialogFragment
import io.agora.scene.common.constant.SSOUserManager
import io.agora.scene.common.ui.CommonDialog
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.LogUploader
import io.agora.scene.common.util.copyToClipboard
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovInfoDialogBinding
import io.agora.scene.convoai.constant.CovAgentManager
import io.agora.scene.convoai.api.CovAgentApiManager
import io.agora.scene.convoai.constant.AgentConnectionState
import io.agora.scene.convoai.rtc.CovRtcManager

class CovAgentInfoDialog : DialogFragment() {
    private var binding: CovInfoDialogBinding? = null
    private var onDismissCallback: (() -> Unit)? = null
    private var onLogout: (() -> Unit)? = null

    companion object {
        fun newInstance(onDismissCallback: () -> Unit, onLogout: () -> Unit): CovAgentInfoDialog {
            return CovAgentInfoDialog().apply {
                this.onDismissCallback = onDismissCallback
                this.onLogout = onLogout
            }
        }
    }

    private var value: Int = -1
    private var connectionState: AgentConnectionState = AgentConnectionState.IDLE

    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
        onDismissCallback?.invoke()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setStyle(STYLE_NO_FRAME, R.style.LeftSideSheetDialog)
    }

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        return super.onCreateDialog(savedInstanceState).apply {
            window?.apply {
                setGravity(Gravity.START)
                setLayout(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.MATCH_PARENT
                )
                
                // 隐藏状态栏和导航栏
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    decorView.windowInsetsController?.apply {
                        hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                        systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                    }
                } else {
                    @Suppress("DEPRECATION")
                    decorView.systemUiVisibility = (
                        View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    )
                }
            }
        }
    }
    
    private var uploadAnimation: Animation? = null
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        uploadAnimation = AnimationUtils.loadAnimation(context, R.anim.cov_rotate_loading)
        
        binding?.apply {
            mtvAgentId.setOnLongClickListener {
                copyToClipboard(mtvAgentId.text.toString())
                return@setOnLongClickListener true
            }
            mtvRoomId.setOnLongClickListener {
                copyToClipboard(mtvRoomId.text.toString())
                return@setOnLongClickListener true
            }
            mtvUidValue.setOnLongClickListener {
                copyToClipboard(mtvUidValue.text.toString())
                return@setOnLongClickListener true
            }
            btnClose.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    dismiss()
                }
            })
            tvUploader.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    updateUploadingStatus(true)
                    //CovRtcManager.generatePredumpFile()
                    tvUploader.postDelayed({
                        //LogUploader.uploadLog(CovAgentApiManager.agentId?:"",CovAgentManager.channelName?:"")
                        updateUploadingStatus(false)
                    }, 5000L)
                }
            })
            tvLogout.setOnClickListener {
                onLogout?.invoke()
            }
            updateView()
        }
    }

    fun updateConnectStatus(connectionState: AgentConnectionState) {
        this.connectionState = connectionState
        updateView()
    }

    private fun updateView() {
        val context = context ?: return
        binding?.apply {
            when (connectionState) {
                AgentConnectionState.IDLE, AgentConnectionState.ERROR -> {
                    mtvRoomStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvRoomStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))

                    mtvAgentStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvAgentStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))

                    mtvAgentId.text = getString(R.string.cov_info_empty)
                    mtvRoomId.text = getString(R.string.cov_info_empty)
                    mtvUidValue.text = getString(R.string.cov_info_empty)
                }

                AgentConnectionState.CONNECTING -> {
                    mtvRoomStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvRoomStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))

                    mtvAgentStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvAgentStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))

                    mtvAgentId.text = getString(R.string.cov_info_empty)
                    mtvRoomId.text = CovAgentManager.channelName
                    mtvUidValue.text = CovAgentManager.uid.toString()
                }

                AgentConnectionState.CONNECTED -> {
                    mtvRoomStatus.text = getString(R.string.cov_info_agent_connected)
                    mtvRoomStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_green6))

                    mtvAgentStatus.text = getString(R.string.cov_info_agent_connected)
                    mtvAgentStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_green6))

                    mtvAgentId.text = CovAgentApiManager.agentId ?: getString(R.string.cov_info_empty)
                    mtvRoomId.text = CovAgentManager.channelName
                    mtvUidValue.text = CovAgentManager.uid.toString()
                }

                AgentConnectionState.CONNECTED_INTERRUPT -> {
                    mtvRoomStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvRoomStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))

                    mtvAgentStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvAgentStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))

                    mtvAgentId.text = CovAgentApiManager.agentId ?: getString(R.string.cov_info_empty)
                    mtvRoomId.text = CovAgentManager.channelName
                    mtvUidValue.text = CovAgentManager.uid.toString()
                }
            }
            updateNetworkStatus(value)
        }
    }

    private fun updateUploadingStatus(isUploading: Boolean) {
        context ?: return
        binding?.apply {
            if (isUploading) {
                tvUploader.startAnimation(uploadAnimation)
                tvUploader.setColorFilter(requireContext().getColor(io.agora.scene.common.R.color.ai_icontext3), PorterDuff.Mode.SRC_IN)
                tvUploader.isEnabled = false
                btnClose.setColorFilter(requireContext().getColor(io.agora.scene.common.R.color.ai_icontext3), PorterDuff.Mode.SRC_IN)
                btnClose.isEnabled = false
                // 禁用返回键
                dialog?.setCancelable(false)
            } else {
                tvUploader.clearAnimation()
                tvUploader.setColorFilter(requireContext().getColor(io.agora.scene.common.R.color.ai_icontext1), PorterDuff.Mode.SRC_IN)
                tvUploader.isEnabled = true
                btnClose.setColorFilter(requireContext().getColor(io.agora.scene.common.R.color.ai_icontext1), PorterDuff.Mode.SRC_IN)
                btnClose.isEnabled = true
                // 恢复返回键
                dialog?.setCancelable(true)
            }
        }
    }

    fun updateNetworkStatus(value: Int) {
        this.value = value
//        val context = context ?: return
//        binding?.apply {
//            when (value) {
//                -1 -> {
//                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_disconnected)
//                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))
//                }
//
//                Constants.QUALITY_VBAD, Constants.QUALITY_DOWN -> {
//                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_poor)
//                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))
//                }
//
//                Constants.QUALITY_POOR, Constants.QUALITY_BAD -> {
//                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_medium)
//                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_yellow6))
//                }
//
//                else -> {
//                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_good)
//                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_green6))
//                }
//            }
//        }
    }

    private fun copyToClipboard(text: String) {
        context?.apply {
            copyToClipboard(text)
            ToastUtil.show(getString(R.string.cov_copy_succeed))
        }
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        binding = CovInfoDialogBinding.inflate(inflater, container, false)
        activity?.onBackPressedDispatcher?.addCallback(viewLifecycleOwner, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                //onHandleOnBackPressed()
            }
        })
        return binding?.root
    }

    // 删除 getViewBinding 方法，因为我们直接在 onCreateView 中处理了 ViewBinding

    override fun onDestroyView() {
        super.onDestroyView()
        binding = null
    }

}
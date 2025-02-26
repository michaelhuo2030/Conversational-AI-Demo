package io.agora.scene.convoai.ui

import android.app.Dialog
import android.view.Gravity
import android.view.WindowManager
import android.content.DialogInterface
import android.graphics.PorterDuff
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.animation.Animation
import android.view.animation.AnimationUtils
import io.agora.scene.common.ui.BaseDialogFragment
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

class CovAgentInfoDialog : BaseDialogFragment<CovInfoDialogBinding>() {
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
            }
        }
    }
    
    private var uploadAnimation: Animation? = null
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        uploadAnimation = AnimationUtils.loadAnimation(context, R.anim.cov_rotate_loading)
        
        mBinding?.apply {
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
            layoutUploader.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    updateUploadingStatus(true)
                    CovRtcManager.generatePredumpFile()
                    tvUploader.postDelayed({
                        LogUploader.uploadLog(CovAgentApiManager.agentId ?: "",CovAgentManager.channelName) { err ->
                            if (err == null) {
                                ToastUtil.show(getString(io.agora.scene.common.R.string.common_upload_time_success))
                            } else {
                                ToastUtil.show(getString(io.agora.scene.common.R.string.common_upload_time_failed))
                            }
                            updateUploadingStatus(false)
                        }
                    }, 5000L)
                }
            })
            layoutLogout.setOnClickListener {
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
        mBinding?.apply {
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
        }
    }

    private fun updateUploadingStatus(isUploading: Boolean) {
        context ?: return
        mBinding?.apply {
            if (isUploading) {
                tvLogout.isEnabled = false
                tvLogout.setColorFilter(requireContext().getColor(io.agora.scene.common.R.color.ai_icontext3), PorterDuff.Mode.SRC_IN)
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
                tvLogout.setColorFilter(requireContext().getColor(io.agora.scene.common.R.color.ai_icontext1), PorterDuff.Mode.SRC_IN)
                tvLogout.isEnabled = true
                // 恢复返回键
                dialog?.setCancelable(true)
            }
        }
    }

    private fun copyToClipboard(text: String) {
        context?.apply {
            copyToClipboard(text)
            ToastUtil.show(getString(R.string.cov_copy_succeed))
        }
    }

    override fun getViewBinding(inflater: LayoutInflater, container: ViewGroup?): CovInfoDialogBinding? {
        return CovInfoDialogBinding.inflate(inflater, container, false)
    }

    override fun onHandleOnBackPressed() {
//        super.onHandleOnBackPressed()
    }

    override fun onDestroyView() {
        super.onDestroyView()
//        binding = null
    }

}
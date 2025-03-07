package io.agora.scene.convoai.iot.ui.dialog

import android.content.Context
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.RadioButton
import android.widget.TextView
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.common.ui.CommonDialog
import io.agora.scene.common.ui.LoadingDialog
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.ui.widget.LastItemDividerDecoration
import io.agora.scene.common.util.dp
import io.agora.scene.common.util.getDistanceFromScreenEdges
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovIotDeviceSettingsDialogBinding
import io.agora.scene.convoai.databinding.CovSettingOptionItemBinding
import io.agora.scene.convoai.iot.api.CovIotApiManager
import io.agora.scene.convoai.iot.manager.CovIotPresetManager
import io.agora.scene.convoai.iot.model.CovIotDevice

class CovIotDeviceSettingsDialog : BaseSheetDialog<CovIotDeviceSettingsDialogBinding>() {

    private var onDismissCallback: (() -> Unit)? = null
    private var onDeleteCallback: (() -> Unit)? = null
    private var onResetCallback: (() -> Unit)? = null
    private var onSaveCallback: ((CovIotDevice) -> Unit)? = null
    private var device: CovIotDevice? = null
    private var context: Context? = null
    
    // 添加初始状态记录
    private var initialLanguage: String? = null
    private var initialAiVad: Boolean = false
    private var initialPreset: String? = null

    // 预设适配器
    private lateinit var presetAdapter: PresetAdapter
    private var presetList = mutableListOf<PresetItem>()
    private var selectedPresetPosition = 0
    private var mLoadingDialog: LoadingDialog? = null

    companion object {
        private const val TAG = "IotDeviceSettingsDialog"

        fun newInstance(
            device: CovIotDevice,
            onDismiss: () -> Unit,
            onDelete: () -> Unit,
            onReset: () -> Unit,
            onSave: (CovIotDevice) -> Unit
        ): CovIotDeviceSettingsDialog {
            return CovIotDeviceSettingsDialog().apply {
                this.device = device
                this.onDismissCallback = onDismiss
                this.onDeleteCallback = onDelete
                this.onResetCallback = onReset
                this.onSaveCallback = onSave
            }
        }
    }

    private val optionsAdapter = OptionsAdapter()

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): CovIotDeviceSettingsDialogBinding {
        return CovIotDeviceSettingsDialogBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // 记录初始状态
        device?.let { device ->
            // 如果设备值为空，则使用默认值
            initialLanguage = device.currentLanguage.takeIf { !it.isNullOrEmpty() } ?: getDefaultLanguage()
            initialAiVad = device.enableAIVAD
            initialPreset = device.currentPreset.takeIf { !it.isNullOrEmpty() } ?: getDefaultPreset()
        }

        // 设置点击外部区域关闭对话框
        dialog?.setCanceledOnTouchOutside(false)
        
        binding?.apply {
            setOnApplyWindowInsets(root)
            rcOptions.adapter = optionsAdapter
            rcOptions.layoutManager = LinearLayoutManager(context)
            rcOptions.context.getDrawable(io.agora.scene.common.R.drawable.shape_divider_line)?.let {
                rcOptions.addItemDecoration(LastItemDividerDecoration(it))
            }

            // 初始化预设列表
            initPresetList()
            
            // 设置预设RecyclerView
            rvPreset.layoutManager = LinearLayoutManager(context)
            presetAdapter = PresetAdapter(presetList, selectedPresetPosition) { position ->
                // 处理预设选择
                selectedPresetPosition = position
            }
            rvPreset.adapter = presetAdapter

            // 语言选项点击事件
            clLanguage.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onClickLanguage()
                }
            })

            // 遮罩层点击事件
            vOptionsMask.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onClickMaskView()
                }
            })

            // 优雅打断开关
            cbAiVad.isChecked = initialAiVad

            mLoadingDialog = LoadingDialog(this.root.context)
            mLoadingDialog?.setProgressBarColor(io.agora.scene.common.R.color.ai_click)

            // 关闭按钮
            btnClose.setOnClickListener {
                // 检查是否需要保存设置
                if (hasSettingsChanged()) {
                    showSaveConfirmDialog(
                        onSave = {
                            // 点击确认时，从UI读取当前状态并创建新的CovIotDevice对象
                            device?.let { dev ->
                                binding?.let { binding ->
                                    // 创建新的CovIotDevice对象
                                    val languageText = binding.tvLanguageDetail.text.toString()
                                    val selectedPreset = presetList[selectedPresetPosition]
                                    val newDevice = CovIotDevice(
                                        dev.id,
                                        dev.name,
                                        dev.bleDevice,
                                        currentPreset = selectedPreset.id,
                                        currentLanguage = languageText,
                                        enableAIVAD = binding.cbAiVad.isChecked,
                                    )

                                    mLoadingDialog?.show()
                                    CovIotApiManager.updateSettings(
                                        deviceId = newDevice.bleDevice.address,
                                        presetName = newDevice.currentPreset,
                                        asrLanguage = newDevice.currentLanguage,
                                        enableAivad = newDevice.enableAIVAD
                                    ) { e ->
                                        if (e == null) {
                                            // 调用回调保存新设备
                                            onSaveCallback?.invoke(newDevice)
                                        } else {
                                            // TODO 保存失败
                                            ToastUtil.show("设备信息更新失败, 请重试")
                                        }
                                        mLoadingDialog?.dismiss()
                                    }
                                }
                            }
                            dismiss()
                        },
                        onCancel = {
                            // 点击取消时，恢复UI到初始状态
                            restoreInitialSettings()
                            onDismissCallback?.invoke()
                            dismiss()
                        }
                    )
                } else {
                    onDismissCallback?.invoke()
                    dismiss()
                }
            }

            // 重新配网按钮
            btnReset.setOnClickListener {
                onResetCallback?.invoke()
                dismiss()
            }

            // 删除设备按钮
            btnDelete.setOnClickListener {
                showDeleteConfirmDialog(device?.name ?: "") {
                    onDeleteCallback?.invoke()
                    dismiss()
                }
            }
        }

        updateBaseSettings()
    }

    override fun disableDragging(): Boolean {
        return true
    }

    private fun updateBaseSettings() {
        binding?.apply {
            tvLanguageDetail.text = initialLanguage
        }
    }

    private fun initPresetList() {
        // 清空列表
        presetList.clear()
        
        // 从CovIotPresetManager获取预设列表
        val presets = CovIotPresetManager.getPresetList()
        
        // 添加所有预设到列表
        presets?.forEach { preset ->
            presetList.add(
                PresetItem(
                    preset.preset_name,
                    preset.display_name,
                    preset.preset_brief
                )
            )
        }
        
        // 设置初始选中位置
        selectedPresetPosition = presets?.indexOfFirst { it.preset_name == initialPreset }.takeIf { it != null && it >= 0 } ?: 0
    }

    private fun onClickLanguage() {
        // 获取当前选中预设的语言列表
        val currentPreset = presetList.getOrNull(selectedPresetPosition)?.id ?: return
        val languages = CovIotPresetManager.getPresetLanguages(currentPreset) ?: return
        
        binding?.apply {
            vOptionsMask.visibility = View.VISIBLE

            // 计算弹出位置
            val itemDistances = clLanguage.getDistanceFromScreenEdges()
            val maskDistances = vOptionsMask.getDistanceFromScreenEdges()
            val targetY = itemDistances.top - maskDistances.top + 30.dp
            cvOptions.x = vOptionsMask.width - 250.dp
            cvOptions.y = targetY

            // 计算高度约束
            val params = cvOptions.layoutParams
            val itemHeight = 56.dp.toInt()
            val finalMaxHeight = itemDistances.bottom.coerceAtLeast(itemHeight)
            val finalHeight = (itemHeight * languages.size).coerceIn(itemHeight, finalMaxHeight)

            params.height = finalHeight
            cvOptions.layoutParams = params

            // 更新选项并处理选择
            optionsAdapter.updateOptions(
                languages.map { it.name }.toTypedArray(),
                languages.indexOfFirst { it.name == tvLanguageDetail.text.toString() }.takeIf { it >= 0 } ?: 0
            ) { index ->
                // 更新语言显示
                tvLanguageDetail.text = languages[index].name
                vOptionsMask.visibility = View.INVISIBLE
            }
        }
    }

    private fun onClickMaskView() {
        binding?.apply {
            vOptionsMask.visibility = View.INVISIBLE
        }
    }

    // 修改检查设置是否有变更的方法
    private fun hasSettingsChanged(): Boolean {
        // 比较当前UI设置与初始设置是否有变化
        binding?.let {
            // 从UI读取当前状态
            val currentAiVad = it.cbAiVad.isChecked
            val selectedPreset = presetList[selectedPresetPosition].id
            
            // 检查语言是否变更 (通过UI文本比较)
            val currentLanguageText = it.tvLanguageDetail.text.toString()
            val languageChanged = initialLanguage != currentLanguageText
            
            return currentAiVad != initialAiVad || 
                   languageChanged || 
                   selectedPreset != initialPreset
        }
        
        return false
    }
    
    // 添加恢复初始设置的方法
    private fun restoreInitialSettings() {
        // 恢复预设选择
        selectedPresetPosition = if (initialPreset?.contains("故事") == true) 0 else 1
        presetAdapter.updateSelectedPosition(selectedPresetPosition)
        
        // 更新UI
        binding?.apply {
            // 恢复AI VAD开关状态
            cbAiVad.isChecked = initialAiVad
            
            // 恢复语言显示
            tvLanguageDetail.text = initialLanguage
        }
    }

    private fun showDeleteConfirmDialog(deviceName: String, onDelete: () -> Unit) {
        CommonDialog.Builder()
            .setTitle(getString(R.string.cov_iot_devices_setting_delete, deviceName))
            .setContent(getString(R.string.cov_iot_devices_setting_delete_content))
            .setPositiveButton(getString(R.string.cov_iot_devices_setting_delete_confirm), {
                onDelete.invoke()
            })
            .setNegativeButton(getString(io.agora.scene.common.R.string.common_logout_confirm_cancel))
            .hideTopImage()
            .build()
            .show(parentFragmentManager, "delete_dialog_tag")
    }

    private fun showSaveConfirmDialog(onSave: () -> Unit, onCancel: () -> Unit) {
        CommonDialog.Builder()
            .setTitle(getString(R.string.cov_iot_devices_setting_confirm_title))
            .setContent(getString(R.string.cov_iot_devices_setting_confirm_content))
            .setPositiveButton(getString(R.string.cov_iot_devices_setting_confirm), {
                onSave.invoke()
            })
            .setNegativeButton(getString(R.string.cov_iot_devices_setting_cancel), {
                onCancel.invoke()
            })
            .hideTopImage()
            .build()
            .show(parentFragmentManager, "save_dialog_tag")
    }

    // 预设适配器
    inner class PresetAdapter(
        private val presets: List<PresetItem>,
        private var selectedPosition: Int = 0,
        private val onPresetSelected: (Int) -> Unit
    ) : RecyclerView.Adapter<PresetAdapter.PresetViewHolder>() {

        inner class PresetViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
            val radioButton: RadioButton = itemView.findViewById(R.id.rb_preset)
            val titleTextView: TextView = itemView.findViewById(R.id.tv_preset_title)
            val descTextView: TextView = itemView.findViewById(R.id.tv_preset_desc)
            val divider: View = itemView.findViewById(R.id.view_divider)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): PresetViewHolder {
            val view = LayoutInflater.from(parent.context)
                .inflate(R.layout.cov_iot_preset_item, parent, false)
            return PresetViewHolder(view)
        }

        override fun onBindViewHolder(holder: PresetViewHolder, position: Int) {
            val preset = presets[position]
            
            holder.titleTextView.text = preset.title
            holder.descTextView.text = preset.description
            holder.radioButton.isChecked = position == selectedPosition
            
            // 显示分隔线，除了最后一项
            holder.divider.visibility = if (position < presets.size - 1) View.VISIBLE else View.GONE
            
            // 设置点击事件
            holder.itemView.setOnClickListener {
                updateSelection(position)
            }
            
            holder.radioButton.setOnClickListener {
                updateSelection(position)
            }
        }
        
        private fun updateSelection(position: Int) {
            if (selectedPosition != position) {
                val oldPosition = selectedPosition
                selectedPosition = position
                
                // 只更新变化的项，避免整个列表闪烁
                notifyItemChanged(oldPosition, "selection_changed")
                notifyItemChanged(position, "selection_changed")
                
                // 更新语言选项
                val currentPreset = presets[position].id
                val languages = CovIotPresetManager.getPresetLanguages(currentPreset)
                
                // 查找该预设的默认语言（isDefault为true的语言）
                val defaultLanguage = languages?.find { it.default }
                if (defaultLanguage != null) {
                    binding?.tvLanguageDetail?.text = defaultLanguage.name
                } else if (languages?.isNotEmpty() == true) {
                    // 如果没有默认语言，则使用第一个
                    binding?.tvLanguageDetail?.text = languages[0].name
                }
                
                onPresetSelected(position)
            }
        }

        override fun onBindViewHolder(holder: PresetViewHolder, position: Int, payloads: List<Any>) {
            if (payloads.isEmpty() || payloads[0] != "selection_changed") {
                super.onBindViewHolder(holder, position, payloads)
            } else {
                // 只更新选择状态，避免整个项目重绘
                holder.radioButton.isChecked = position == selectedPosition
            }
        }

        override fun getItemCount() = presets.size
        
        fun updateSelectedPosition(position: Int) {
            if (position != selectedPosition && position in presets.indices) {
                val oldPosition = selectedPosition
                selectedPosition = position
                notifyItemChanged(oldPosition, "selection_changed")
                notifyItemChanged(position, "selection_changed")
            }
        }
    }

    inner class OptionsAdapter : RecyclerView.Adapter<OptionsAdapter.ViewHolder>() {

        private var options: Array<String> = emptyArray()
        private var listener: ((Int) -> Unit)? = null
        private var selectedIndex: Int? = null

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
            return ViewHolder(CovSettingOptionItemBinding.inflate(LayoutInflater.from(parent.context), parent, false))
        }

        override fun onBindViewHolder(holder: ViewHolder, position: Int) {
            holder.bind(options[position], (position == selectedIndex))
            holder.itemView.setOnClickListener {
                listener?.invoke(position)
            }
        }

        override fun getItemCount(): Int {
            return options.size
        }

        fun updateOptions(newOptions: Array<String>, selected: Int, newListener: (Int) -> Unit) {
            options = newOptions
            listener = newListener
            selectedIndex = selected
            notifyDataSetChanged()
        }

        inner class ViewHolder(private val binding: CovSettingOptionItemBinding) :
            RecyclerView.ViewHolder(binding.root) {
            fun bind(option: String, selected: Boolean) {
                binding.tvText.text = option
                binding.ivIcon.visibility = if (selected) View.VISIBLE else View.INVISIBLE
            }
        }
    }

    // 获取默认语言
    private fun getDefaultLanguage(): String {
        // 获取默认预设
        val defaultPreset = getDefaultPreset()
        // 获取该预设的语言列表
        val languages = CovIotPresetManager.getPresetLanguages(defaultPreset)
        // 返回默认语言或第一个语言
        return languages?.find { it.default }?.name ?: languages?.firstOrNull()?.name ?: "中文"
    }

    // 获取默认预设
    private fun getDefaultPreset(): String {
        // 从预设管理器获取预设列表
        val presets = CovIotPresetManager.getPresetList()
        // 返回第一个预设的ID，如果列表为空则返回空字符串
        return presets?.firstOrNull()?.preset_name ?: ""
    }
}

// 预设项数据类
data class PresetItem(
    val id: String,
    val title: String,
    val description: String
)
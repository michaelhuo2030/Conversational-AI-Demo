package io.agora.scene.convoai.iot.adapter

import android.app.AlertDialog
import android.text.InputType
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.convoai.databinding.CovIotDeviceItemBinding
import io.agora.scene.convoai.iot.model.CovIotDevice

class IotDeviceAdapter(private val devices: List<CovIotDevice>) :
    RecyclerView.Adapter<IotDeviceAdapter.DeviceViewHolder>() {
    
    private var listener: OnItemClickListener? = null
    
    interface OnItemClickListener {
        fun onItemSettingClick(device: CovIotDevice, position: Int)
        fun onNameChanged(device: CovIotDevice, newName: String, position: Int)
    }
    
    fun setOnItemClickListener(listener: OnItemClickListener) {
        this.listener = listener
    }
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): DeviceViewHolder {
        val binding = CovIotDeviceItemBinding.inflate(
            LayoutInflater.from(parent.context), 
            parent, 
            false
        )
        // 在创建ViewHolder时就根据viewType设置背景
        val backgroundResId = if (viewType == 0) {
            parent.context.resources.getIdentifier("cov_iot_device_item_bg_2", "drawable", parent.context.packageName)
        } else {
            parent.context.resources.getIdentifier("cov_iot_device_item_bg", "drawable", parent.context.packageName)
        }
        binding.clIotItem.setBackgroundResource(backgroundResId)
        
        return DeviceViewHolder(binding)
    }
    
    override fun onBindViewHolder(holder: DeviceViewHolder, position: Int) {
        val device = devices[position]
        holder.bind(device, position)
    }
    
    override fun getItemCount(): Int = devices.size
    
    override fun getItemViewType(position: Int): Int {
        return position % 2
    }
    
    inner class DeviceViewHolder(private val binding: CovIotDeviceItemBinding) : 
        RecyclerView.ViewHolder(binding.root) {
        
        fun bind(device: CovIotDevice, position: Int) {
            binding.apply {
                // 设置设备名称为TextView显示
                tvDeviceName.text = device.name
                
                // 设置名称点击事件，弹出对话框编辑
                tvDeviceName.setOnClickListener {
                    showEditNameDialog(device, adapterPosition)
                }
                
                // 设置SN和序列号
                tvSnLabel.text = "SN"
                tvSerialNumber.text = device.id

                // 设置设置按钮点击事件
                cvDeviceSettings.setOnClickListener {
                    listener?.onItemSettingClick(device, adapterPosition)
                }
            }
        }
        
        private fun showEditNameDialog(device: CovIotDevice, position: Int) {
            val context = itemView.context
            val input = EditText(context)
            input.inputType = InputType.TYPE_CLASS_TEXT
            input.setText(device.name)
            input.setSelection(input.text.length)
            
            AlertDialog.Builder(context)
                .setTitle("编辑设备名称")
                .setView(input)
                .setPositiveButton("确定") { dialog, which ->
                    val newName = input.text.toString().trim()
                    if (newName.isNotEmpty() && newName != device.name) {
                        listener?.onNameChanged(device, newName, position)
                    }
                }
                .setNegativeButton("取消") { dialog, which -> dialog.cancel() }
                .show()
        }
    }
}
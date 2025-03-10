package io.agora.scene.convoai.iot.adapter

import android.app.AlertDialog
import android.text.InputFilter
import android.text.InputType
import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.EditText
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovIotDeviceItemBinding
import io.agora.scene.convoai.iot.model.CovIotDevice

class CovIotDeviceListAdapter(private val devices: List<CovIotDevice>) :
    RecyclerView.Adapter<CovIotDeviceListAdapter.DeviceViewHolder>() {
    
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
        val backgroundResId = if (viewType == 0) {
            R.drawable.cov_iot_device_item_bg_2
        } else {
            R.drawable.cov_iot_device_item_bg
        }
        binding.clIotItem.setBackgroundResource(backgroundResId)
        
        return DeviceViewHolder(binding)
    }
    
    override fun onBindViewHolder(holder: DeviceViewHolder, position: Int) {
        val device = devices[position]
        holder.bind(device)
    }
    
    override fun getItemCount(): Int = devices.size
    
    override fun getItemViewType(position: Int): Int {
        return position % 2
    }
    
    inner class DeviceViewHolder(private val binding: CovIotDeviceItemBinding) : 
        RecyclerView.ViewHolder(binding.root) {
        
        fun bind(device: CovIotDevice) {
            binding.apply {
                tvDeviceName.text = device.name
                
                tvDeviceName.setOnClickListener {
                    showEditNameDialog(device, adapterPosition)
                }

                tvSerialNumber.text = device.id

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
            
            // set input limit: max 10 characters and not empty
            input.filters = arrayOf(InputFilter.LengthFilter(10))
            
            AlertDialog.Builder(context)
                .setTitle(R.string.cov_iot_devices_setting_modify_name)
                .setView(input)
                .setPositiveButton(R.string.cov_iot_devices_setting_modify_name_confirm) { _, _ ->
                    val newName = input.text.toString().trim()
                    if (newName.isNotEmpty() && newName != device.name) {
                        listener?.onNameChanged(device, newName, position)
                    }
                }
                .setNegativeButton(R.string.cov_iot_devices_setting_modify_name_cancel) { dialog, _ -> dialog.cancel() }
                .show()
        }
    }
}
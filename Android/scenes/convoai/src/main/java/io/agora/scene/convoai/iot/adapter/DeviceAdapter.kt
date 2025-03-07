package io.agora.scene.convoai.iot.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.convoai.databinding.CovItemDeviceBinding
import io.iot.dn.ble.model.BleDevice

class DeviceAdapter(
    private val devices: List<BleDevice>,
    private val onItemClick: (BleDevice) -> Unit
) : RecyclerView.Adapter<DeviceAdapter.DeviceViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): DeviceViewHolder {
        val binding = CovItemDeviceBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return DeviceViewHolder(binding)
    }

    override fun onBindViewHolder(holder: DeviceViewHolder, position: Int) {
        val device = devices[position]
        holder.bind(device)
    }

    override fun getItemCount(): Int = devices.size

    inner class DeviceViewHolder(private val binding: CovItemDeviceBinding) :
        RecyclerView.ViewHolder(binding.root) {

        init {
            binding.root.setOnClickListener {
                // 点击时改变背景颜色
                binding.root.setCardBackgroundColor(ContextCompat.getColor(binding.root.context, io.agora.scene.common.R.color.ai_click_app))
                
                // 200毫秒后恢复原来的颜色
                binding.root.postDelayed({
                    binding.root.setCardBackgroundColor(ContextCompat.getColor(binding.root.context, io.agora.scene.common.R.color.ai_fill1))
                }, 200)
                
                val position = adapterPosition
                if (position != RecyclerView.NO_POSITION) {
                    onItemClick(devices[position])
                }
            }
        }

        fun bind(device: BleDevice) {
            binding.apply {
                tvDeviceName.text = device.name
            }
        }
    }
} 
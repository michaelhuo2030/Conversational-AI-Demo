package io.agora.scene.convoai.iot.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.convoai.R
import io.agora.scene.convoai.iot.model.DeviceImage

class DeviceImageAdapter(private val images: List<DeviceImage>) : 
    RecyclerView.Adapter<DeviceImageAdapter.ImageViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ImageViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.cov_item_device_image, parent, false)
        return ImageViewHolder(view)
    }

    override fun onBindViewHolder(holder: ImageViewHolder, position: Int) {
        val deviceImage = images[position]
        holder.imageView.setImageResource(deviceImage.resourceId)
        holder.imageView.contentDescription = deviceImage.description
    }

    override fun getItemCount(): Int = images.size

    class ImageViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val imageView: ImageView = itemView.findViewById(R.id.iv_device_image)
    }
} 
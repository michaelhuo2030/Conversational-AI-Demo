package io.agora.scene.convoai.iot.ui

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import androidx.recyclerview.widget.LinearLayoutManager
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.dp
import io.agora.scene.common.util.getStatusBarHeight
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.iot.adapter.IotDeviceAdapter
import io.agora.scene.convoai.databinding.CovActivityIotDeviceListBinding
import io.agora.scene.convoai.iot.model.CovIotDevice
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import io.agora.scene.convoai.iot.manager.CovIotDeviceManager
import io.agora.scene.convoai.iot.ui.dialog.CovIotDeviceSettingsDialog

class CovIotDeviceListActivity : BaseActivity<CovActivityIotDeviceListBinding>() {

    companion object {
        private const val TAG = "CovIotDeviceListActivity"

        fun startActivity(activity: BaseActivity<*>) {
            val intent = Intent(activity, CovIotDeviceListActivity::class.java)
            activity.startActivity(intent)
        }
    }
    
    // 创建协程作用域用于异步操作
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    // 设备列表适配器
    private lateinit var deviceAdapter: IotDeviceAdapter
    
    // 模拟的设备列表数据
    private val deviceList = mutableListOf<CovIotDevice>()
    
    // 设备管理器
    private lateinit var deviceManager: CovIotDeviceManager

    override fun getViewBinding(): CovActivityIotDeviceListBinding {
        return CovActivityIotDeviceListBinding.inflate(layoutInflater)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 初始化设备管理器
        deviceManager = CovIotDeviceManager.getInstance(this)
        initData()
    }

    override fun initView() {
        setupView()
        setupRecyclerView()
        setupEmptyView()
    }

    override fun onDestroy() {
        coroutineScope.cancel()
        super.onDestroy()
    }

    override fun onResume() {
        super.onResume()
        // 在Activity恢复时重新加载设备列表
        coroutineScope.launch {
            loadDevicesFromLocal()
            updateEmptyState()
        }
    }

    private fun setupView() {
        mBinding?.apply {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            val statusBarHeight = getStatusBarHeight() ?: 25.dp.toInt()
            CovLogger.d(TAG, "statusBarHeight $statusBarHeight")
            val layoutParams = clTitleBar.layoutParams as ViewGroup.MarginLayoutParams
            layoutParams.topMargin = statusBarHeight
            clTitleBar.layoutParams = layoutParams

            // 设置返回按钮点击事件
            ivBack.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    finish()
                }
            })
            
            // 设置添加设备按钮点击事件
            ivAdd.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    CovIotDeviceSetupActivity.startActivity(this@CovIotDeviceListActivity)
                }
            })
        }
    }
    
    private fun setupEmptyView() {
        mBinding?.apply {
            // 设置空状态视图中的添加设备按钮点击事件
            btnAddDevice.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    CovIotDeviceSetupActivity.startActivity(this@CovIotDeviceListActivity)
                }
            })
        }
        
        // 根据设备列表状态更新UI
        updateEmptyState()
    }

    private fun setupRecyclerView() {
        deviceAdapter = IotDeviceAdapter(deviceList)
        deviceAdapter.setOnItemClickListener(object : IotDeviceAdapter.OnItemClickListener {
            override fun onItemSettingClick(device: CovIotDevice, position: Int) {
                // 这里可以跳转到设备详情页面
                val dialog = CovIotDeviceSettingsDialog.newInstance(
                    device = device,
                    onDismiss = {
                        // 对话框关闭回调
                    },
                    onDelete = {
                        removeDevice(device, position)
                    },
                    onReset = {
                        // 重新配网回调
                        CovIotDeviceSetupActivity.startActivity(this@CovIotDeviceListActivity)
                    },
                    onSave = { device ->
                        // 保存新名称回调
                        val index = deviceList.indexOfFirst { it.id == device.id }
                        if (index != -1) {
                            deviceList[index] = device
                            deviceAdapter.notifyItemChanged(index)
                            
                            // 保存到本地
                            saveDevicesToLocal()
                            
                            ToastUtil.show("设备信息已更新")
                            CovLogger.d(TAG, "设备信息已更新: ${device.id}, 名称: ${device.name}")
                        } else {
                            CovLogger.e(TAG, "未找到要更新的设备: ${device.id}")
                            ToastUtil.show("更新设备信息失败")
                        }
                    }
                )
                dialog.show(supportFragmentManager, "iot_settings")
            }

            override fun onNameChanged(device: CovIotDevice, newName: String, position: Int) {
                // 更新设备名称
                if (position >= 0 && position < deviceList.size) {
                    deviceList[position].name = newName
                    deviceAdapter.notifyItemChanged(position)
                    
                    // 保存到本地
                    saveDevicesToLocal()
                    
                    ToastUtil.show("设备名称已更新为: $newName")
                    CovLogger.d(TAG, "设备名称已更新: ${device.id}, 新名称: $newName")
                } else {
                    CovLogger.e(TAG, "尝试更新无效位置的设备名称: $position, 列表大小: ${deviceList.size}")
                }
            }
        })
        
        mBinding?.rvDevices?.apply {
            layoutManager = LinearLayoutManager(this@CovIotDeviceListActivity)
            adapter = deviceAdapter
            
            // 设置自定义的项目动画
            itemAnimator = androidx.recyclerview.widget.DefaultItemAnimator().apply {
                // 设置添加、移除、移动动画的持续时间
                addDuration = 300
                removeDuration = 300
                moveDuration = 300
                changeDuration = 300
            }
        }
    }

    private fun initData() {
        // 从本地存储加载设备列表数据
        coroutineScope.launch {
            loadDevicesFromLocal()
            updateEmptyState()
        }
    }
    
    private fun loadDevicesFromLocal() {
        val loadedDevices = deviceManager.loadDevicesFromLocal()
        deviceList.clear()
        deviceList.addAll(loadedDevices)
        deviceAdapter.notifyDataSetChanged()
    }
    
    private fun saveDevicesToLocal() {
        deviceManager.saveDevicesToLocal(deviceList)
    }

//    private fun addNewDevice() {
//        // 模拟添加新设备
//        val newDevice = CovIotDevice(
//            id = System.currentTimeMillis().toString(),
//            name = "新设备 ${deviceList.size + 1}"
//        )
//
//        // 如果之前列表为空，先清空RecyclerView的缓存
//        val wasEmpty = deviceList.isEmpty()
//        if (wasEmpty) {
//            mBinding?.rvDevices?.recycledViewPool?.clear()
//        }
//
//        deviceList.add(0, newDevice)
//
//        if (wasEmpty) {
//            // 如果之前列表为空，使用notifyDataSetChanged确保完全刷新
//            deviceAdapter.notifyDataSetChanged()
//        } else {
//            // 否则使用局部更新
//            deviceAdapter.notifyItemInserted(0)
//            deviceAdapter.notifyItemRangeChanged(1, deviceList.size - 1)
//        }
//
//        mBinding?.rvDevices?.scrollToPosition(0)
//
//        // 保存到本地
//        saveDevicesToLocal()
//
//        // 更新空状态
//        updateEmptyState()
//    }

    private fun removeDevice(device: CovIotDevice, position: Int) {
        if (position >= 0 && position < deviceList.size) {
            deviceList.removeAt(position)
            deviceAdapter.notifyItemRemoved(position)
            // 通知从删除位置开始的所有后续项目位置变化
            deviceAdapter.notifyItemRangeChanged(position, deviceList.size - position)
            
            // 保存到本地
            saveDevicesToLocal()
            
            // 更新空状态
            updateEmptyState()
        } else {
            CovLogger.e(TAG, "尝试删除无效位置的设备: $position, 列表大小: ${deviceList.size}")
            ToastUtil.show("删除设备失败")
        }
    }
    
    private fun updateEmptyState() {
        mBinding?.apply {
            if (deviceList.isEmpty()) {
                // 当列表为空时，清空适配器缓存
                rvDevices.recycledViewPool.clear()
                
                ivAdd.visibility = View.GONE
                rvDevices.visibility = View.GONE
                clEmptyState.visibility = View.VISIBLE
            } else {
                ivAdd.visibility = View.VISIBLE
                rvDevices.visibility = View.VISIBLE
                clEmptyState.visibility = View.GONE
            }
        }
    }
}
package io.agora.scene.convoai.iot.ui

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.dp
import io.agora.scene.common.util.getStatusBarHeight
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.databinding.CovActivityDeviceConnectBinding
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import io.agora.scene.common.ui.CommonDialog
import io.agora.scene.convoai.R
import android.view.animation.Animation
import android.view.animation.LinearInterpolator
import android.view.animation.RotateAnimation
import io.agora.scene.convoai.iot.manager.BleDeviceManager
import io.agora.scene.convoai.iot.model.CovIotDevice
import io.agora.scene.convoai.iot.ui.dialog.CovDeviceConnectionFailedDialog
import io.iot.dn.ble.manager.BleManager
import io.iot.dn.ble.model.BleDevice

class CovDeviceConnectActivity : BaseActivity<CovActivityDeviceConnectBinding>() {

    companion object {
        private const val TAG = "CovDeviceConnectActivity"
        private const val EXTRA_DEVICE = "extra_device"
        private const val EXTRA_WIFI_SSID = "extra_wifi_ssid"
        private const val EXTRA_WIFI_PASSWORD = "extra_wifi_password"

        fun startActivity(activity: BaseActivity<*>, deviceAddress: String, wifiSsid: String, wifiPassword: String) {
            val intent = Intent(activity, CovDeviceConnectActivity::class.java).apply {
                putExtra(EXTRA_DEVICE, deviceAddress)
                putExtra(EXTRA_WIFI_SSID, wifiSsid)
                putExtra(EXTRA_WIFI_PASSWORD, wifiPassword)
            }
            activity.startActivity(intent)
        }
    }
    
    // 创建协程作用域用于异步操作
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    private val viewModelScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    // 设备对象
    private var device: BleDevice? = null
    // WiFi信息
    private var wifiSsid: String = ""
    private var wifiPassword: String = ""

    private val bleManager = BleManager(this)
    
    // 连接状态
    private enum class ConnectState {
        CONNECTING,  // 连接中
        FAILED,      // 连接失败
        SUCCESS      // 连接成功
    }

    override fun getViewBinding(): CovActivityDeviceConnectBinding {
        return CovActivityDeviceConnectBinding.inflate(layoutInflater)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initData()
        startConnect()
    }

    override fun initView() {
        setupView()
    }

    override fun onDestroy() {
        coroutineScope.cancel()
        super.onDestroy()
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
            
            // 添加旋转动画
            startConnectingAnimation()
        }
    }

    private fun initData() {
        // 从Intent中获取设备信息和WiFi信息
        device = BleDeviceManager.getDevice(intent.getStringExtra(EXTRA_DEVICE) ?: "")
        wifiSsid = intent.getStringExtra(EXTRA_WIFI_SSID) ?: ""
        wifiPassword = intent.getStringExtra(EXTRA_WIFI_PASSWORD) ?: ""
        CovLogger.d(TAG, "连接设备: ${device}, WiFi: $wifiSsid")
    }
    
    // 开始连接设备
    private fun startConnect() {
        val device = this.device ?: return
        updateConnectState(ConnectState.CONNECTING)

//        CovIotApiManager.generatorToken(device.address) { model, e ->
//            if (e != null || model?.auth_token?.isEmpty() == true) {
//                updateConnectState(ConnectState.FAILED)
//            } else {
//                viewModelScope.launch {
//                    try {
//                        val ret = bleManager.distributionNetwork(
//                            device = device.device,
//                            ssid = wifiSsid,
//                            pwd = wifiPassword,
//                            token = model?.auth_token ?: ""
//                        )
//                        if (ret) updateConnectState(ConnectState.SUCCESS) else updateConnectState(ConnectState.FAILED)
//                    } catch (e: BleError) {
//                        updateConnectState(ConnectState.FAILED)
//                    }
//                }
//            }
//        }
        // 模拟连接过程
        simulateConnectProcess()
    }
    
    // 模拟连接过程
    private fun simulateConnectProcess() {
        coroutineScope.launch {
            // 模拟连接延迟
            delay(5000)
            
            // 随机决定连接结果（50%成功率）
            val isSuccess = (0..100).random() <= 50
            
            if (isSuccess) {
                // 连接成功
                updateConnectState(ConnectState.SUCCESS)
            } else {
                // 连接失败
                updateConnectState(ConnectState.FAILED)
            }
        }
    }
    
    // 添加旋转动画方法
    private fun startConnectingAnimation() {
        mBinding?.ivConnectingCircle?.let { connectingCircle ->
            // 创建旋转动画
            val rotateAnimation = RotateAnimation(
                0f, 360f,
                Animation.RELATIVE_TO_SELF, 0.5f,
                Animation.RELATIVE_TO_SELF, 0.5f
            )

            // 设置动画属性
            rotateAnimation.duration = 2000 // 旋转一周的时间为2秒
            rotateAnimation.repeatCount = Animation.INFINITE // 无限循环
            rotateAnimation.interpolator = LinearInterpolator() // 线性插值器，使旋转速度均匀

            // 启动动画
            connectingCircle.startAnimation(rotateAnimation)
        }
    }
    
    // 更新连接状态UI
    private fun updateConnectState(state: ConnectState) {
        mBinding?.apply {
            when (state) {
                ConnectState.CONNECTING -> {
                    clConnecting.visibility = View.VISIBLE
                    tvConnectingStatus.text = getString(R.string.cov_iot_devices_connecting)
                    // 确保动画在连接状态下运行
                    startConnectingAnimation()
                }
                ConnectState.FAILED -> {
                    clConnecting.visibility = View.GONE
                    // 停止动画
                    ivConnectingCircle.clearAnimation()
                    // 显示连接失败的UI
                    showConnectionFailedDialog()
                }
                ConnectState.SUCCESS -> {
                    clConnecting.visibility = View.GONE
                    // 停止动画
                    ivConnectingCircle.clearAnimation()
                    // 显示连接成功的对话框
                    showConnectionSuccessDialog()
                }
            }
        }
    }

    // 显示连接成功对话框
    private fun showConnectionSuccessDialog() {
        CommonDialog.Builder()
            .setTitle(getString(R.string.cov_iot_devices_connect_connect_success))
            .setContent(getString(R.string.cov_iot_devices_connect_connect_success_tips))
            .setPositiveButton(getString(R.string.cov_iot_devices_connect_connect_success_know)) {
                // 保存设备到设备列表
                saveDeviceToList()
                // 返回设备列表页面
                navigateToDeviceListPage()
            }
            .setImage(R.drawable.cov_iot_connect_success)
            .hideNegativeButton()
            .setCancelable(false)
            .build()
            .show(supportFragmentManager, "dialog_success")
    }

    // 导航到设备列表页面
    private fun navigateToDeviceListPage() {
        // 假设设备列表页面是CovDeviceListActivity
        val intent = Intent(this, CovIotDeviceListActivity::class.java).apply {
            // 清除任务栈中当前Activity之上的所有Activity
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        startActivity(intent)
        finish()
    }

    // 显示连接失败对话框
    private fun showConnectionFailedDialog() {
        CovDeviceConnectionFailedDialog.newInstance(
            onDismiss = {
                //finish()
                navigateToDeviceListPage()
            },
            onRescan = {
                //startConnect()
                navigateToDeviceListPage()
            }
        ).show(supportFragmentManager, "dialog_failed")
    }

    // 保存设备到设备列表
    private fun saveDeviceToList() {
        device?.let { device ->
            try {
                // 将Device转换为CovIotDevice
                val iotDevice = CovIotDevice(
                    id = device.address,
                    name = device.name,
                    bleDevice = device,
                    currentPreset = "",
                    currentLanguage = "",
                    enableAIVAD = false
                )
                
                // 从SharedPreferences加载现有设备列表
                val sharedPrefs = getSharedPreferences("iot_devices_prefs", MODE_PRIVATE)
                val devicesJson = sharedPrefs.getString("saved_devices", null)
                
                val deviceList = mutableListOf<CovIotDevice>()
                
                if (!devicesJson.isNullOrEmpty()) {
                    val type = object : com.google.gson.reflect.TypeToken<List<CovIotDevice>>() {}.type
                    val loadedDevices = com.google.gson.Gson().fromJson<List<CovIotDevice>>(devicesJson, type)
                    deviceList.addAll(loadedDevices)
                }
                
                // 检查设备是否已存在
                val existingDeviceIndex = deviceList.indexOfFirst { it.id == iotDevice.id }
                if (existingDeviceIndex >= 0) {
                    // 更新现有设备
                    deviceList[existingDeviceIndex] = iotDevice
                } else {
                    // 添加新设备
                    deviceList.add(0, iotDevice)
                }
                
                // 保存更新后的设备列表
                val updatedDevicesJson = com.google.gson.Gson().toJson(deviceList)
                sharedPrefs.edit().putString("saved_devices", updatedDevicesJson).apply()
                
                CovLogger.d(TAG, "设备已保存到列表: ${iotDevice.name}")
            } catch (e: Exception) {
                CovLogger.e(TAG, "保存设备失败: ${e.message}")
                e.printStackTrace()
            }
        }
    }
} 
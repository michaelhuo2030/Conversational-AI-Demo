package io.agora.scene.convoai.iot.ui

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.provider.Settings
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import androidx.recyclerview.widget.LinearLayoutManager
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.dp
import io.agora.scene.common.util.getStatusBarHeight
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.databinding.CovActivityDeviceScanBinding
import io.agora.scene.convoai.iot.adapter.DeviceAdapter
import io.iot.dn.ble.callback.BleListener
import io.iot.dn.ble.manager.BleManager
import io.iot.dn.ble.model.BleDevice
import io.iot.dn.ble.state.BleConnectionState
import io.iot.dn.ble.state.BleScanState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import io.agora.scene.convoai.iot.manager.BleDeviceManager
import io.agora.scene.convoai.iot.ui.dialog.CovPermissionDialog

class CovDeviceScanActivity : BaseActivity<CovActivityDeviceScanBinding>() {

    private val TAG = "CovDeviceScanActivity"
    
    // 创建协程作用域用于异步操作
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    private val bleManager = BleManager(this)

    // 设备列表适配器
    private lateinit var deviceAdapter: DeviceAdapter
    
    // 设备列表
    private val deviceList = mutableListOf<BleDevice>()
    
    // 倒计时器
    private var countDownTimer: CountDownTimer? = null

    private var permissionDialog: CovPermissionDialog? = null
    
    // 扫描状态
    private enum class ScanState {
        SCANNING,    // 扫描中
        FAILED,      // 扫描失败
        SUCCESS      // 扫描成功
    }

    override fun getViewBinding(): CovActivityDeviceScanBinding {
        return CovActivityDeviceScanBinding.inflate(layoutInflater)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initData()
    }

    override fun initView() {
        setupView()
        setupDeviceList()
        setupRippleAnimation()
        initBle()
        startScan()
    }

    override fun onDestroy() {
        countDownTimer?.cancel()
        coroutineScope.cancel()
        super.onDestroy()
    }

    override fun onResume() {
        super.onResume()
        // 检查WiFi是否已开启，如果已开启则关闭权限对话框
        if (isNetworkConnected() && permissionDialog?.isAdded == true) {
            permissionDialog?.dismiss()
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
            
            // 设置重试按钮点击事件
            btnRetry.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    startScan()
                }
            })
        }
    }
    
    // 设置涟漪动画
    private fun setupRippleAnimation() {
        mBinding?.apply {
            // 扫描中的涟漪动画
            rippleAnimationView.scaleFactor = 1.4f
        }
    }
    
    private fun setupDeviceList() {
        deviceAdapter = DeviceAdapter(deviceList) { device ->
            // 设备点击事件处理
            CovLogger.d(TAG, "点击设备: ${device.name}")
            // 检查网络连接状态
            if (!isNetworkConnected()) {
                // 网络未连接，显示提示对话框
                showNetworkSettingsDialog()
            } else {
                // 网络已连接，只传递设备ID
                CovWifiSelectActivity.startActivity(this, device.address)
            }
        }
        
        mBinding?.apply {
            rvDeviceList.layoutManager = LinearLayoutManager(this@CovDeviceScanActivity)
            rvDeviceList.adapter = deviceAdapter
        }
    }

    private fun initData() {
        // 可以在这里初始化数据，例如从Intent中获取设备类型等信息
        val deviceType = intent.getStringExtra(EXTRA_DEVICE_TYPE) ?: "未知设备"
        CovLogger.d(TAG, "扫描设备类型: $deviceType")
    }

    private fun initBle() {
        bleManager.addListener(object : BleListener {
            override fun onScanStateChanged(state: BleScanState) {
                // 处理扫描状态变化
            }

            override fun onDeviceFound(device: BleDevice) {
                Log.d("hugo", "onDeviceFound: $device")
                // 将发现的设备添加到设备管理器
                BleDeviceManager.addDevice(device)
                
                runOnUiThread {
                    // 检查设备是否已存在于列表中
                    if (deviceList.none { it.address == device.address } && device.name.isNotEmpty()) {
                        deviceList.add(device)
                        deviceAdapter.notifyDataSetChanged()
                        
                        // 发现设备后，隐藏扫描中视图，但保留波纹动画
                        if (deviceList.size == 1) { // 第一次发现设备时
                            mBinding?.clScanning?.visibility = View.GONE
                            mBinding?.clScanResult?.visibility = View.VISIBLE
                            // 波纹动画保持可见
                            mBinding?.rippleAnimationView?.alpha = 0.5F
                        }
                    }
                }
            }

            override fun onConnectionStateChanged(state: BleConnectionState) {
                // 处理连接状态变化
            }

            override fun onDataReceived(uuid: String, data: ByteArray) {
                // 处理接收到的数据
            }
        })
    }
    
    // 开始扫描设备
    private fun startScan() {
        updateScanState(ScanState.SCANNING)
        
        // 清空之前的设备列表
        deviceList.clear()
        deviceAdapter.notifyDataSetChanged()
        
        // 清空设备管理器中的设备
        BleDeviceManager.clearDevices()
        
        // 启动蓝牙扫描
        mBinding?.root?.postDelayed({
            bleManager.startScan(null)
        }, 3000)
        
        // 启动30秒倒计时
        countDownTimer?.cancel()
        countDownTimer = object : CountDownTimer(30000, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val seconds = millisUntilFinished / 1000
                mBinding?.tvCountdown?.text = "${seconds}s"
            }

            override fun onFinish() {
                // 停止扫描
                bleManager.stopScan()
                
                // 根据deviceList数量决定是否扫描成功
                if (deviceList.isEmpty()) {
                    // 没有找到设备，显示失败状态
                    updateScanState(ScanState.FAILED)
                } else {
                    // 找到设备，显示设备列表
                    updateScanState(ScanState.SUCCESS)
                }
            }
        }.start()
    }
    
    // 更新扫描状态UI
    private fun updateScanState(state: ScanState) {
        mBinding?.apply {
            when (state) {
                ScanState.SCANNING -> {
                    rippleAnimationView.alpha = 1.0F
                    tvCountdown.visibility = View.VISIBLE
                    clScanning.visibility = View.VISIBLE
                    clScanFailed.visibility = View.GONE
                    clScanResult.visibility = View.VISIBLE
                    rippleAnimationView.visibility = View.VISIBLE
                    
                    // 扫描中时，设置clScanResult距离底部160dp
                    val layoutParams = clScanResult.layoutParams as ViewGroup.MarginLayoutParams
                    layoutParams.bottomMargin = 160.dp.toInt()
                    clScanResult.layoutParams = layoutParams
                }
                ScanState.FAILED -> {
                    clScanning.visibility = View.GONE
                    clScanFailed.visibility = View.VISIBLE
                    clScanResult.visibility = View.GONE
                    rippleAnimationView.visibility = View.GONE
                    tvCountdown.visibility = View.GONE
                }
                ScanState.SUCCESS -> {
                    clScanning.visibility = View.GONE
                    clScanFailed.visibility = View.GONE
                    clScanResult.visibility = View.VISIBLE
                    rippleAnimationView.visibility = View.GONE // 扫描成功时隐藏波纹动画
                    tvCountdown.visibility = View.GONE
                    
                    // 扫描成功后，设置clScanResult距离底部60dp
                    val layoutParams = clScanResult.layoutParams as ViewGroup.MarginLayoutParams
                    layoutParams.bottomMargin = 60.dp.toInt()
                    clScanResult.layoutParams = layoutParams
                }
            }
        }
    }

    // 检查WiFi开关是否开启
    private fun isNetworkConnected(): Boolean {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
        return wifiManager.isWifiEnabled
    }

    // 显示权限对话框
    private fun showNetworkSettingsDialog() {
        if (permissionDialog == null) {
            permissionDialog = CovPermissionDialog.newInstance(
                onDismiss = {
                    // 对话框关闭回调
                    permissionDialog = null
                },
                onWifiPermission = {
                    startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                },
                showBluetoothPermission = false,
                showLocation = false,
                showWifi = true
            )
        }

        permissionDialog?.apply {
            updateWifiPermissionStatus(false)
            if (!isAdded) {
                show(supportFragmentManager, "permission_dialog")
            }
        }
    }

    companion object {
        private const val EXTRA_DEVICE_TYPE = "extra_device"
        
        fun startActivity(activity: BaseActivity<*>, deviceType: String = "") {
            val intent = Intent(activity, CovDeviceScanActivity::class.java).apply {
                putExtra(EXTRA_DEVICE_TYPE, deviceType)
            }
            activity.startActivity(intent)
        }
    }
} 
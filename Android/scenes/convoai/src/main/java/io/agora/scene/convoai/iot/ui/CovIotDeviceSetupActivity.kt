package io.agora.scene.convoai.iot.ui

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import androidx.viewpager2.widget.ViewPager2
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.dp
import io.agora.scene.common.util.getStatusBarHeight
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovActivityIotDeviceSetupBinding
import io.agora.scene.convoai.iot.adapter.DeviceImageAdapter
import io.agora.scene.convoai.iot.model.DeviceImage
import io.agora.scene.convoai.iot.ui.dialog.CovPermissionDialog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

class CovIotDeviceSetupActivity : BaseActivity<CovActivityIotDeviceSetupBinding>() {

    companion object {
        private const val TAG = "CovIotDeviceSetupActivity"
        private const val EXTRA_DEVICE_TYPE = "extra_device_type"
        private const val MAX_PERMISSION_REQUEST_COUNT = 1

        fun startActivity(activity: BaseActivity<*>, deviceType: String = "") {
            val intent = Intent(activity, CovIotDeviceSetupActivity::class.java).apply {
                putExtra(EXTRA_DEVICE_TYPE, deviceType)
            }
            activity.startActivity(intent)
        }
    }
    
    // 创建协程作用域用于异步操作
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    // 设备图片适配器
    private lateinit var deviceImageAdapter: DeviceImageAdapter
    
    // 设备图片列表
    private val deviceImages = mutableListOf<DeviceImage>()
    
    // 设备类型
    private var deviceType: String = "未知设备"
    
    // 蓝牙适配器
    private val bluetoothAdapter: BluetoothAdapter? by lazy {
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothManager.adapter
    }
    
    // 权限对话框
    private var permissionDialog: CovPermissionDialog? = null
    
    // 权限请求计数器
    private var locationPermissionRequestCount = 0
    private var bluetoothPermissionRequestCount = 0
    
    // 位置服务检查启动器
    private val locationSettingsLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        // 用户从位置设置页面返回后，重新检查位置服务
        checkLocationEnabledAfterSettings()
    }
    
    // 权限请求回调
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        var locationPermissionGranted = true
        var bluetoothPermissionGranted = true
        
        // 检查位置权限结果
        if (permissions.containsKey(Manifest.permission.ACCESS_FINE_LOCATION)) {
            locationPermissionGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] == true
            if (locationPermissionGranted) {
                locationPermissionRequestCount = 0
            } else {
                locationPermissionRequestCount++
            }
        }
        
        // 检查蓝牙权限结果（Android 12及以上）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (permissions.containsKey(Manifest.permission.BLUETOOTH_SCAN)) {
                bluetoothPermissionGranted = bluetoothPermissionGranted && 
                    permissions[Manifest.permission.BLUETOOTH_SCAN] == true
            }
            if (permissions.containsKey(Manifest.permission.BLUETOOTH_CONNECT)) {
                bluetoothPermissionGranted = bluetoothPermissionGranted && 
                    permissions[Manifest.permission.BLUETOOTH_CONNECT] == true
            }
            
            if (!bluetoothPermissionGranted) {
                bluetoothPermissionRequestCount++
            } else {
                bluetoothPermissionRequestCount = 0
            }
        }
        
        // 如果有权限被拒绝，显示权限对话框
        if (!locationPermissionGranted || !bluetoothPermissionGranted) {
            showPermissionDialog(locationPermissionGranted, bluetoothPermissionGranted)
        } else {
            // 所有权限都已授予，检查蓝牙是否开启
            checkBluetoothEnabled()
        }
    }
    
    // 蓝牙开启请求回调
    private val bluetoothEnableLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            // 蓝牙已开启
            permissionDialog?.updateBluetoothPermissionStatus(true)
            checkLocationEnabled()
        } else {
            // 用户拒绝开启蓝牙
            ToastUtil.show("需要开启蓝牙才能配置设备")
            permissionDialog?.updateBluetoothPermissionStatus(true)
            showPermissionDialog(
                ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) 
                    == PackageManager.PERMISSION_GRANTED,
                true,
                false
            )
        }
    }

    override fun getViewBinding(): CovActivityIotDeviceSetupBinding {
        return CovActivityIotDeviceSetupBinding.inflate(layoutInflater)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initData()
    }

    override fun initView() {
        setupView()
        setupViewPager()
        setupCheckbox()
    }

    override fun onResume() {
        super.onResume()
        // 在页面恢复时更新UI状态
        updateUIState()
    }

    override fun onDestroy() {
        // 清理资源，避免内存泄漏
        dismissPermissionDialog()
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
            
            // 设置下一步按钮点击事件
            btnNext.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    if (cbConfirm.isChecked) {
                        // 开始权限检查和蓝牙检查流程
                        checkAndRequestPermissions()
                    } else {
                        ToastUtil.show("请先确认已完成上述操作")
                    }
                }
            })

            // 初始化按钮状态
            updateNextButtonState(cbConfirm.isChecked)
        }
    }
    
    private fun setupViewPager() {
        // 初始化设备图片数据
        deviceImages.clear()
        deviceImages.add(DeviceImage(R.drawable.cov_iot_prepare_pic_1, "设备正面图"))
        deviceImages.add(DeviceImage(R.drawable.cov_iot_device_item_bg_2, "设备背面图"))
        
        deviceImageAdapter = DeviceImageAdapter(deviceImages)
        
        mBinding?.apply {
            viewpagerDevice.adapter = deviceImageAdapter
            
            // 设置ViewPager2页面切换监听
            viewpagerDevice.registerOnPageChangeCallback(object : ViewPager2.OnPageChangeCallback() {
                override fun onPageSelected(position: Int) {
                    super.onPageSelected(position)
                    // 防止索引越界
                    if (position >= 0 && position < deviceImages.size) {
                        updateIndicators(position)
                    }
                }
            })
            
            // 初始化指示器状态
            updateIndicators(0)
        }
    }
    
    private fun updateIndicators(position: Int) {
        mBinding?.apply {
            // 根据当前页面位置更新指示器状态
            indicator1.setBackgroundResource(
                if (position == 0) R.drawable.shape_indicator_selected 
                else R.drawable.shape_indicator_normal
            )
            
            indicator2.setBackgroundResource(
                if (position == 1) R.drawable.shape_indicator_selected 
                else R.drawable.shape_indicator_normal
            )
        }
    }
    
    private fun setupCheckbox() {
        mBinding?.apply {
            cbConfirm.setOnCheckedChangeListener { _, isChecked ->
                // 根据复选框状态启用或禁用下一步按钮
                updateNextButtonState(isChecked)
            }
        }
    }

    private fun initData() {
        // 从Intent中获取设备类型
        deviceType = intent.getStringExtra(EXTRA_DEVICE_TYPE) ?: "未知设备"
        CovLogger.d(TAG, "设置设备类型: $deviceType")
    }

    // 更新UI状态
    private fun updateUIState() {
        mBinding?.apply {
            // 更新复选框和按钮状态
            updateNextButtonState(cbConfirm.isChecked == true)
        }
    }

    // 检查并请求必要的权限
    private fun checkAndRequestPermissions() {
        val permissionsToRequest = mutableListOf<String>()
        var locationPermissionGranted = true
        var bluetoothPermissionGranted = true
        
        // 检查位置权限（BLE扫描需要）
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) 
            != PackageManager.PERMISSION_GRANTED) {
            permissionsToRequest.add(Manifest.permission.ACCESS_FINE_LOCATION)
            locationPermissionGranted = false
        }
        
        // Android 12及以上需要蓝牙扫描和连接权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) 
                != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH_SCAN)
                bluetoothPermissionGranted = false
            }
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) 
                != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH_CONNECT)
                bluetoothPermissionGranted = false
            }
        }
        
        if (permissionsToRequest.isNotEmpty()) {
            // 请求权限
            requestPermissionLauncher.launch(permissionsToRequest.toTypedArray())
        } else {
            // 已有所有权限，检查蓝牙是否开启
            checkBluetoothEnabled()
        }
    }
    
    // 显示权限对话框
    private fun showPermissionDialog(locationGranted: Boolean, bluetoothGranted: Boolean, bluetoothOpen: Boolean? = null) {
        if (permissionDialog == null) {
            permissionDialog = CovPermissionDialog.newInstance(
                onDismiss = {
                    // 对话框关闭回调
                    permissionDialog = null
                },
                onLocationPermission = {
                    // 位置权限点击回调
                    if (locationPermissionRequestCount >= MAX_PERMISSION_REQUEST_COUNT) {
                        // 用户多次拒绝，直接跳转到应用设置页面
                        openAppSettings()
                        ToastUtil.show("请在设置中手动授予位置权限")
                    } else {
                        requestLocationPermission()
                    }
                },
                onBluetoothPermission = {
                    // 蓝牙权限点击回调
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && 
                        bluetoothPermissionRequestCount >= MAX_PERMISSION_REQUEST_COUNT) {
                        // 用户多次拒绝，直接跳转到应用设置页面
                        openAppSettings()
                        ToastUtil.show("请在设置中手动授予蓝牙权限")
                    } else {
                        requestBluetoothPermission()
                    }
                },
                onBluetoothSwitch = {
                    // 请求开启蓝牙
                    val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                    bluetoothEnableLauncher.launch(enableBtIntent)
                }
            )
        }
        
        permissionDialog?.apply {
            updateLocationPermissionStatus(locationGranted)
            updateBluetoothPermissionStatus(bluetoothGranted)
            if (bluetoothOpen != null) showBluetoothSwitch()
            
            if (!isAdded) {
                show(supportFragmentManager, "permission_dialog")
            }
        }
    }
    
    // 关闭权限对话框
    private fun dismissPermissionDialog() {
        permissionDialog?.dismiss()
        permissionDialog = null
    }
    
    // 打开应用设置页面
    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = android.net.Uri.parse("package:$packageName")
                addCategory(Intent.CATEGORY_DEFAULT)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) {
            CovLogger.e(TAG, "无法打开应用设置页面: ${e.message}")
            ToastUtil.show("请手动前往设置页面授予权限")
        }
    }
    
    // 请求位置权限
    private fun requestLocationPermission() {
        requestPermissionLauncher.launch(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION))
    }
    
    // 请求蓝牙权限
    private fun requestBluetoothPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            requestPermissionLauncher.launch(arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT
            ))
        } else {
            // Android 12以下版本不需要额外的蓝牙权限
            permissionDialog?.updateBluetoothPermissionStatus(true)
            checkBluetoothEnabled()
        }
    }
    
    // 检查蓝牙是否开启
    private fun checkBluetoothEnabled() {
        bluetoothAdapter?.let { adapter ->
            if (!adapter.isEnabled) {
                // 蓝牙未开启，请求开启
                val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                bluetoothEnableLauncher.launch(enableBtIntent)
            } else {
                // 蓝牙已开启，检查位置服务
                checkLocationEnabled()
            }
        } ?: run {
            // 设备不支持蓝牙
            ToastUtil.show("设备不支持蓝牙功能，无法配置设备")
            // 提供替代方案或退出流程
            showDeviceNotSupportedDialog()
        }
    }
    
    // 显示设备不支持对话框
    private fun showDeviceNotSupportedDialog() {
        // 这里可以实现一个对话框，告知用户设备不支持蓝牙，无法继续配置
        // 可以提供替代方案或退出流程
        ToastUtil.show("您的设备不支持蓝牙功能，无法配置智能设备")
        finish()
    }
    
    // 检查位置服务是否开启
    private fun checkLocationEnabled() {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val isLocationEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        
        if (!isLocationEnabled) {
            // 位置服务未开启，提示用户开启
            ToastUtil.show("请开启位置服务以便配置设备")
            // 跳转到位置设置页面
            try {
                val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                locationSettingsLauncher.launch(intent)
            } catch (e: Exception) {
                CovLogger.e(TAG, "无法打开位置设置页面: ${e.message}")
                ToastUtil.show("请手动开启位置服务")
            }
            
            permissionDialog?.updateLocationPermissionStatus(false)
            showPermissionDialog(false, 
                bluetoothAdapter?.isEnabled == true
            )
        } else {
            // 所有条件都满足，可以进入配网流程
            permissionDialog?.updateLocationPermissionStatus(true)
            startWifiConnectActivity()
        }
    }
    
    // 从设置页面返回后检查位置服务
    private fun checkLocationEnabledAfterSettings() {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val isLocationEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        
        if (isLocationEnabled) {
            // 位置服务已开启，可以进入配网流程
            permissionDialog?.updateLocationPermissionStatus(true)
            dismissPermissionDialog()
            startWifiConnectActivity()
        } else {
            // 位置服务仍未开启
            ToastUtil.show("需要开启位置服务才能配置设备")
            permissionDialog?.updateLocationPermissionStatus(false)
        }
    }
    
    // 启动Wi-Fi连接页面
    private fun startWifiConnectActivity() {
        val intent = Intent(this, CovDeviceScanActivity::class.java).apply {
            // 传递设备类型到下一个页面
            putExtra(EXTRA_DEVICE_TYPE, deviceType)
        }
        startActivity(intent)
    }

    // 添加更新按钮状态的方法
    private fun updateNextButtonState(isChecked: Boolean) {
        mBinding?.apply {
            btnNext.let { button ->
                button.isEnabled = isChecked
                button.alpha = if (isChecked) 1.0f else 0.5f
            }
        }
    }
}
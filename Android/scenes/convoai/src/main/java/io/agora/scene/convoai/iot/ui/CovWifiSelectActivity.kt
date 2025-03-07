package io.agora.scene.convoai.iot.ui

import android.content.Intent
import android.net.wifi.WifiManager
import android.os.Bundle
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Toast
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.dp
import io.agora.scene.common.util.getStatusBarHeight
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovActivityWifiSelectBinding
import io.agora.scene.convoai.iot.manager.BleDeviceManager
import io.iot.dn.ble.model.BleDevice
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class CovWifiSelectActivity : BaseActivity<CovActivityWifiSelectBinding>() {

    private val TAG = "CovWifiSelectActivity"
    
    // 创建协程作用域用于异步操作
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    // 当前连接的Wi-Fi网络
    private var currentWifi: String? = null
    
    // 是否显示密码
    private var isPasswordVisible = false
    
    // 移除不需要的WiFi网络列表
    // private val wifiNetworks = mutableListOf<WifiNetwork>()

    private lateinit var bleDevice: BleDevice

    override fun getViewBinding(): CovActivityWifiSelectBinding {
        return CovActivityWifiSelectBinding.inflate(layoutInflater)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 获取设备ID
        val deviceId = intent.getStringExtra(EXTRA_DEVICE_ID) ?: ""
        
        // 从设备管理器获取设备
        val device = BleDeviceManager.getDevice(deviceId)
        if (device == null) {
            // 设备不存在，显示错误并返回
            Toast.makeText(this, "设备信息不存在", Toast.LENGTH_SHORT).show()
            finish()
            return
        }
        
        // 保存设备信息
        bleDevice = device
        
        // 继续初始化
        initData()
    }

    override fun initView() {
        setupView()
        setupPasswordToggle()
        setupWifiSelection()
        setupNextButton()
    }

    override fun onDestroy() {
        coroutineScope.cancel()
        super.onDestroy()
    }

    override fun onResume() {
        super.onResume()
        // 每次页面恢复时重新获取当前Wi-Fi信息
        getCurrentWifi()
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
        }
    }
    
    private fun setupPasswordToggle() {
        mBinding?.apply {
            // 设置密码可见性切换
            ivTogglePassword.setOnClickListener {
                isPasswordVisible = !isPasswordVisible
                
                // 更新密码输入框的输入类型
                if (isPasswordVisible) {
                    etWifiPassword.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD
                    ivTogglePassword.setImageResource(R.drawable.cov_iot_show_pw)
                } else {
                    etWifiPassword.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
                    ivTogglePassword.setImageResource(R.drawable.cov_iot_hide_pw)
                }
                
                // 将光标移到文本末尾
                etWifiPassword.setSelection(etWifiPassword.text.length)
            }
            
            // 监听密码输入变化
            etWifiPassword.addTextChangedListener(object : TextWatcher {
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
                
                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
                
                override fun afterTextChanged(s: Editable?) {
                    // 根据密码长度启用或禁用下一步按钮
                    val isEnabled = !s.isNullOrEmpty() && s.length >= 8
                    btnNext.isEnabled = isEnabled
                    // 根据按钮状态设置alpha值
                    btnNext.alpha = if (isEnabled) 1.0f else 0.5f
                }
            })
        }
    }
    
    private fun setupWifiSelection() {
        mBinding?.apply {
            // 设置当前Wi-Fi名称
            currentWifi?.let {
                tvWifiName.text = it
            }
            
            // 设置更换Wi-Fi按钮点击事件 - 打开系统Wi-Fi设置
            btnChangeWifi.setOnClickListener {
                openWifiSettings()
            }
        }
    }
    
    private fun setupNextButton() {
        mBinding?.apply {
            // 初始状态下禁用下一步按钮
            btnNext.isEnabled = false
            // 设置初始alpha值
            btnNext.alpha = 0.5f
            
            // 设置下一步按钮点击事件
            btnNext.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    val password = etWifiPassword.text.toString()
                    
                    if (password.length < 8) {
                        ToastUtil.show("Wi-Fi密码长度不能少于8位")
                        return
                    }
                    
                    // 保存Wi-Fi信息并进入下一步
                    currentWifi?.let {
                        startDeviceConnectActivity(password)
                    } ?: run {
                        ToastUtil.show("请先选择Wi-Fi网络")
                    }
                }
            })
        }
    }

    private fun initData() {
        // 添加日志输出检查device是否为null
        CovLogger.d(TAG, "配置设备Wi-Fi: ${bleDevice.name}, device是否为null: ${bleDevice == null}")
        
        // 如果device为null，显示提示并返回上一页面
        if (bleDevice == null) {
            ToastUtil.show("设备信息获取失败，请重试")
            finish()
            return
        }
        
        // 获取当前连接的Wi-Fi
        getCurrentWifi()
    }
    
    // 获取当前连接的Wi-Fi信息
    private fun getCurrentWifi() {
        coroutineScope.launch(Dispatchers.IO) {
            try {
                // 获取当前连接的Wi-Fi信息
                val wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
                val wifiInfo = wifiManager.connectionInfo
                val ssid = wifiInfo.ssid.replace("\"", "") // 移除SSID两端的引号
                
                if (ssid.isNotEmpty() && ssid != "<unknown ssid>") {
                    currentWifi = ssid
                    
                    // 检查WiFi频段
                    val is5GHz = checkIf5GHzWifi(wifiManager, wifiInfo)
                    
                    launch(Dispatchers.Main) {
                        mBinding?.tvWifiName?.text = currentWifi ?: ""
                        
                        if (is5GHz) {
                            // 5G WiFi - 显示红色并禁用密码输入
                            mBinding?.tvWifiName?.setTextColor(resources.getColor(io.agora.scene.common.R.color.ai_red6, null))
                            mBinding?.etWifiPassword?.isEnabled = false
                            mBinding?.btnNext?.isEnabled = false
                            mBinding?.btnNext?.alpha = 0.5f
                            mBinding?.tvWifiWarning?.visibility = View.VISIBLE
                        } else {
                            // 2.4G WiFi - 正常显示
                            mBinding?.tvWifiName?.setTextColor(resources.getColor(io.agora.scene.common.R.color.ai_icontext1, null))
                            mBinding?.etWifiPassword?.isEnabled = true
                            mBinding?.tvWifiWarning?.visibility = View.GONE
                            
                            // 更新UI状态，确保Wi-Fi已连接时启用下一步按钮（如果密码已输入）
                            val isEnabled = !mBinding?.etWifiPassword?.text.isNullOrEmpty() && 
                                           (mBinding?.etWifiPassword?.text?.length ?: 0) >= 8
                            mBinding?.btnNext?.isEnabled = isEnabled
                            // 根据按钮状态设置alpha值
                            mBinding?.btnNext?.alpha = if (isEnabled) 1.0f else 0.5f
                        }
                    }
                } else {
                    launch(Dispatchers.Main) {
                        mBinding?.tvWifiName?.text = ""
                        mBinding?.btnNext?.isEnabled = false
                        mBinding?.btnNext?.alpha = 0.5f
                        mBinding?.tvWifiWarning?.visibility = View.GONE
                        ToastUtil.show("未检测到Wi-Fi连接，请先连接Wi-Fi")
                    }
                }
            } catch (e: Exception) {
                CovLogger.e(TAG, "获取Wi-Fi信息失败: ${e.message}")
                
                launch(Dispatchers.Main) {
                    ToastUtil.show("获取Wi-Fi信息失败")
                }
            }
        }
    }
    
    // 检查当前WiFi是否为5GHz
    private fun checkIf5GHzWifi(wifiManager: WifiManager, wifiInfo: android.net.wifi.WifiInfo): Boolean {
        try {
            // Android 6.0 (API 23)及以上版本可以直接获取频率
            val frequency = wifiInfo.frequency
            CovLogger.d(TAG, "当前WiFi频率: $frequency MHz")
            
            // 5GHz WiFi频率范围通常在5000MHz以上
            return frequency > 4900
        } catch (e: Exception) {
            CovLogger.e(TAG, "获取WiFi频率失败: ${e.message}")
            // 如果无法获取频率，默认为非5G
            return false
        }
    }
    
    // 打开系统Wi-Fi设置页面
    private fun openWifiSettings() {
        try {
            val intent = Intent(android.provider.Settings.ACTION_WIFI_SETTINGS)
            startActivity(intent)
        } catch (e: Exception) {
            CovLogger.e(TAG, "打开Wi-Fi设置失败: ${e.message}")
            ToastUtil.show("无法打开Wi-Fi设置")
        }
    }
    
    // 启动设备连接页面
    private fun startDeviceConnectActivity(wifiPassword: String) {
        // 将Wi-Fi信息传递给设备连接页面
        CovDeviceConnectActivity.startActivity(this, bleDevice.address, currentWifi ?: "", wifiPassword)
    }

    companion object {
        private const val EXTRA_DEVICE_ID = "extra_device_id"
        
        fun startActivity(activity: BaseActivity<*>, deviceId: String) {
            val intent = Intent(activity, CovWifiSelectActivity::class.java).apply {
                putExtra(EXTRA_DEVICE_ID, deviceId)
            }
            activity.startActivity(intent)
            
            // 添加日志确认设备对象是否正确传递
            CovLogger.d("CovWifiSelectActivity", "启动Wi-Fi选择页面，传递设备: $deviceId")
        }
    }
}
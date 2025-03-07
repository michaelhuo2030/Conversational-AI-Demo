package io.agora.scene.convoai.iot.ui.dialog

import android.content.DialogInterface
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.convoai.databinding.CovPermissionDialogBinding

class CovPermissionDialog : BaseSheetDialog<CovPermissionDialogBinding>() {

    private var onDismissCallback: (() -> Unit)? = null
    private var onLocationPermissionClick: (() -> Unit)? = null
    private var onBluetoothPermissionClick: (() -> Unit)? = null
    private var onBluetoothSwitchClick: (() -> Unit)? = null
    private var onWifiPermissionClick: (() -> Unit)? = null
    
    // 权限状态
    private var locationPermissionGranted = false
    private var bluetoothPermissionGranted = false
    private var bluetoothSwitchNeedOpen = false
    private var wifiPermissionGranted = false
    
    // 权限显示配置
    private var showLocationPermission = true
    private var showBluetoothPermission = true
    private var showWifiPermission = false

    companion object {
        private const val TAG = "CovPermissionDialog"

        fun newInstance(
            onDismiss: () -> Unit,
            onLocationPermission: (() -> Unit)? = null,
            onBluetoothPermission: (() -> Unit)? = null,
            onWifiPermission: (() -> Unit)? = null,
            onBluetoothSwitch: (() -> Unit)? = null,
            showLocation: Boolean = true,
            showBluetoothPermission: Boolean = true,
            showWifi: Boolean = false
        ): CovPermissionDialog {
            return CovPermissionDialog().apply {
                this.onDismissCallback = onDismiss
                this.onLocationPermissionClick = onLocationPermission
                this.onBluetoothPermissionClick = onBluetoothPermission
                this.onBluetoothSwitchClick = onBluetoothSwitch
                this.onWifiPermissionClick = onWifiPermission
                this.showLocationPermission = showLocation
                this.showBluetoothPermission = showBluetoothPermission
                this.showWifiPermission = showWifi
            }
        }
    }

    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
        onDismissCallback?.invoke()
    }

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): CovPermissionDialogBinding {
        return CovPermissionDialogBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding?.apply {
            setOnApplyWindowInsets(root)
            
            // 设置关闭按钮点击事件
            btnClose.setOnClickListener {
                dismiss()
            }
            
            // 设置位置服务权限按钮点击事件
            btnLocationPermission.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onLocationPermissionClick?.invoke()
                    dismiss()
                }
            })
            
            // 设置蓝牙权限按钮点击事件
            btnBluetoothPermission.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onBluetoothPermissionClick?.invoke()
                    dismiss()
                }
            })

            // 设置蓝牙开关按钮点击事件
            btnBluetoothSwitch.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onBluetoothSwitchClick?.invoke()
                    dismiss()
                }
            })
            
            // 设置Wi-Fi权限按钮点击事件
            btnWifiPermission.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onWifiPermissionClick?.invoke()
                    dismiss()
                }
            })
            
            // 根据配置显示或隐藏权限项
            cvLocationPermission.visibility = if (showLocationPermission) View.VISIBLE else View.GONE
            cvBluetoothPermission.visibility = if (showBluetoothPermission) View.VISIBLE else View.GONE
            cvWifiPermission.visibility = if (showWifiPermission) View.VISIBLE else View.GONE
            cvBluetoothSwitch.visibility = if (bluetoothSwitchNeedOpen) View.VISIBLE else View.GONE
        }
        
        updatePermissionStatus()
    }

    override fun disableDragging(): Boolean {
        return true
    }
    
    /**
     * 更新位置权限状态
     * @param granted 是否已授予权限
     */
    fun updateLocationPermissionStatus(granted: Boolean) {
        locationPermissionGranted = granted
        updatePermissionStatus()
    }
    
    /**
     * 更新蓝牙权限状态
     * @param granted 是否已授予权限
     */
    fun updateBluetoothPermissionStatus(granted: Boolean) {
        bluetoothPermissionGranted = granted
        updatePermissionStatus()
    }
    
    /**
     * 更新Wi-Fi权限状态
     * @param granted 是否已授予权限
     */
    fun updateWifiPermissionStatus(granted: Boolean) {
        wifiPermissionGranted = granted
        updatePermissionStatus()
    }

    fun showBluetoothSwitch() {
        bluetoothSwitchNeedOpen = true
        updatePermissionStatus()
    }
    
    /**
     * 更新权限状态UI
     */
    private fun updatePermissionStatus() {
        binding?.apply {
            // 更新位置服务权限状态
            if (showLocationPermission) {
                if (locationPermissionGranted) {
                    cvLocationPermission.visibility = View.GONE
                } else {
                    cvLocationPermission.visibility = View.VISIBLE
                    btnLocationPermission.isEnabled = true
                }
            }
            
            // 更新蓝牙权限状态
            if (showBluetoothPermission) {
                if (bluetoothPermissionGranted) {
                    cvBluetoothPermission.visibility = View.GONE
                } else {
                    cvBluetoothPermission.visibility = View.VISIBLE
                    btnBluetoothPermission.isEnabled = true
                }
            }
            
            // 更新Wi-Fi权限状态
            if (showWifiPermission) {
                if (wifiPermissionGranted) {
                    cvWifiPermission.visibility = View.GONE
                } else {
                    cvWifiPermission.visibility = View.VISIBLE
                    btnWifiPermission.isEnabled = true
                }
            }

            // 检查是否所有显示的权限都已授予，如果是则自动关闭对话框
            val allGranted = (!showLocationPermission || locationPermissionGranted) && 
                             (!showBluetoothPermission || bluetoothPermissionGranted) &&
                             (!showWifiPermission || wifiPermissionGranted) &&
                             (!bluetoothSwitchNeedOpen)
            if (allGranted) {
                dismiss()
            }
        }
    }
} 
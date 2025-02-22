package io.agora.agent

import android.Manifest
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.fragment.app.FragmentTransaction
import io.agora.agent.databinding.ActivityMainBinding
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.ui.BaseActivity
import java.util.Locale
import android.annotation.SuppressLint
import android.app.Activity
import android.util.Log
import android.view.View
import android.webkit.CookieManager
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.core.os.LocaleListCompat
import androidx.appcompat.app.AppCompatDelegate
import io.agora.scene.common.AgentApp
import io.agora.scene.common.constant.AgentScenes
import io.agora.scene.common.constant.SSOUserManager
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.common.debugMode.DebugDialog
import io.agora.scene.common.debugMode.DebugConfigSettings
import io.agora.scene.common.debugMode.DebugButton
import io.agora.scene.common.debugMode.DebugDialogCallback
import io.agora.scene.common.net.TokenGenerator
import io.agora.scene.common.ui.LoginDialog
import io.agora.scene.common.ui.LoginDialogCallback
import io.agora.scene.common.ui.SSOWebViewActivity
import io.agora.scene.common.ui.TermsActivity
import io.agora.scene.common.ui.vm.LoginViewModel
import io.agora.scene.convoai.ui.CovLivingActivity

class MainActivity : BaseActivity<ActivityMainBinding>() {

    private val REQUEST_CODE = 100

    // Counter for debug mode activation
    private var counts = 0
    private val debugModeOpenTime: Long = 2000
    private var beginTime: Long = 0
    private var mDebugDialog: DebugDialog? = null
    private var mLoginDialog: LoginDialog? = null

    private lateinit var activityResultLauncher: ActivityResultLauncher<Intent>

    private val mLoginViewModel: LoginViewModel by viewModels()

    override fun getViewBinding(): ActivityMainBinding {
        return ActivityMainBinding.inflate(layoutInflater)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        DebugConfigSettings.init(this, BuildConfig.IS_MAINLAND)
        ServerConfig.initBuildConfig(
            BuildConfig.IS_MAINLAND,
            "",
            BuildConfig.TOOLBOX_SERVER_HOST,
            BuildConfig.AG_APP_ID,
            BuildConfig.AG_APP_CERTIFICATE
        )
        setupLocale()
        super.onCreate(savedInstanceState)
    }

    override fun initView() {
        setupView()
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            REQUEST_CODE
        )
        activityResultLauncher =
            registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
                if (result.resultCode == Activity.RESULT_OK) {
                    val data: Intent? = result.data
                    val token = data?.getStringExtra("token")
                    if (token != null) {
                        SSOUserManager.saveToken(token)
                        mLoginViewModel.getUserInfoByToken(token)
                    } else {
                        ToastUtil.show("Login error")
                    }
                }
            }

        val tempToken = SSOUserManager.getToken()
        if (tempToken.isNotEmpty()) {
            mLoginViewModel.getUserInfoByToken(tempToken)
        }

        mLoginViewModel.userInfoLiveData.observe(this) { userInfo ->
            if (userInfo != null) {
                goScene(AgentScenes.ConvoAi)
            } else {
                ToastUtil.show("获取用户信息失败")
            }
        }

        TokenGenerator.tokenErrorCompletion = {
            if (it != null) {
                SSOUserManager.logout()
                // TODO:
            }
        }
    }

    private fun goScene(scene: AgentScenes) {
        try {
            val intent = when (scene) {
                AgentScenes.ConvoAi -> Intent(this, CovLivingActivity::class.java)
                else -> Intent()
            }
            startActivity(intent)
            finish()
        } catch (e: Exception) {
            ToastUtil.show(getString(R.string.scenes_coming_soon))
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        setupLocale()
    }

    override fun onResume() {
        super.onResume()
        setupLocale()
        // Set debug callback when page is resumed
        DebugButton.setDebugCallback {
            showDebugDialog()
        }
    }

    override fun onPause() {
        super.onPause()
        // Clear debug callback when activity is paused
        DebugButton.setDebugCallback(null)
    }

    private fun setupView() {
        mBinding?.apply {
            setOnApplyWindowInsetsListener(root)
            // Set logo based on region
            if (ServerConfig.isMainlandVersion) {
                ivLogo.setImageResource(R.drawable.app_main_logo_cn)
                ivLogo.setColorFilter(Color.WHITE)
            } else {
                ivLogo.setImageResource(R.drawable.app_main_logo)
                ivLogo.clearColorFilter()
            }

            // Setup UI event listeners
            cbTerms.setOnCheckedChangeListener { _, _ ->
                updateStartButtonState()
            }
            tvTermsSelection.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onClickTermsDetail()
                }
            })
            tvGetStarted.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    showLoginDialog()
                }
            })
            tvSsoLogin.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onClickLoginSSO()
                }
            })

            // Debug mode activation with multiple taps
            ivIcon.setOnClickListener {
                if (DebugConfigSettings.isDebug) return@setOnClickListener
                if (counts == 0 || System.currentTimeMillis() - beginTime > debugModeOpenTime) {
                    beginTime = System.currentTimeMillis()
                    counts = 0
                }
                counts++
                if (counts > 7) {
                    counts = 0
                    DebugConfigSettings.enableDebugMode(true)
                    DebugButton.getInstance(AgentApp.instance()).show()
                    // Add callback setup here for first time activation
                    DebugButton.setDebugCallback {
                        showDebugDialog()
                    }
                    ToastUtil.show(getString(io.agora.scene.common.R.string.common_debug_mode_enable))
                }
            }
            updateStartButtonState()
        }
    }

    private fun updateStartButtonState() {
        mBinding?.apply {
            // Update start button opacity and enabled state based on terms acceptance
            if (cbTerms.isChecked) {
                tvGetStarted.alpha = 1f
                tvGetStarted.isEnabled = true
            } else {
                tvGetStarted.alpha = 0.6f
                tvGetStarted.isEnabled = false
            }
        }
    }

    private fun onClickTermsDetail() {
        val intent = Intent(this, TermsActivity::class.java)
        startActivity(intent)
    }

    private fun onClickGetStarted() {
        mBinding?.apply {
            if (!cbTerms.isChecked) {
                return
            }
            val fragmentTransaction: FragmentTransaction = supportFragmentManager.beginTransaction()
            fragmentTransaction.replace(R.id.fragment_container, SceneSelectionFragment())
            fragmentTransaction.commit()
        }
    }

    private fun onClickLoginSSO() {
        if (mBinding?.cbTerms?.isChecked == false) {
            return
        }
        clearCookies()
        activityResultLauncher.launch(Intent(this, SSOWebViewActivity::class.java))
    }

    private fun clearCookies() {
        val cookieManager = CookieManager.getInstance()
        cookieManager.removeAllCookies { success ->
            if (success) {
                Log.d("clearCookies", "Cookies successfully removed")
            } else {
                Log.d("clearCookies", "Failed to remove cookies")
            }
        }
        cookieManager.flush()
    }

    private fun setupLocale() {
        val lang = if (ServerConfig.isMainlandVersion) "zh" else "en"
        val locale = Locale(lang)

        AppCompatDelegate.setApplicationLocales(LocaleListCompat.create(locale))

        updateActivityLocale(locale)
    }

    @SuppressLint("ObsoleteSdkInt")
    private fun updateActivityLocale(locale: Locale) {
        Locale.setDefault(locale)

        val config = resources.configuration
        config.setLocale(locale)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            createConfigurationContext(config)
        } else {
            @Suppress("DEPRECATION")
            resources.updateConfiguration(config, resources.displayMetrics)
        }
    }

    private fun showDebugDialog() {
        if (!isFinishing && !isDestroyed) {  // Add safety check
            if (mDebugDialog?.dialog?.isShowing == true) return
            mDebugDialog = DebugDialog(AgentScenes.Common)
            mDebugDialog?.onDebugDialogCallback = object : DebugDialogCallback {
                override fun onDialogDismiss() {
                    mDebugDialog = null
                }
            }
            mDebugDialog?.show(supportFragmentManager, "mainDebugDialog")
        }
    }

    private fun showLoginDialog(){
        if (!isFinishing && !isDestroyed) {  // Add safety check
            mLoginDialog = LoginDialog().apply {
                onLoginDialogCallback = object : LoginDialogCallback{
                    override fun onDialogDismiss() {
                        mLoginDialog = null
                    }

                    override fun onClickStartSSO() {
                        onClickLoginSSO()
                    }

                    override fun onClickTerms() {
                        onClickTermsDetail()
                    }
                }
            }
            mLoginDialog?.show(supportFragmentManager, "mainDebugDialog")
        }
    }

    override fun onDestroy() {
        DebugButton.getInstance(AgentApp.instance()).hide()
        super.onDestroy()
    }
}
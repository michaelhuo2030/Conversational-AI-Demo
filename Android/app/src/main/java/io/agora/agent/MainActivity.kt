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
import android.view.View
import androidx.core.os.LocaleListCompat
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.view.isVisible
import io.agora.scene.common.constant.AgentKey
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.debug.CovDebugDialog
import io.agora.scene.convoai.rtc.CovRtcManager

class MainActivity : BaseActivity<ActivityMainBinding>() {

    private val REQUEST_CODE = 100

    private var counts = 0
    private val debugModeOpenTime: Long = 2000
    private var beginTime: Long = 0

    override fun getViewBinding(): ActivityMainBinding {
        return ActivityMainBinding.inflate(layoutInflater)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        val stagingKey = AgentKey(BuildConfig.AG_APP_ID,BuildConfig.AG_APP_CERTIFICATE)
        val devKey = AgentKey(BuildConfig.AG_APP_ID_DEV,BuildConfig.AG_APP_CERTIFICATE_DEV)
        ServerConfig.initConfig(BuildConfig.IS_MAINLAND,
            stagingKey = stagingKey,
            devKey = devKey)
        setupLocale()
        super.onCreate(savedInstanceState)
    }

    override fun initView() {
        setupView()
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.RECORD_AUDIO, Manifest.permission.WRITE_EXTERNAL_STORAGE),
            REQUEST_CODE
        )
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        setupLocale()
    }

    override fun onResume() {
        super.onResume()
        setupLocale()
    }

    private fun setupView() {
        mBinding?.apply {
            setOnApplyWindowInsetsListener(root)
            if (ServerConfig.isMainlandVersion) {
                ivLogo.setImageResource(R.drawable.app_main_logo_cn)
                ivLogo.setColorFilter(Color.WHITE)
            } else {
                ivLogo.setImageResource(R.drawable.app_main_logo)
                ivLogo.clearColorFilter()
            }
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
                    onClickGetStarted()
                }
            })
            ivIcon.setOnClickListener {
                if (ServerConfig.isDebug) return@setOnClickListener
                if (counts == 0 || System.currentTimeMillis() - beginTime > debugModeOpenTime) {
                    beginTime = System.currentTimeMillis()
                    counts = 0
                }
                counts++
                if (counts > 7) {
                    counts = 0
                    btnDebug.isVisible = true
                    ServerConfig.isDebug = true
                    ToastUtil.show(getString(io.agora.scene.common.R.string.common_debug_mode_enable))
                }
            }
            btnDebug.isVisible = ServerConfig.isDebug
            btnDebug.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    showDebugDialog()
                }
            })
            updateStartButtonState()
        }
    }

    private fun updateStartButtonState() {
        mBinding?.apply {
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

    private fun showDebugDialog(){
        val callback = object : CovDebugDialog.Callback {
            override fun onAudioDumpEnable(enable: Boolean) {
                CovRtcManager.onAudioDump(enable)
            }

            override fun onDebugEnable(enable: Boolean) {
                mBinding?.btnDebug?.isVisible =false
            }
        }
        val dialog = CovDebugDialog(callback)
        dialog.show(supportFragmentManager, "debugSettings")
    }
}
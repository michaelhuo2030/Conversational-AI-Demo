package io.agora.agent

import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.ui.BaseActivity
import java.util.Locale
import android.annotation.SuppressLint
import androidx.core.os.LocaleListCompat
import androidx.appcompat.app.AppCompatDelegate
import io.agora.agent.databinding.WelcomeActivityBinding
import io.agora.scene.common.constant.AgentScenes
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.common.debugMode.DebugConfigSettings
import io.agora.scene.convoai.ui.CovLivingActivity

class WelcomeActivity : BaseActivity<WelcomeActivityBinding>() {

    override fun getViewBinding(): WelcomeActivityBinding {
        return WelcomeActivityBinding.inflate(layoutInflater)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // 初始化配置要在 super.onCreate 之前
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
        goScene(AgentScenes.ConvoAi)
    }

    override fun initView() {
        setupView()
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
    }

    private fun setupView() {
        mBinding?.apply {
            setOnApplyWindowInsetsListener(root)
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
}
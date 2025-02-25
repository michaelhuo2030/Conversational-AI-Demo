package io.agora.agent

import android.annotation.SuppressLint
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.agora.agent.databinding.WelcomeActivityBinding
import io.agora.scene.common.constant.AgentScenes
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.debugMode.DebugConfigSettings
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.ui.CovLivingActivity
import java.util.Locale
import androidx.annotation.RequiresApi


class WelcomeActivity : BaseActivity<WelcomeActivityBinding>() {

    override fun getViewBinding(): WelcomeActivityBinding {
        return WelcomeActivityBinding.inflate(layoutInflater)
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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            handleSplashScreenExit()
        } else {
            goScene(AgentScenes.ConvoAi)
        }
        super.onCreate(savedInstanceState)
    }

    override fun immersiveMode(): ImmersiveMode {
        return ImmersiveMode.FULLY_IMMERSIVE
    }

    override fun initView() {
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

    private val SPLASH_DURATION = 300L

    @RequiresApi(Build.VERSION_CODES.S)
    private fun handleSplashScreenExit() {
        val splashScreen = installSplashScreen()
        var keepSplashOnScreen = true
        
        splashScreen.setOnExitAnimationListener { provider ->
            provider.iconView.animate()
                .alpha(0f)
                .setDuration(300L)
                .scaleX(1f)
                .scaleY(1f)
                .withEndAction {
                    provider.remove()
                    goScene(AgentScenes.ConvoAi)
                }.start()
        }
        
        val handler = android.os.Handler(mainLooper)
        handler.postDelayed({
            keepSplashOnScreen = false
        }, SPLASH_DURATION)
        
        splashScreen.setKeepOnScreenCondition { keepSplashOnScreen }
    }
}
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
import io.agora.scene.common.ui.OnFastClickListener

class MainActivity : BaseActivity<ActivityMainBinding>() {

    private val REQUEST_CODE = 100

    override fun getViewBinding(): ActivityMainBinding {
        return ActivityMainBinding.inflate(layoutInflater)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
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
}
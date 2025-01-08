package io.agora.agent

import android.Manifest
import android.content.Intent
import android.graphics.Color
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.view.LayoutInflater
import androidx.core.app.ActivityCompat
import androidx.fragment.app.FragmentTransaction
import io.agora.agent.databinding.ActivityMainBinding
import io.agora.agent.rtc.AgoraManager


class MainActivity : AppCompatActivity() {

    private val REQUEST_CODE = 100

    private val mViewBinding by lazy { ActivityMainBinding.inflate(LayoutInflater.from(this)) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(mViewBinding.root)
        setupView()
        if (AgoraManager.isMainlandVersion) {
            mViewBinding.ivLogo.setImageResource(R.drawable.app_main_logo_cn)
            mViewBinding.ivLogo.setColorFilter(Color.WHITE)
        } else {
            mViewBinding.ivLogo.setImageResource(R.drawable.app_main_logo)
            mViewBinding.ivLogo.clearColorFilter()
        }

        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.RECORD_AUDIO, Manifest.permission.WRITE_EXTERNAL_STORAGE),
            REQUEST_CODE
        )
    }

    private fun setupView() {
        mViewBinding.cbTerms.setOnCheckedChangeListener { _, _ ->
            updateStartButtonState()
        }
        mViewBinding.tvTermsSelection.setOnClickListener {
            onClickTermsDetail()
        }
        mViewBinding.tvGetStarted.setOnClickListener {
            onClickGetStarted()
        }
        updateStartButtonState()
    }

    private fun updateStartButtonState() {
        if (mViewBinding.cbTerms.isChecked) {
            mViewBinding.tvGetStarted.alpha = 1f
            mViewBinding.tvGetStarted.isEnabled = true
        } else {
            mViewBinding.tvGetStarted.alpha = 0.4f
            mViewBinding.tvGetStarted.isEnabled = false
        }
    }

    private fun onClickTermsDetail() {
        val intent = Intent(this, TermsActivity::class.java)
        startActivity(intent)
    }

    private fun onClickGetStarted() {
        if (!mViewBinding.cbTerms.isChecked) { return }
        val fragmentTransaction: FragmentTransaction = supportFragmentManager.beginTransaction()
        fragmentTransaction.replace(R.id.fragment_container, SceneSelectionFragment())
        fragmentTransaction.commit()
    }
}
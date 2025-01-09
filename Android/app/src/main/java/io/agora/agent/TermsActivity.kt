package io.agora.agent

import android.os.Bundle
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity
import io.agora.agent.databinding.ActivityTermsBinding
import io.agora.agent.rtc.AgoraManager

class TermsActivity : AppCompatActivity() {

    private lateinit var binding: ActivityTermsBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityTermsBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.webView.settings.javaScriptEnabled = true
        binding.webView.webViewClient = WebViewClient()
        val site = if (AgoraManager.isMainlandVersion) {
            "https://www.agora.io/en/terms-of-service/"
        } else {
            "https://www.agora.io/en/terms-of-service/"
        }
        binding.webView.loadUrl(site)
    }

    override fun onBackPressed() {
        if (binding.webView.canGoBack()) {
            binding.webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
}

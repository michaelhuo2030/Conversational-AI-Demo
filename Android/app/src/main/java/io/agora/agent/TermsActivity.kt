package io.agora.agent

import android.webkit.WebViewClient
import io.agora.agent.databinding.ActivityTermsBinding
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.ui.BaseActivity

class TermsActivity : BaseActivity<ActivityTermsBinding>() {

    private lateinit var binding: ActivityTermsBinding

    override fun getViewBinding(): ActivityTermsBinding {
        return  ActivityTermsBinding.inflate(layoutInflater)
    }

    override fun initView() {
        binding.webView.settings.javaScriptEnabled = true
        binding.webView.webViewClient = WebViewClient()
        binding.webView.loadUrl(ServerConfig.siteUrl)
    }

    override fun onHandleOnBackPressed() {
        if (binding.webView.canGoBack()) {
            binding.webView.goBack()
        } else {
            super.onHandleOnBackPressed()
        }
    }
}

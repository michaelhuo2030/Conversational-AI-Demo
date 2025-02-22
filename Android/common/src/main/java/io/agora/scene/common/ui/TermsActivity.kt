package io.agora.scene.common.ui

import android.webkit.WebChromeClient
import android.webkit.WebViewClient
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.databinding.CommonTermsActivityBinding

class TermsActivity : BaseActivity<CommonTermsActivityBinding>() {

    override fun getViewBinding(): CommonTermsActivityBinding {
        return  CommonTermsActivityBinding.inflate(layoutInflater)
    }

    override fun initView() {
        mBinding?.apply {
            setOnApplyWindowInsetsListener(root)
            ivBackIcon.setOnClickListener {
                onHandleOnBackPressed()
            }
            webView.settings.javaScriptEnabled = true
            webView.webViewClient = WebViewClient()
            webView.loadUrl(ServerConfig.siteUrl)

            webView.webChromeClient = object : WebChromeClient() {
                override fun onProgressChanged(view: android.webkit.WebView, newProgress: Int) {
                    super.onProgressChanged(view, newProgress)
                    progressBar.progress = newProgress
                    if (newProgress == 100) {
                        progressBar.visibility = android.view.View.GONE
                    } else {
                        progressBar.visibility = android.view.View.VISIBLE
                    }
                }
            }
        }
    }

    override fun onHandleOnBackPressed() {
        mBinding?.let {
            if (it.webView.canGoBack()) {
                it.webView.goBack()
            } else {
                super.onHandleOnBackPressed()
            }
        }
    }
}

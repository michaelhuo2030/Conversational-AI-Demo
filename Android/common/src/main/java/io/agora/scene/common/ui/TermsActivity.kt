package io.agora.scene.common.ui

import android.app.Activity
import android.content.Intent
import android.text.TextUtils
import android.view.ViewGroup
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.databinding.CommonTermsActivityBinding
import io.agora.scene.common.util.dp
import io.agora.scene.common.util.getStatusBarHeight
import retrofit2.http.Url

class TermsActivity : BaseActivity<CommonTermsActivityBinding>() {

    companion object {
        private const val URL_KEY = "url_key"

        fun startActivity(activity: Activity, url: String) {
            val intent = Intent(activity, TermsActivity::class.java).apply {
                putExtra(URL_KEY, url)
            }
            activity.startActivity(intent)
        }
    }

    override fun getViewBinding(): CommonTermsActivityBinding {
        return CommonTermsActivityBinding.inflate(layoutInflater)
    }

    override fun initView() {
        mBinding?.apply {
            val statusBarHeight = getStatusBarHeight() ?: 25.dp.toInt()
            val layoutParams = layoutTitle.layoutParams as ViewGroup.MarginLayoutParams
            layoutParams.topMargin = statusBarHeight
            layoutTitle.layoutParams = layoutParams

            ivBackIcon.setOnClickListener {
                onHandleOnBackPressed()
            }
            webView.settings.javaScriptEnabled = true
            webView.webViewClient = WebViewClient()


            intent.getStringExtra(URL_KEY)?.let {
                webView.loadUrl(it)
            }

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

                override fun onReceivedTitle(view: WebView, title: String) {
                    super.onReceivedTitle(view, title)
                    if (!TextUtils.isEmpty(title) && view.url?.contains(title) == false) {
                        mBinding?.tvTitle?.text = title
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

package io.agora.agent;

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.view.View
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.core.view.isVisible
import io.agora.agent.databinding.AppActivitySsoBinding
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.util.CommonLogger

class SSOWebViewActivity : BaseActivity<AppActivitySsoBinding>() {

    override fun getViewBinding(): AppActivitySsoBinding {
        return AppActivitySsoBinding.inflate(layoutInflater)
    }

    companion object {
        private const val TAG = "SSOWebViewActivity"
        const val EXTRA_URL: String = "url"
    }

    override fun initView() {
        mBinding?.apply {
            setOnApplyWindowInsetsListener(root)
            ivBackIcon.setOnClickListener {
                onHandleOnBackPressed()
            }
            webView.clearCache(true)
            webView.clearHistory()
            webView.settings.apply {
                setJavaScriptEnabled(true)
                useWideViewPort = false
                domStorageEnabled = true
                allowFileAccess = true
                databaseEnabled = true
                saveFormData = true
                loadWithOverviewMode = true
                setSupportZoom(false)
                defaultTextEncodingName = "UTF-8"
            }
            webView.setWebChromeClient(object : WebChromeClient() {
                override fun onProgressChanged(view: WebView, newProgress: Int) {
                    if (newProgress == 100) {
                        mBinding?.progressBar?.visibility = View.GONE
                    } else {
                        if (mBinding?.progressBar?.visibility == View.GONE) {
                            mBinding?.progressBar?.visibility = View.VISIBLE
                        }
                        mBinding?.progressBar?.progress = newProgress
                    }
                    super.onProgressChanged(view, newProgress)
                }
            })
            webView.webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    val url = request?.url.toString()

                    if (url.contains("v1/sso/callback") && !url.contains("redirect_uri")) {
                        CommonLogger.d(TAG, "start login url = $url")
                        viewEmpty.isVisible = true
                        return false
                    }
                    return super.shouldOverrideUrlLoading(view, request)
                }

                override fun onPageFinished(view: WebView, url: String) {
                    super.onPageFinished(view, url)
                    if (url.contains("v1/sso/callback") && !url.contains("redirect_uri")) {
                        CommonLogger.d(TAG, "onPageFinished url = $url")
                        injectJavaScript()
                    }
                }

                override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: WebResourceError?) {
                    super.onReceivedError(view, request, error)
                    mBinding?.viewEmpty?.isVisible = false
                    CommonLogger.e(TAG, "onReceivedError ${error?.description}")
                }
            }

            webView.addJavascriptInterface(WebAppInterface(this@SSOWebViewActivity), "Android")

            intent.getStringExtra(EXTRA_URL)?.let {
                mBinding?.webView?.loadUrl(it)
            }
        }
    }


    private fun injectJavaScript() {
        // Inject JavaScript code to retrieve JSON data
        val jsCode = """
        (function() {
             // Get the text content of the page
            var jsonResponse = document.body.innerText; // Assume JSON data is in the body of the page
             // Parse the JSON data
            try {
                var jsonData = JSON.parse(jsonResponse); // Parse it into a JSON object
                // Check if the code is 0
                if (jsonData.code === 0) {
                    // Call the Android interface and pass the token
                    Android.handleResponse(jsonData.data.token);
                } else {
                    // If the code is not 0, return the error message
                    Android.handleResponse("Error " + jsonData.msg);
                }
            } catch (e) {
                 // Handle JSON parsing errors
                Android.handleResponse("Error " + e.message);
            }
        })();
    """
        mBinding?.webView?.evaluateJavascript(jsCode, null)
    }

    inner class WebAppInterface(private val context: Context) {

        @JavascriptInterface
        fun handleResponse(response: String) {
            CommonLogger.d(TAG, "handleResponse = $response")
            // If it's a token, perform the corresponding action
            if (!response.startsWith("Error")) {
                // Process the token, e.g., save it to SharedPreferences
                // Here you can save the token or perform other actions
                setResult(Activity.RESULT_OK, Intent().putExtra("token", response))
                finish()
            } else {
                // Handle error messages
                mBinding?.viewEmpty?.isVisible = false
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
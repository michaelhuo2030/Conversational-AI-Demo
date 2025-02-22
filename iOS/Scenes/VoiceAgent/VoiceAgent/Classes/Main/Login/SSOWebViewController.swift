//
//  File.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/20.
//

import UIKit
import WebKit
import SVProgressHUD
import Common

class CustomNavigationView: UIView {
    var onBackButtonTapped: (() -> Void)?
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("ic_sso_back_icon"), for: .normal)
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 64)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        addSubview(backButton)
        addSubview(titleLabel)
        
        backButton.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(44)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-12)
        }
    }
    
    @objc private func backButtonTapped() {
        onBackButtonTapped?()
    }
    
    func setTitle(_ title: String?) {
        titleLabel.text = title
    }
}

@objc class SSOWebViewController: UIViewController {
    private lazy var naviBar: CustomNavigationView = {
        let view = CustomNavigationView()
        view.setTitle(ResourceManager.L10n.Conversation.appName)
        view.backgroundColor = .white
        view.onBackButtonTapped = { [weak self] in
            self?.dismiss(animated: true)
        }
        return view
    }()

    var urlString: String = ""
    
    private lazy var ssoWebView: WKWebView = {
        // Config WKWebView
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        // Register JavaScript callback
        userContentController.add(self, name: "handleResponse")
        configuration.userContentController = userContentController
        
        let view = WKWebView(frame: CGRectZero, configuration: configuration)
        view.navigationDelegate = self
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()
    
    var completionHandler: ((String?) -> Void)?
    
    lazy var emptyView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SVProgressHUD.setOffsetFromCenter(UIOffset(horizontal: 0, vertical: 0))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
        SVProgressHUD.setOffsetFromCenter(UIOffset(horizontal: 0, vertical: 180))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            ssoWebView.load(request)
        }
    }
    
    private func setupUI() {
        view.addSubview(naviBar)
        view.addSubview(ssoWebView)
        view.addSubview(emptyView)
        
        ssoWebView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(0)
            make.top.equalTo(naviBar.snp.bottom)
        }
        
        emptyView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(0)
            make.top.equalTo(naviBar.snp.bottom)
        }
        
        emptyView.isHidden = true

    }
    
    // MARK: - JavaScript Injection
    private func injectJavaScript() {
        let jsCode = """
        (function() {
            var jsonResponse = document.body.innerText;
            console.log('Raw Response:', jsonResponse);
            try {
                var jsonData = JSON.parse(jsonResponse);
                if (jsonData.code === 0) {
                    window.webkit.messageHandlers.handleResponse.postMessage({
                        token: jsonData.data.token,
                        error: null
                    });
                } else {
                    window.webkit.messageHandlers.handleResponse.postMessage({
                        token: null,
                        error: jsonData.msg
                    });
                }
            } catch (e) {
                window.webkit.messageHandlers.handleResponse.postMessage({
                    token: null,
                    error: e.message
                });
            }
        })();
        """
        
        ssoWebView.evaluateJavaScript(jsCode, completionHandler: nil)
    }
    
    @objc static func clearWebViewCache() {
        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: Date(timeIntervalSince1970: 0)
        ) { }
        
        let dataStore = URLCache.shared
        dataStore.removeAllCachedResponses()

        
        let cookieStorage = HTTPCookieStorage.shared
        for cookie in cookieStorage.cookies ?? [] {
            cookieStorage.deleteCookie(cookie)
        }
    }
}

// MARK: - WKNavigationDelegate
extension SSOWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        SVProgressHUD.show()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if url.absoluteString.contains("v1/convoai/sso/callback") && !url.absoluteString.contains("redirect_uri") {
                emptyView.isHidden = false
            }
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        SVProgressHUD.show(withStatus: error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        SVProgressHUD.dismiss()
        webView.evaluateJavaScript("document.title") { [weak self] (result, error) in
            if let title = result as? String {
                self?.naviBar.setTitle(title)
            }
        }
        injectJavaScript()
    }
}

// MARK: - WKScriptMessageHandler
extension SSOWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "handleResponse" {
            guard let dict = message.body as? [String: Any] else { return }
            
            if let token = dict["token"] as? String {
                completionHandler?(token)
            } else if let error = dict["error"] as? String {
                print("Error: \(error)")
                completionHandler?(nil)
            }
        }
    }
}

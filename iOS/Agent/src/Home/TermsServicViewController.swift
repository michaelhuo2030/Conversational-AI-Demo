//
//  TermsServicViewController.swift
//  VoiceAgent
//
//  Created by qinhui on 2024/12/25.
//

import UIKit
import WebKit
import Common

class TermsServiceWebViewController: UIViewController {
    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        return webView
    }()
    
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = PrimaryColors.c_0097d4
        return progress
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        loadWebContent()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    private func setupViews() {
        title = ResourceManager.L10n.Main.termsOfService
        view.backgroundColor = .white
        view.addSubview(webView)
        view.addSubview(progressView)
        
        webView.addObserver(self,
                           forKeyPath: "estimatedProgress",
                           options: .new,
                           context: nil)
    }
    
    private func setupConstraints() {
        progressView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(2)
        }
        
        webView.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private func loadWebContent() {
        if let url = URL(string: AppContext.shared.termsOfServiceUrl) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                             of object: Any?,
                             change: [NSKeyValueChangeKey : Any]?,
                             context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = webView.estimatedProgress >= 1
        }
    }
}

// MARK: - WKNavigationDelegate
extension TermsServiceWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
    }
}

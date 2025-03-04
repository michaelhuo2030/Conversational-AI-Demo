//
//  BaseViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/4.
//

import UIKit

class BaseViewController: UIViewController {
    
    // MARK: - Public Properties
    
    /// Controls whether the custom navigation bar is hidden, defaults to false
    var isNavigationBarHidden: Bool = false {
        didSet {
            navigationView.isHidden = isNavigationBarHidden
        }
    }
    
    /// The title displayed in the navigation bar
    var navigationTitle: String? {
        didSet {
            navigationView.title = navigationTitle
        }
    }
    
    // MARK: - Private Properties
    
    private lazy var navigationView: NavigationView = {
        let nav = NavigationView()
        nav.backgroundColor = UIColor.themColor(named: "ai_fill1")
        nav.titleColor = UIColor.themColor(named: "ai_icontext1")
        nav.titleFont = .systemFont(ofSize: 17, weight: .medium)
        nav.leftButtonTintColor = UIColor.themColor(named: "ai_icontext1")
        nav.rightButtonTintColor = UIColor.themColor(named: "ai_icontext1")
        nav.onLeftButtonTapped = { [weak self] in
            self?.navigationLeftButtonTapped()
        }
        nav.onRightButtonTapped = { [weak self] in
            self?.navigationRightButtonTapped()
        }
        return nav
    }()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupDefaultBackButton()
    }
    
    // MARK: - Private Methods
    
    private func setupNavigationBar() {
        view.backgroundColor = UIColor.themColor(named: "ai_fill1")
        view.addSubview(navigationView)
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }
    }
    
    private func setupDefaultBackButton() {
        // Show back button if not root view controller
        if navigationController?.viewControllers.count ?? 0 > 1 {
            navigationView.leftButtonImage = UIImage.ag_named("ic_base_back_icon")
        }
    }
    
    // MARK: - Protected Methods (Overridable)
    
    /// Sets the right button image in navigation bar
    func setRightButtonImage(_ image: UIImage?) {
        navigationView.rightButtonImage = image
    }
    
    /// Sets the left button image in navigation bar
    func setLeftButtonImage(_ image: UIImage?) {
        navigationView.leftButtonImage = image
    }
    
    /// Sets the background color of navigation bar
    func setNavigationBarBackgroundColor(_ color: UIColor) {
        navigationView.backgroundColor = color
    }
    
    /// Sets the title color in navigation bar
    func setTitleColor(_ color: UIColor) {
        navigationView.titleColor = color
    }
    
    /// Sets the tint color for both navigation buttons
    func setButtonsTintColor(_ color: UIColor) {
        navigationView.leftButtonTintColor = color
        navigationView.rightButtonTintColor = color
    }
    
    /// Left button tap handler, can be overridden by subclasses
    @objc func navigationLeftButtonTapped() {
        // Default implementation: pop or dismiss
        if navigationController?.viewControllers.count ?? 0 > 1 {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    /// Right button tap handler, can be overridden by subclasses
    @objc func navigationRightButtonTapped() {
        // Empty by default, implement in subclass
    }
}

// MARK: - Public Methods

extension BaseViewController {
    /// Hides the system navigation bar
    func hideSystemNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    /// Shows the system navigation bar
    func showSystemNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

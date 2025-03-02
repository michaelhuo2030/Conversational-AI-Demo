//
//  TabbarController.swift
//  Agent
//
//  Created by qinhui on 2024/12/10.
//

import Foundation
import UIKit

class TabbarController: UITabBarController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = .white
            tabBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
        } else {
            tabBar.backgroundColor = .white
        }
        tabBar.isTranslucent = false
    }
    
    func addChild(viewController: UIViewController, title: String, image: UIImage?, selectedImage: UIImage?) {
        viewController.title = title
        viewController.tabBarItem = UITabBarItem(title: title,
                                               image: image?.withRenderingMode(.alwaysOriginal),
                                               selectedImage: selectedImage?.withRenderingMode(.alwaysOriginal))
        
        let nav = UINavigationController(rootViewController: viewController)
        addChild(nav)
    }
    
    func setTabBarItemTextColor(selected: UIColor, normal: UIColor) {
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: normal
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: selected
        ]
        
        UITabBarItem.appearance().setTitleTextAttributes(normalAttributes, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(selectedAttributes, for: .selected)
    }
}

//
//  SearchDeviceViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/5.
//

import Foundation
import Common

class SearchDeviceViewController: BaseViewController {
    private lazy var searchAnimateView:RippleAnimationView = {
        let diameter = view.bounds.width
        let rippleFrame = CGRect(
            x: 0,
            y: view.bounds.height - diameter/2 + 20,
            width: diameter,
            height: diameter
        )
        
        let rippleView = RippleAnimationView(frame: rippleFrame)
        
        return rippleView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationTitle = "扫描附近设备"
        naviBar.backgroundColor = UIColor.themColor(named: "ai_fill2")
        view.backgroundColor = UIColor.themColor(named: "ai_fill2")
        view.clipsToBounds = true
        configUI()
    }
    
    private func configUI() {
        [searchAnimateView].forEach { view.addSubview($0) }
    }
}

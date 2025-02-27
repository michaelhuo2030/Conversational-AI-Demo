//
//  MainViewController.swift
//  Agent
//
//  Created by qinhui on 2024/12/10.
//

import UIKit
import VoiceAgent

class MainViewController: UIViewController {
    private lazy var flowLayout: UICollectionViewFlowLayout = {
       let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: (UIScreen.main.bounds.width - 40 - 15) * 0.5, height: 80)
        return flowLayout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(HomeContentViewCell.self, forCellWithReuseIdentifier: "HomeCell")
        collectionView.backgroundColor = .clear
        return collectionView
    }()
        
    private var dataArray: [HomeContentModel] = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
        dataArray = HomeModel.createData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let vc = ChatViewController()
        self.navigationController?.pushViewController(vc, animated: false)
    }

    private func setupUI() {
        view.backgroundColor = .white
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        view.addSubview(collectionView)
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeCell", for: indexPath) as! HomeContentViewCell
        let model = dataArray[indexPath.item]
        cell.setupData(model: model)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = dataArray[indexPath.item]
        if model.isEnable == false { return }
        
        switch model.type {
        case .voiceAgent:
//            VoiceAgentEntrance.voiceAgentScene(viewController: self)
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        CGSize(width: UIScreen.main.bounds.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)
    }
    
        
}

//
//  DeviceIntroductionViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/5.
//

import UIKit
import Common

class DeviceIntroductionViewController: BaseViewController {
    
    // MARK: - Model
    
    struct IntroductionStep {
        let image: UIImage?
        let title: String
        let description: String
    }
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .black
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private lazy var carouselCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
        collectionView.layer.cornerRadius = 20
        collectionView.register(IntroductionCarouselCell.self, forCellWithReuseIdentifier: "CarouselCell")
        return collectionView
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.pageIndicatorTintColor = UIColor.themColor(named: "ai_line2")
        pageControl.currentPageIndicatorTintColor = UIColor.themColor(named: "ai_brand_main6")
        pageControl.numberOfPages = steps.count
        pageControl.currentPage = 0
        return pageControl
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        
        let fullText = "按住配网按钮 3秒 进入配网状态"
        let attributedString = NSMutableAttributedString(string: fullText)
        
        attributedString.addAttribute(.foregroundColor, value: UIColor.themColor(named: "ai_icontext1"), range: NSRange(location: 0, length: fullText.count))
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 24, weight: .semibold), range: NSRange(location: 0, length: fullText.count))
        
        if let range = fullText.range(of: "3秒") {
            let nsRange = NSRange(range, in: fullText)
            attributedString.addAttribute(.foregroundColor, value: UIColor.themColor(named: "ai_green6"), range: nsRange)
        }
        
        label.attributedText = attributedString
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "配对过程中会请求下列权限和开关"
        return label
    }()
    
    private lazy var permissionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 30
        stackView.distribution = .fillEqually
        stackView.alignment = .top
        return stackView
    }()
    
    private lazy var checkButton: UIButton = {
        let button = UIButton(type: .custom)
        
        // Create button configuration
        var config = UIButton.Configuration.plain()
        config.image = UIImage.ag_named("ic_iot_uncheck_icon")
        config.title = "已完成上述操作"
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseForegroundColor = UIColor.themColor(named: "ai_icontext1")
        config.background.backgroundColor = .clear
        
        // Set font in configuration
        var container = AttributeContainer()
        container.font = .systemFont(ofSize: 14)
        config.attributedTitle = AttributedString("已完成上述操作", attributes: container)
        
        // Apply configuration
        button.configuration = config
        button.configurationUpdateHandler = { button in
            var config = button.configuration
            config?.image = button.isSelected ? 
                UIImage.ag_named("ic_iot_check_icon") : 
                UIImage.ag_named("ic_iot_uncheck_icon")
            button.configuration = config
        }
        
        button.addTarget(self, action: #selector(checkButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_fill1")
        
        // Add shadow
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 10
        
        // Add top corners radius
        let maskPath = UIBezierPath(
            roundedRect: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 148),
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 20, height: 20)
        )
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        view.layer.mask = maskLayer
        
        return view
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("下一步", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor.themColor(named: "ai_brand_main6")
        button.layer.cornerRadius = 8
        button.isEnabled = false
        button.alpha = 0.5
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    
    private var steps: [IntroductionStep] = [
        IntroductionStep(
            image: UIImage.ag_named("ic_iot_intro_1"),
            title: "连接电源",
            description: "将设备连接到电源并打开"
        ),
        IntroductionStep(
            image: UIImage.ag_named("ic_iot_intro_2"),
            title: "等待启动",
            description: "设备指示灯将亮起，等待其完成启动"
        ),
        IntroductionStep(
            image: UIImage.ag_named("ic_iot_intro_3"),
            title: "网络连接",
            description: "确保您的手机已连接到Wi-Fi网络"
        )
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationTitle = "配网"
        view.backgroundColor = .black
        naviBar.backgroundColor = .black
        setupUI()
        setupPermissions()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(bottomView)
        bottomView.addSubview(checkButton)
        bottomView.addSubview(nextButton)
        
        scrollView.addSubview(contentView)
        
        contentView.addSubview(carouselCollectionView)
        contentView.addSubview(pageControl)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(permissionsStackView)
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(naviBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(bottomView.snp.top)
        }
        
        bottomView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(0)
            make.height.equalTo(148)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(view)
        }
        
        carouselCollectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(30)
            make.height.equalTo(190)
        }
        
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(carouselCollectionView.snp.bottom).offset(-12)
            make.height.equalTo(20)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(pageControl.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(30)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(30)
        }
        
        permissionsStackView.snp.remakeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(30)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(0)
        }
        
        checkButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.centerX.equalToSuperview()
            make.height.equalTo(21)
        }
        
        nextButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(30)
            make.top.equalTo(checkButton.snp.bottom).offset(16)
            make.height.equalTo(50)
        }
    }
    
    private func setupPermissions() {
        // Location information
        let locationView = createPermissionView(
            icon: UIImage.ag_named("ic_iot_location_icon"),
            iconColor: UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0),
            title: "位置信息"
        )
        
        // Bluetooth
        let bluetoothView = createPermissionView(
            icon: UIImage.ag_named("ic_iot_bluetooth_icon"),
            iconColor: UIColor(red: 0.4, green: 0.5, blue: 1.0, alpha: 1.0),
            title: "蓝牙"
        )
        
        // Wi-Fi
        let wifiView = createPermissionView(
            icon: UIImage.ag_named("ic_iot_wifi_icon"),
            iconColor: UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0),
            title: "2.4G Wi-Fi"
        )
        
        permissionsStackView.addArrangedSubview(locationView)
        permissionsStackView.addArrangedSubview(bluetoothView)
        permissionsStackView.addArrangedSubview(wifiView)
    }
    
    private func createPermissionView(icon: UIImage?, iconColor: UIColor, title: String) -> UIView {
        let containerView = UIView()
        
        let iconBackground = UIView()
        iconBackground.backgroundColor = UIColor.themColor(named: "ai_fill2")
        iconBackground.layer.cornerRadius = 30
        
        let iconImageView = UIImageView()
        iconImageView.image = icon
        iconImageView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        titleLabel.textAlignment = .center
        
        containerView.addSubview(iconBackground)
        iconBackground.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        
        iconBackground.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 60, height: 60))
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconBackground.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        return containerView
    }
    
    // MARK: - Actions
    
    @objc private func checkButtonTapped() {
        checkButton.isSelected.toggle()
        nextButton.isEnabled = checkButton.isSelected
        nextButton.alpha = checkButton.isSelected ? 1.0 : 0.5
    }
    
    private func testPermissionView() {
        let permissions = [
            PermissionAlertViewController.Permission(
                icon: UIImage.ag_named("ic_iot_location_icon"),
                iconBackgroundColor: UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0),
                cardBackgroundColor: UIColor.themColor(named: "ai_green6"),
                title: "定位服务未授权",
                action: {
                    // Open Location Settings
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            ),
            PermissionAlertViewController.Permission(
                icon: UIImage.ag_named("ic_iot_bluetooth_icon"),
                iconBackgroundColor: UIColor(red: 0.4, green: 0.5, blue: 1.0, alpha: 1.0),
                cardBackgroundColor: UIColor.themColor(named: "ai_brand_main6"),
                title: "未开启蓝牙权限",
                action: {
                    // Open Bluetooth Settings
                    guard let bluetoothUrl = URL(string: "App-Prefs:root=Bluetooth") else { return }
                    if UIApplication.shared.canOpenURL(bluetoothUrl) {
                        UIApplication.shared.open(bluetoothUrl)
                    }
                }
            ),
            PermissionAlertViewController.Permission(
                icon: UIImage.ag_named("ic_iot_bluetooth_icon"),
                iconBackgroundColor: UIColor(red: 0.4, green: 0.5, blue: 1.0, alpha: 1.0),
                cardBackgroundColor: UIColor.themColor(named: "ai_brand_main6"),
                title: "打开蓝牙",
                action: {
                    // Open Bluetooth Settings
                    guard let bluetoothUrl = URL(string: "App-Prefs:root=Bluetooth") else { return }
                    if UIApplication.shared.canOpenURL(bluetoothUrl) {
                        UIApplication.shared.open(bluetoothUrl)
                    }
                }
            )
        ]

        let alertVC = PermissionAlertViewController(
            title: "开启权限和开关",
            description: "需要开启以下权限和开关，用于添加附近设备",
            permissions: permissions
        )
        present(alertVC, animated: false)
    }
    
    @objc private func nextButtonTapped() {
        // Handle next button tap
        let vc = SearchDeviceViewController()
        self.navigationController?.pushViewController(vc)
        
//        testPermissionView()
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension DeviceIntroductionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return steps.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CarouselCell", for: indexPath) as! IntroductionCarouselCell
        cell.configure(with: steps[indexPath.item].image)
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == carouselCollectionView {
            let pageWidth = scrollView.bounds.width
            let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
            pageControl.currentPage = currentPage
        }
    }
}

// MARK: - IntroductionCarouselCell

class IntroductionCarouselCell: UICollectionViewCell {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
    }
    
    func configure(with image: UIImage?) {
        imageView.image = image
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension DeviceIntroductionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
}

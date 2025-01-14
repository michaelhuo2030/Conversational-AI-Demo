//
//  AgentSceneViewController.swift
//  VoiceAgent
//
//  Created by qinhui on 2024/12/20.
//

import UIKit
import Common

// MARK: - Models
enum AgentItem: CaseIterable {
    case conversationalAI
//    case agoraV2V
//    case digitalHuman
//    
    var title: String {
        switch self {
        case .conversationalAI:
            return ResourceManager.L10n.Scene.aiCardTitle
//        case .agoraV2V:
//            return ResourceManager.L10n.Scene.v2vCardTitle
//        case .digitalHuman:
//            return ResourceManager.L10n.Scene.digCardTitle
        }
    }
    
    var description: String {
        switch self {
        case .conversationalAI:
            return ResourceManager.L10n.Scene.aiCardDes
//        case .agoraV2V:
//            return ResourceManager.L10n.Scene.v2vCardDes
//        case .digitalHuman:
//            return ResourceManager.L10n.Scene.digCardDes
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .conversationalAI:
            return UIImage.va_named("ic_con_ai_agent_icon")
//        case .agoraV2V:
//            return UIImage.va_named("ic_v2v_ai_agent_icon")
//        case .digitalHuman:
//            return UIImage.va_named("ic_digital_ai_agent_icon")
        }
    }
    
    var shouldShowMineContent: Bool {
        switch self {
//        case .digitalHuman:
//            return true
//        case .conversationalAI, .agoraV2V:
        case .conversationalAI:

            return false
        }
    }
}

// MARK: - AgentCardCell
class AgentCardCell: UITableViewCell {
    static let identifier = "AgentCardCell"
    private enum Constants {
        static let cornerRadius: CGFloat = 16
        static let iconSize: CGFloat = 72
        static let padding: CGFloat = 28
    }
    
    private lazy var cardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.borderColor = PrimaryColors.c_262626.cgColor
        view.layer.borderWidth = 1.0
        view.layer.masksToBounds = true
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = Constants.iconSize / 2
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20)
        label.textAlignment = .left
        label.textColor = PrimaryColors.c_fdfcfb
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .left
        label.textColor = PrimaryColors.c_ffffff_a
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(cardView)
        cardView.addSubview(iconImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(descriptionLabel)
    }
    
    private func setupConstraints() {
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20))
            make.height.equalTo(220)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.left.equalTo(Constants.padding)
            make.top.equalTo(Constants.padding)
            make.height.width.equalTo(Constants.iconSize)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.left.equalTo(Constants.padding)
            make.right.equalTo(-Constants.padding)
            make.bottom.equalTo(-Constants.padding)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(Constants.padding)
            make.right.equalTo(-Constants.padding)
            make.bottom.equalTo(descriptionLabel.snp.top).offset(-5)
        }
    }
    
    func configure(with item: AgentItem) {
        titleLabel.text = item.title
        descriptionLabel.text = item.description
        iconImageView.image = item.icon
    }
}

// MARK: - AgentSceneViewController
class AgentSceneViewController: UIViewController {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Scene.title
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = PrimaryColors.c_b3b3b3
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        tableView.register(AgentCardCell.self, forCellReuseIdentifier: AgentCardCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        view.backgroundColor = PrimaryColors.c_0a0a0a
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.addSubview(titleLabel)
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.centerX.equalToSuperview()
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private func handleItemSelected(_ item: AgentItem) {
        switch item {
        case .conversationalAI:
            let vc = PreparedToStartViewController()
            vc.showMineContent = item.shouldShowMineContent
            self.navigationController?.pushViewController(vc, animated: true)
//        case .agoraV2V:
//            print("Agora V2V selected")
//        case .digitalHuman:
//            print("Digital Human selected")
//            let vc = PreparedToStartViewController()
//            vc.showMineContent = item.shouldShowMineContent
//            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AgentSceneViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AgentItem.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AgentCardCell.identifier, for: indexPath) as! AgentCardCell
        let item = AgentItem.allCases[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = AgentItem.allCases[indexPath.row]
        handleItemSelected(item)
    }
}


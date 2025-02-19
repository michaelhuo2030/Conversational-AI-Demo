//
//  AgentSceneViewController.swift
//  VoiceAgent
//
//  Created by qinhui on 2024/12/20.
//

import UIKit
import Common
import VoiceAgent
import DigitalHuman

// MARK: - Models
struct AgentItem {
    var rawValue: Int
    var title: String
    var description: String
    var icon: UIImage?
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
        view.layer.borderColor = UIColor.themColor(named: "ai_line1").cgColor
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
        label.textColor = UIColor.themColor(named: "ai_icontext2")
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .left
        label.textColor = UIColor.themColor(named: "ai_icontext3")
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
        backgroundColor = UIColor(hex: 0x111111)
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
        label.textColor = UIColor.themColor(named: "ai_icontext4")
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
    
    var dataSource: [AgentItem] = [
        AgentItem(
            rawValue: 0,
            title: ResourceManager.L10n.Scene.aiCardTitle,
            description: ResourceManager.L10n.Scene.aiCardDes,
            icon: UIImage(named: "ic_con_ai_agent_icon")
        ),
//        AgentItem(
//            rawValue: 1,
//            title: ResourceManager.L10n.Scene.v2vCardTitle,
//            description: ResourceManager.L10n.Scene.v2vCardDes,
//            icon: UIImage(named: "ic_v2v_ai_agent_icon")
//        ),
//        AgentItem(
//            rawValue: 2,
//            title: ResourceManager.L10n.Scene.digCardTitle,
//            description: ResourceManager.L10n.Scene.digCardDes,
//            icon: UIImage(named: "ic_digital_ai_agent_icon")
//        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        view.backgroundColor = UIColor(hex: 0x111111)
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
        switch item.rawValue {
        case 0:
            VoiceAgentEntrance.voiceAgentScene(viewController: self)
        case 1:
            // Agora V2V selected
            print("Agora V2V selected")
        case 2:
            // Digital Human selected
            print("Digital Human selected")
             DigitalHumanContext.digitalHumanAgentScene(viewController: self)
        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AgentSceneViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AgentCardCell.identifier, for: indexPath) as! AgentCardCell
        let item = dataSource[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = dataSource[indexPath.row]
        handleItemSelected(item)
    }
}


// MARK: - Message Model

import Common
struct Message {
    var content: String
    let isUser: Bool
    var isCompleted: Bool
}

// MARK: - ChatMessageCell
class ChatMessageCell: UITableViewCell {
    static let identifier = "ChatMessageCell"
    
    // MARK: - UI Components
    private lazy var avatarView: UIView = {
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = PrimaryColors.c_ffffff
        return label
    }()
    
    private lazy var messageBubble: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        return view
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(avatarView)
        avatarView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(messageBubble)
        messageBubble.addSubview(messageLabel)
    }
    
    func configure(with message: Message) {
        if message.isUser {
            setupUserLayout()
            nameLabel.text = ResourceManager.L10n.Conversation.messageYou
            nameLabel.textColor = PrimaryColors.c_ffffff
            avatarImageView.image = UIImage.va_named("ic_agent_mine_avatar")
            messageLabel.textColor = PrimaryColors.c_ffffff
            messageBubble.backgroundColor = PrimaryColors.c_2b2b2b
        } else {
            setupAgentLayout()
            avatarView.backgroundColor = .clear
            avatarImageView.image = UIImage.va_named("ic_agent_avatar")
            nameLabel.text = ResourceManager.L10n.Conversation.messageAgentName
            nameLabel.textColor = PrimaryColors.c_ffffff
            messageLabel.textColor = PrimaryColors.c_b3b3b3
            messageBubble.backgroundColor = .clear
        }
        
        messageLabel.text = message.content
    }
    
    private func setupUserLayout() {
        nameLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-20)
        }
        
        avatarView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerY.equalTo(nameLabel)
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.right.equalTo(nameLabel.snp.left).offset(-6)
        }
        
        avatarImageView.snp.remakeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
        
        messageBubble.snp.remakeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(8)
            make.right.equalToSuperview().offset(-20)
            make.left.greaterThanOrEqualToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        messageLabel.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        }
    }
    
    private func setupAgentLayout() {
        avatarView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        avatarImageView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 15, height: 10))
        }
        
        nameLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(avatarView)
            make.left.equalTo(avatarView.snp.right).offset(4)
        }
        
        messageBubble.snp.remakeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(20)
            make.right.lessThanOrEqualToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        messageLabel.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 0, bottom: 12, right: 0))
        }
    }
}

// MARK: - ChatView
class ChatView: UIView {
    // MARK: - Properties
    private var messages: [Message] = []
    private var currentStreamMessage: String = ""
    
    var isEmpty: Bool {
        return messages.isEmpty
    }
    
    var isLastMessageFromUser: Bool {
        return messages.last?.isUser == true
    }
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.delegate = self
        table.dataSource = self
        table.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        return table
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        backgroundColor = UIColor(red: 0.09, green: 0.09, blue: 0.09, alpha: 1.0)
        layer.cornerRadius = 12
        addSubview(tableView)
    }
    
    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalTo(0)
            make.bottom.equalTo(-40)
        }
    }
    
    // MARK: - Public Methods
    func addMessage(_ message: String, isUser: Bool) {
        messages.append(Message(content: message, isUser: isUser, isCompleted: true))
        tableView.reloadData()
        scrollToBottom()
    }
    
    func addUserMessage(_ message: String) {
        messages.append(Message(content: message, isUser: true, isCompleted: true))
        tableView.reloadData()
        scrollToBottom()
    }
    
    func startNewStreamMessage() {
        currentStreamMessage = ""
        messages.append(Message(content: "", isUser: false, isCompleted: false))
        tableView.reloadData()
        scrollToBottom()
    }
    
    func updateStreamContent(_ text: String) {
        currentStreamMessage = text
        if var lastMessage = messages.last, !lastMessage.isUser {
            lastMessage.content = currentStreamMessage
            messages[messages.count - 1] = lastMessage
            tableView.reloadData()
            scrollToBottom(animated: true)
        }
    }
    
    func completeStreamMessage() {
        if var lastMessage = messages.last, !lastMessage.isUser {
            lastMessage.isCompleted = true
            lastMessage.content = currentStreamMessage
            messages[messages.count - 1] = lastMessage
            tableView.reloadData()
            scrollToBottom()
        }
        currentStreamMessage = ""
    }
    
    func clearMessages() {
        messages.removeAll()
        currentStreamMessage = ""
        tableView.reloadData()
    }
    
    private func scrollToBottom(animated: Bool = true) {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        DispatchQueue.main.async { [weak self] in
            self?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension ChatView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.identifier, for: indexPath) as! ChatMessageCell
        cell.configure(with: messages[indexPath.row])
        return cell
    }
} 


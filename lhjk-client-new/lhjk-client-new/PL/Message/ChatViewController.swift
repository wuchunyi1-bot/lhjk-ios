import UIKit

/// 聊天页面
final class ChatViewController: BaseViewController {

    // MARK: - Properties

    private let conversationId: String
    private var messages: [Message] = []

    // MARK: - UI Components

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "MessageCell")
        tv.delegate = self
        tv.dataSource = self
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private lazy var inputBar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "输入消息..."
        tf.borderStyle = .roundedRect
        tf.returnKeyType = .send
        tf.delegate = self
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("发送", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Initialization

    init(conversationId: String) {
        self.conversationId = conversationId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func setupUI() {
        title = "聊天"
        view.addSubview(tableView)
        view.addSubview(inputBar)
        inputBar.addSubview(textField)
        inputBar.addSubview(sendButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            textField.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 12),
            textField.topAnchor.constraint(equalTo: inputBar.topAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: inputBar.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            sendButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 50)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMessages()
    }

    // MARK: - Data Loading

    private func loadMessages() {
        messages = IMService.shared.getMessages(conversationId: conversationId)
        tableView.reloadData()
        scrollToBottom(animated: false)
    }

    // MARK: - Actions

    @objc private func sendMessage() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return
        }
        // TODO: 通过 IMService 发送文本消息
        textField.text = ""
        print("[IM] Sending message to \(conversationId): \(text)")
    }

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
}

// MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        let message = messages[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = message.content
        config.secondaryText = message.timestamp.formatted()
        cell.contentConfiguration = config
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChatViewController: UITableViewDelegate {}

// MARK: - UITextFieldDelegate

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}

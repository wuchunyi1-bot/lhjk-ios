import UIKit
import SnapKit

/// 聊天详情页 — 参考 funde-im ChatPanel.vue + MessageList.vue + Composer.vue
final class ChatViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    private let conversation: Conversation
    private var messages: [Message] = []

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg; tv.separatorStyle = .none; tv.showsVerticalScrollIndicator = false
        tv.dataSource = self; tv.delegate = self
        tv.register(MessageBubbleCell.self, forCellReuseIdentifier: MessageBubbleCell.reuseIdentifier)
        tv.register(NotificationCardCell.self, forCellReuseIdentifier: NotificationCardCell.reuseIdentifier)
        tv.register(SystemMessageCell.self, forCellReuseIdentifier: SystemMessageCell.reuseIdentifier)
        tv.keyboardDismissMode = .interactive
        return tv
    }()

    private lazy var inputBar: UIView = {
        let v = UIView(); v.backgroundColor = .fdSurface
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: -1)
        v.layer.shadowRadius = 3; v.layer.shadowOpacity = 0.04
        return v
    }()

    private lazy var toolButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        b.tintColor = .fdSubtext; b.addTarget(self, action: #selector(showToolSheet), for: .touchUpInside)
        return b
    }()

    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "输入消息..."; tf.font = .systemFont(ofSize: 15)
        tf.backgroundColor = .fdBg2; tf.layer.cornerRadius = 18
        tf.returnKeyType = .send; tf.delegate = self
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        return tf
    }()

    private lazy var sendButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("发送", for: .normal); b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        b.setTitleColor(.fdPrimary, for: .normal); b.setTitleColor(.fdMuted, for: .disabled)
        b.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        b.isEnabled = false
        return b
    }()

    private var inputBottomConstraint: Constraint?

    // MARK: - Init

    init(conversation: Conversation) {
        self.conversation = conversation
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = conversation.name
        view.backgroundColor = .fdBg

        [tableView, inputBar].forEach(view.addSubview)
        [toolButton, textField, sendButton].forEach(inputBar.addSubview)

        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        inputBar.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            inputBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
        }
        toolButton.snp.makeConstraints { $0.leading.equalToSuperview().offset(12); $0.centerY.equalToSuperview(); $0.size.equalTo(32) }
        textField.snp.makeConstraints { $0.leading.equalTo(toolButton.snp.trailing).offset(8); $0.top.equalToSuperview().offset(8); $0.height.equalTo(36) }
        sendButton.snp.makeConstraints { $0.leading.equalTo(textField.snp.trailing).offset(8); $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalTo(textField); $0.width.equalTo(44) }
        inputBar.snp.makeConstraints { $0.bottom.equalTo(textField.snp.bottom).offset(8) }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        loadMessages()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Data

    private func loadMessages() {
        messages = IMService.shared.getMessages(conversationId: conversation.id)
        IMService.shared.markAsRead(conversation.id)
        tableView.reloadData()
        DispatchQueue.main.async { self.scrollToBottom(animated: false) }
    }

    // MARK: - UITableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let msg = messages[indexPath.row]
        let timeStr = shouldShowTime(at: indexPath)

        switch msg.type {
        case .text:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MessageBubbleCell.reuseIdentifier, for: indexPath) as? MessageBubbleCell else {
                return UITableViewCell()
            }
            cell.configure(msg, showTime: timeStr)
            return cell

        case .notification:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCardCell.reuseIdentifier, for: indexPath) as? NotificationCardCell else {
                return UITableViewCell()
            }
            cell.configure(msg, showTime: timeStr)
            return cell

        case .system:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SystemMessageCell.reuseIdentifier, for: indexPath) as? SystemMessageCell else {
                return UITableViewCell()
            }
            cell.configure(msg)
            return cell

        default:
            return UITableViewCell()
        }
    }

    private func shouldShowTime(at indexPath: IndexPath) -> String? {
        let msg = messages[indexPath.row]
        let fmt = DateFormatter(); fmt.dateFormat = "MM-dd HH:mm"
        if indexPath.row == 0 { return fmt.string(from: msg.createdAt) }
        let prev = messages[indexPath.row - 1]
        if msg.createdAt.timeIntervalSince(prev.createdAt) > 300 { return fmt.string(from: msg.createdAt) }
        return nil
    }

    // MARK: - Actions

    @objc private func sendMessage() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        let msg = IMService.shared.sendMessage(text, conversationId: conversation.id)
        messages.append(msg)
        let idx = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [idx], with: .none)
        scrollToBottom(animated: true)
        textField.text = ""; updateSendButton()
    }

    @objc private func showToolSheet() {
        let sheet = UIAlertController(title: "选择工具", message: nil, preferredStyle: .actionSheet)
        let tools = ["图片", "拍照", "健康档案", "随访计划", "服务套餐", "用药提醒", "饮食建议", "运动处方", "预约挂号", "健康问卷", "在线问诊", "知识库", "转派工单"]
        for t in tools {
            sheet.addAction(UIAlertAction(title: t, style: .default) { _ in
                self.showToast(t)
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(sheet, animated: true)
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(_ n: Notification) {
        guard let kb = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        inputBottomConstraint?.update(offset: -kb.height + view.safeAreaInsets.bottom)
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
        scrollToBottom(animated: false)
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        inputBottomConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        DispatchQueue.main.async { self.updateSendButton() }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool { sendMessage(); return true }

    private func updateSendButton() {
        sendButton.isEnabled = !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    // MARK: - Helpers

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: animated)
    }

    private func showToast(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { alert.dismiss(animated: true) }
    }
}

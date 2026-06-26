import UIKit
import SnapKit

/// 聊天详情页 — 参考 funde-client ConversationDetailView.vue
final class ChatViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Properties

    private let conversationId: String
    private var conversation: Conversation?
    private var messages: [ChatMessage] = []
    private var inputBottomConstraint: Constraint?

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(TextBubbleCell.self, forCellReuseIdentifier: TextBubbleCell.reuseID)
        tv.register(SystemMessageCell.self, forCellReuseIdentifier: SystemMessageCell.reuseID)
        tv.register(ServiceCardCell.self, forCellReuseIdentifier: ServiceCardCell.reuseID)
        tv.register(MealAnalysisCell.self, forCellReuseIdentifier: MealAnalysisCell.reuseID)
        tv.register(AIWeeklyReportCell.self, forCellReuseIdentifier: AIWeeklyReportCell.reuseID)
        tv.keyboardDismissMode = .interactive
        return tv
    }()

    // Input bar
    private lazy var inputBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: -1)
        v.layer.shadowRadius = 3
        v.layer.shadowOpacity = 0.04
        return v
    }()

    private lazy var quickReplyScroll: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    private lazy var quickReplyStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        return s
    }()

    private lazy var toolBtns: [UIButton] = {
        ["doc.text", "chart.line.uptrend.xyaxis", "photo"].map { icon in
            let b = UIButton(type: .system)
            b.setImage(UIImage(systemName: icon), for: .normal)
            b.tintColor = .fdPrimary
            b.backgroundColor = .fdBg2
            b.layer.cornerRadius = 10
            b.snp.makeConstraints { $0.size.equalTo(32) }
            return b
        }
    }()

    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "发消息给..."
        tf.font = .fdBody
        tf.backgroundColor = UIColor(hexString: "#FFF8F5")
        tf.layer.cornerRadius = 18
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.fdBorder.cgColor
        tf.returnKeyType = .send
        tf.delegate = self
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 13, height: 0))
        tf.leftViewMode = .always
        tf.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        return tf
    }()

    private lazy var sendBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("发送", for: .normal)
        b.titleLabel?.font = .fdFont(ofSize: 13, weight: .bold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .fdPrimary
        b.layer.cornerRadius = 18
        b.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        b.isEnabled = false
        b.setTitleColor(.fdMuted, for: .disabled)
        return b
    }()

    // MARK: - Init

    init(conversationId: String) {
        self.conversationId = conversationId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        conversation = IMService.shared.getConversations().first { $0.id == conversationId }
        guard let conv = conversation else { return }

        title = conv.name

        // Input bar assembly
        let toolsRow = UIStackView(arrangedSubviews: toolBtns)
        toolsRow.axis = .horizontal
        toolsRow.spacing = 6

        let inputRow = UIStackView(arrangedSubviews: [toolsRow, textField, sendBtn])
        inputRow.axis = .horizontal
        inputRow.spacing = 8
        inputRow.alignment = .center

        quickReplyScroll.addSubview(quickReplyStack)
        quickReplyStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)) }
        quickReplyStack.snp.makeConstraints { $0.height.equalTo(quickReplyScroll) }

        let stack = UIStackView(arrangedSubviews: [quickReplyScroll, inputRow])
        stack.axis = .vertical
        stack.spacing = 8
        inputBar.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        [tableView, inputBar].forEach(view.addSubview)

        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        inputBar.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            inputBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
            make.bottom.equalTo(inputRow.snp.bottom).offset(max(8, view.safeAreaInsets.bottom))
        }

        sendBtn.snp.makeConstraints { $0.width.equalTo(56); $0.height.equalTo(36) }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        setupQuickReplies(for: conv)
        loadMessages()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Quick Replies

    private func setupQuickReplies(for conv: Conversation) {
        let replies: [String]
        switch conv.role {
        case .ai: replies = ["查看本周周报", "我的健康目标", "今日健康建议"]
        case .nutrition: replies = ["今天早餐怎么吃？", "帮我调整晚餐", "查看饮食方案"]
        case .doctor: replies = ["帮我看下指标", "用药需要调整吗", "预约复诊"]
        case .caseManager: replies = ["查看个案进度", "补充资料", "联系家属"]
        case .psychology: replies = ["开始放松练习", "记录睡眠", "预约咨询"]
        case .service: replies = ["查看预约", "改约时间", "联系服务台"]
        case .team: replies = ["同步今日指标", "请团队看一下", "查看本周目标"]
        default: replies = ["上传血压", "查看监测方案", "联系健管师"]
        }

        for r in replies {
            let btn = UIButton(type: .system)
            btn.setTitle(r, for: .normal)
            btn.titleLabel?.font = .fdFont(ofSize: 12)
            btn.setTitleColor(.fdSubtext, for: .normal)
            btn.backgroundColor = .fdSurface
            btn.layer.cornerRadius = 16
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.fdBorder.cgColor
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            btn.addTarget(self, action: #selector(quickReplyTapped(_:)), for: .touchUpInside)
            quickReplyStack.addArrangedSubview(btn)
        }
    }

    @objc private func quickReplyTapped(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }
        send(text: text)
    }

    // MARK: - Data

    private func loadMessages() {
        messages = IMService.shared.getMessages(conversationId: conversationId)
        tableView.reloadData()
        DispatchQueue.main.async { self.scrollToBottom(animated: false) }
    }

    // MARK: - UITableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let msg = messages[indexPath.row]

        switch msg.type {
        case .text:
            let cell = tableView.dequeueReusableCell(withIdentifier: TextBubbleCell.reuseID, for: indexPath) as! TextBubbleCell
            cell.configure(msg, tone: conversation?.role.toneHex ?? "#FF7A50", convRole: conversation?.role ?? .manager)
            return cell
        case .system:
            let cell = tableView.dequeueReusableCell(withIdentifier: SystemMessageCell.reuseID, for: indexPath) as! SystemMessageCell
            cell.configure(text: msg.text ?? "")
            return cell
        case .metricCard, .reportCard, .dietCard, .appointmentCard, .caseCard, .planCard:
            let cell = tableView.dequeueReusableCell(withIdentifier: ServiceCardCell.reuseID, for: indexPath) as! ServiceCardCell
            cell.configure(msg, tone: conversation?.role.toneHex ?? "#FF7A50")
            return cell
        case .mealAnalysis:
            let cell = tableView.dequeueReusableCell(withIdentifier: MealAnalysisCell.reuseID, for: indexPath) as! MealAnalysisCell
            cell.configure(msg)
            return cell
        case .aiWeeklyReport:
            let cell = tableView.dequeueReusableCell(withIdentifier: AIWeeklyReportCell.reuseID, for: indexPath) as! AIWeeklyReportCell
            cell.configure(msg)
            return cell
        }
    }

    // MARK: - Context Header

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let conv = conversation else { return nil }
        let header = UIView()
        header.backgroundColor = UIColor.white.withAlphaComponent(0.72)
        header.layer.cornerRadius = 12
        header.layer.borderWidth = 1
        header.layer.borderColor = UIColor.fdBorder.cgColor

        let titleLabel = UILabel()
        titleLabel.text = conv.title
        titleLabel.font = .fdFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = .fdText

        let descLabel = UILabel()
        descLabel.text = conv.serviceScope
        descLabel.font = .fdFont(ofSize: 12)
        descLabel.textColor = .fdSubtext

        let statusBadge = UILabel()
        statusBadge.text = conv.status
        statusBadge.font = .fdFont(ofSize: 10, weight: .bold)
        statusBadge.textColor = UIColor(hexString: conv.role.toneHex)
        statusBadge.backgroundColor = UIColor(hexString: conv.role.toneHex).withAlphaComponent(0.12)
        statusBadge.layer.cornerRadius = 8
        statusBadge.clipsToBounds = true
        statusBadge.textAlignment = .center

        [titleLabel, descLabel, statusBadge].forEach(header.addSubview)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(10)
        }
        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(titleLabel.snp.trailing).offset(6)
            make.trailing.lessThanOrEqualTo(statusBadge.snp.leading).offset(-8)
        }
        statusBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalTo(titleLabel)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(56)
        }
        // Move desc to second line
        descLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().offset(-10)
        }

        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    // MARK: - Actions

    @objc private func sendMessage() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        send(text: text)
        textField.text = ""
        updateSendBtn()
    }

    private func send(text: String) {
        let msg = IMService.shared.sendMessage(text, conversationId: conversationId)
        messages.append(msg)
        let idx = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [idx], with: .none)
        scrollToBottom(animated: true)
    }

    @objc private func textChanged() {
        updateSendBtn()
    }

    private func updateSendBtn() {
        let hasText = !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        sendBtn.isEnabled = hasText
        sendBtn.backgroundColor = hasText ? .fdPrimary : .fdBorder
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

    // MARK: - Helpers

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: animated)
    }
}

// MARK: - UITextFieldDelegate

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}

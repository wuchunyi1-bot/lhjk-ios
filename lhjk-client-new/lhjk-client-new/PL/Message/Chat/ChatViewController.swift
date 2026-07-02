import UIKit
import SnapKit
import Combine
import Kingfisher
import AVFoundation

/// 消息 Cell 长按回调协议
protocol ChatCellDelegate: AnyObject {
    func cellDidLongPress(_ cell: UITableViewCell, message: ChatMessage)
    func cellDidTapReply(_ cell: UITableViewCell, message: ChatMessage)
}

extension ChatCellDelegate {
    func cellDidTapReply(_ cell: UITableViewCell, message: ChatMessage) {}
}

/// 聊天详情页 — 参考 funde-client ConversationDetailView.vue
final class ChatViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ChatCellDelegate {

    // MARK: - Properties

    private let conversationId: String
    private var conversation: Conversation?
    private var messages: [ChatMessage] = []
    private var inputBottomConstraint: Constraint?
    private var cancellables = Set<AnyCancellable>()
    private var isLoadingMore = false
    private var hasMoreMessages = true
    private var lastTimestamp: Int64 = 0
    private var isVoiceMode = false
    private let audioRecorder = AudioRecorder()
    private var actionMenu: MessageActionMenu?
    private var quotePreviewBar: QuotePreviewBar?
    private var quotedMessage: ChatMessage?

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
        tv.register(ImageBubbleCell.self, forCellReuseIdentifier: ImageBubbleCell.reuseID)
        tv.register(FileBubbleCell.self, forCellReuseIdentifier: FileBubbleCell.reuseID)
        tv.register(VideoBubbleCell.self, forCellReuseIdentifier: VideoBubbleCell.reuseID)
        tv.register(SysNotifyCell.self, forCellReuseIdentifier: SysNotifyCell.reuseID)
        tv.register(CenteredTipCell.self, forCellReuseIdentifier: CenteredTipCell.reuseID)
        tv.register(VoiceBubbleCell.self, forCellReuseIdentifier: VoiceBubbleCell.reuseID)
        tv.keyboardDismissMode = .interactive
        tv.refreshControl = refreshControl
        return tv
    }()

    private let refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return rc
    }()

    // Input bar
    private lazy var inputBar: UIView = {
        let v = UIView()
        v.backgroundColor = .white
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
        let icons = ["doc.text", "mic.fill", "photo"]
        return icons.enumerated().map { idx, icon in
            let b = UIButton(type: .system)
            b.setImage(UIImage(systemName: icon), for: .normal)
            b.tintColor = .fdPrimary
            b.backgroundColor = .fdBg2
            b.layer.cornerRadius = 10
            b.snp.makeConstraints { $0.size.equalTo(32) }
            if idx == 1 {
                b.addTarget(self, action: #selector(toggleVoiceMode), for: .touchUpInside)
            } else if idx == 2 {
                b.addTarget(self, action: #selector(showImagePicker), for: .touchUpInside)
            }
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

    private lazy var voiceInputButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("按住 说话", for: .normal)
        b.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        b.setTitleColor(.fdText, for: .normal)
        b.backgroundColor = .fdSurface
        b.layer.cornerRadius = 18
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.fdBorder.cgColor
        b.isHidden = true
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleVoiceLongPress(_:)))
        longPress.minimumPressDuration = 0.1
        b.addGestureRecognizer(longPress)
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        RongCloudManager.shared.clearGroupUnreadCount(for: conversationId)
        IMService.shared.markAsRead(conversationId)
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

        let inputRow = UIStackView(arrangedSubviews: [toolsRow, textField, voiceInputButton, sendBtn])
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
        textField.snp.makeConstraints { $0.height.equalTo(36) }
        voiceInputButton.snp.makeConstraints { $0.height.equalTo(36) }

        // 底部安全区域填充白色，与 inputBar 颜色一致
        let safeAreaFill = UIView()
        safeAreaFill.backgroundColor = .white
        view.addSubview(safeAreaFill)
        safeAreaFill.snp.makeConstraints { make in
            make.top.equalTo(inputBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        setupQuickReplies(for: conv)
        setupRealtimeSubscription()
        loadMessages()
        print("[Chat] setupUI done — refreshControl=\(String(describing: tableView.refreshControl)) bounces=\(tableView.bounces) contentSize=\(tableView.contentSize)")
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

    // MARK: - Real-time Messages

    private func setupRealtimeSubscription() {
        // Combine 订阅：逐条追加新消息
        RongCloudManager.shared.messageReceivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                guard let self = self else { return }
                guard msg.conversationId == self.conversationId else { return }
                guard !self.messages.contains(where: { $0.id == msg.id }) else { return }
                self.messages.append(msg)
                UIView.performWithoutAnimation {
                    self.tableView.insertRows(at: [IndexPath(row: self.messages.count - 1, section: 0)], with: .none)
                }
                self.scrollToBottom(animated: false)
            }
            .store(in: &cancellables)

        // Delegate 回调：收到消息后全量刷新
        RongCloudMessageDelegate.shared.onMessageReceived = { [weak self] rcMsg in
            guard let self = self else { return }
            guard rcMsg.targetId == self.conversationId else { return }
            DispatchQueue.main.async {
                self.loadMessages()
            }
        }
    }

    // MARK: - Data

    private func loadMessages() {
        Task {
            let (msgs, timestamp, isRemaining) = await IMService.shared.loadMessages(conversationId: conversationId)
            print("[Chat] loadMessages count=\(msgs.count) timestamp=\(timestamp) isRemaining=\(isRemaining)")
            for msg in msgs {
                switch msg.type {
                case .text:
                    print("[Chat]   [text] id=\(msg.id) content=\(msg.text ?? "")")
                case .image:
                    print("[Chat]   [image] id=\(msg.id) imagePath=\(msg.imagePath ?? "nil")")
                case .voice:
                    print("[Chat]   [voice] id=\(msg.id) messageId=\(msg.messageId) imagePath=\(msg.imagePath ?? "nil")")
                default:
                    print("[Chat]   [\(msg.type.rawValue)] id=\(msg.id)")
                }
            }
            await MainActor.run {
                lastTimestamp = timestamp
                hasMoreMessages = isRemaining
                var list = msgs.isEmpty
                    ? IMService.shared.getMessages(conversationId: conversationId)
                    : msgs
                messages = insertTimeMarkers(list)
                tableView.reloadData()
                scrollToBottom(animated: false)
            }
        }
    }

    @objc private func handleRefresh() {
        print("[Chat] handleRefresh called — isLoadingMore=\(isLoadingMore) hasMoreMessages=\(hasMoreMessages) lastTimestamp=\(lastTimestamp) messages.count=\(messages.count)")
        guard !isLoadingMore, hasMoreMessages else {
            print("[Chat] handleRefresh ✗ blocked — isLoadingMore=\(isLoadingMore) hasMoreMessages=\(hasMoreMessages)")
            refreshControl.endRefreshing()
            return
        }
        isLoadingMore = true
        Task {
            let (olderMessages, newTimestamp, isRemaining) = await IMService.shared.loadOlderMessages(
                conversationId: conversationId,
                timestamp: lastTimestamp
            )
            print("[Chat] handleRefresh → loadOlderMessages returned \(olderMessages.count) messages, newTimestamp=\(newTimestamp) isRemaining=\(isRemaining)")
            await MainActor.run {
                lastTimestamp = newTimestamp
                hasMoreMessages = isRemaining
                if olderMessages.isEmpty {
                    print("[Chat] handleRefresh → no more messages")
                } else {
                    let existingIds = Set(messages.map { $0.id })
                    let newOlder = olderMessages.filter { !existingIds.contains($0.id) }
                    let raw = messages.filter { $0.type != .timeMarker } + newOlder
                    messages = insertTimeMarkers(raw.sorted { ($0.sentTime ?? Int64.max) < ($1.sentTime ?? Int64.max) })
                    tableView.reloadData()
                    let addedCount = messages.count - (raw.count - newOlder.count)
                    print("[Chat] handleRefresh ✓ loaded \(newOlder.count) new messages (deduped from \(olderMessages.count)), total now \(messages.count), scroll to row \(addedCount - 1)")
                    if addedCount > 0 {
                        tableView.scrollToRow(at: IndexPath(row: addedCount - 1, section: 0), at: .top, animated: false)
                    }
                }
                refreshControl.endRefreshing()
                isLoadingMore = false
            }
        }
    }

    /// 在消息列表中插入日期分隔标记
    /// 比较相邻消息的日期，跨天时在上方插入 `.timeMarker`
    private func insertTimeMarkers(_ list: [ChatMessage]) -> [ChatMessage] {
        guard !list.isEmpty else { return list }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var result: [ChatMessage] = []
        var lastDate: Date?

        for msg in list {
            // skip messages that already have a time (mock 数据 "今天 14:20") or parse sentTime
            guard let sentTime = parseMessageDate(msg) else {
                result.append(msg)
                continue
            }
            let msgDate = calendar.startOfDay(for: sentTime)

            if lastDate == nil || msgDate != lastDate {
                let dateText = formatDateMarker(msgDate, today: today, yesterday: yesterday, calendar: calendar)
                let marker = ChatMessage(
                    id: "marker-\(msg.id)",
                    type: .timeMarker,
                    role: .user,
                    senderName: nil, senderRole: nil, avatar: nil, portraitUrl: nil,
                    text: dateText, time: "", sentTime: nil,
                    card: nil, meal: nil, report: nil,
                    imagePath: nil, thumbWidth: nil, thumbHeight: nil,
                    conversationId: conversationId,
                    extra: nil, reply: nil, messageId: -1
                )
                result.append(marker)
            }
            result.append(msg)
            lastDate = msgDate
        }

        return result
    }

    /// 从 ChatMessage 的 time 字段解析 Date
    private func parseMessageDate(_ msg: ChatMessage) -> Date? {
        // 优先用 sentTime（融云消息）
        if let st = msg.sentTime, st > 0 {
            return Date(timeIntervalSince1970: TimeInterval(st) / 1000.0)
        }
        // fallback: 字符串格式
        guard !msg.time.isEmpty else { return Date() }
        let raw = msg.time
        if raw.hasPrefix("今天") {
            return parseTime(raw.replacingOccurrences(of: "今天 ", with: ""), baseDate: Date())
        }
        if raw.hasPrefix("昨天") {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            return parseTime(raw.replacingOccurrences(of: "昨天 ", with: ""), baseDate: yesterday)
        }
        return parseTime(raw, baseDate: Date())
    }

    private func parseTime(_ timeStr: String, baseDate: Date) -> Date? {
        let parts = timeStr.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate)
    }

    /// 日期格式：今天 / 昨天 / MM-dd / yyyy-MM-dd
    private func formatDateMarker(_ date: Date, today: Date, yesterday: Date, calendar: Calendar) -> String {
        if calendar.isDate(date, inSameDayAs: today) {
            return "今天"
        }
        if calendar.isDate(date, inSameDayAs: yesterday) {
            return "昨天"
        }
        let fmt = DateFormatter()
        let year = calendar.component(.year, from: date)
        let thisYear = calendar.component(.year, from: Date())
        if year == thisYear {
            fmt.dateFormat = "MM-dd"
        } else {
            fmt.dateFormat = "yyyy-MM-dd"
        }
        return fmt.string(from: date)
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
            cell.delegate = self
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
        case .image:
            print("[Chat] cellForRow image: id=\(msg.id) imagePath=\(msg.imagePath ?? "nil")")
            let cell = tableView.dequeueReusableCell(withIdentifier: ImageBubbleCell.reuseID, for: indexPath) as! ImageBubbleCell
            cell.delegate = self
            cell.configure(msg, tone: conversation?.role.toneHex ?? "#FF7A50", convRole: conversation?.role ?? .manager)
            cell.onTapImage = { [weak self] path in
                self?.showImagePreview(path: path)
            }
            return cell
        case .file:
            let cell = tableView.dequeueReusableCell(withIdentifier: FileBubbleCell.reuseID, for: indexPath) as! FileBubbleCell
            cell.delegate = self
            cell.configure(msg, tone: conversation?.role.toneHex ?? "#FF7A50", convRole: conversation?.role ?? .manager)
            return cell
        case .video:
            let cell = tableView.dequeueReusableCell(withIdentifier: VideoBubbleCell.reuseID, for: indexPath) as! VideoBubbleCell
            cell.delegate = self
            cell.configure(msg, tone: conversation?.role.toneHex ?? "#FF7A50", convRole: conversation?.role ?? .manager)
            return cell
        case .sysNotify:
            let cell = tableView.dequeueReusableCell(withIdentifier: SysNotifyCell.reuseID, for: indexPath) as! SysNotifyCell
            cell.delegate = self
            cell.configure(msg, tone: conversation?.role.toneHex ?? "#FF7A50", convRole: conversation?.role ?? .manager)
            return cell
        case .timeMarker, .recall:
            let cell = tableView.dequeueReusableCell(withIdentifier: CenteredTipCell.reuseID, for: indexPath) as! CenteredTipCell
            cell.configure(text: msg.text ?? "")
            return cell
        case .voice:
            let cell = tableView.dequeueReusableCell(withIdentifier: VoiceBubbleCell.reuseID, for: indexPath) as! VoiceBubbleCell
            cell.delegate = self
            cell.configure(msg, tone: conversation?.role.toneHex ?? "#FF7A50", convRole: conversation?.role ?? .manager)
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
        // 先乐观展示本地消息
        let localMsg = ChatMessage(
            id: "local-\(Int(Date().timeIntervalSince1970 * 1000))",
            type: .text,
            role: .user,
            senderName: nil,
            senderRole: nil,
            avatar: nil,
            portraitUrl: nil,
            text: text,
            time: "刚刚",
            sentTime: nil,
            card: nil,
            meal: nil,
            report: nil,
            imagePath: nil,
            thumbWidth: nil,
            thumbHeight: nil,
            conversationId: conversationId,
            extra: nil,
            reply: nil,
            messageId: -1
        )
        messages.append(localMsg)
        UIView.performWithoutAnimation {
            tableView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .none)
        }
        scrollToBottom(animated: false)

        // 异步发送到融云
        Task {
            let reply = quotedMessage.flatMap { ReplyMessage.from($0) }
            let sentMsg = await IMService.shared.sendMessage(text, conversationId: conversationId, replyMessage: reply)
            await MainActor.run {
                self.dismissQuote()
                if let sentMsg = sentMsg, let localIdx = self.messages.firstIndex(where: { $0.id == localMsg.id }) {
                    self.messages[localIdx] = sentMsg
                    self.tableView.reloadRows(at: [IndexPath(row: localIdx, section: 0)], with: .none)
                }
            }
        }
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

    // MARK: - Voice

    @objc private func toggleVoiceMode() {
        isVoiceMode.toggle()
        textField.isHidden = isVoiceMode
        sendBtn.isHidden = isVoiceMode
        voiceInputButton.isHidden = !isVoiceMode
        if isVoiceMode {
            textField.resignFirstResponder()
        }
    }

    @objc private func handleVoiceLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: voiceInputButton)
        let isCancelled = location.y < -60

        switch gesture.state {
        case .began:
            guard awaitPermission() else { return }
            voiceInputButton.setTitle("松开 发送", for: .normal)
            voiceInputButton.backgroundColor = UIColor(hexString: "#FF7A50").withAlphaComponent(0.15)
            let fm = MediaFileManager()
            let url = URL(fileURLWithPath: fm.basePath(.temp) + "/voice_\(Int(Date().timeIntervalSince1970)).wav")
            try? audioRecorder.startRecording(to: url)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

        case .changed:
            if isCancelled {
                voiceInputButton.setTitle("松开 取消", for: .normal)
                voiceInputButton.backgroundColor = UIColor.red.withAlphaComponent(0.1)
            } else {
                voiceInputButton.setTitle("松开 发送", for: .normal)
                voiceInputButton.backgroundColor = UIColor(hexString: "#FF7A50").withAlphaComponent(0.15)
            }

        case .ended:
            voiceInputButton.setTitle("按住 说话", for: .normal)
            voiceInputButton.backgroundColor = .fdSurface

            if isCancelled {
                audioRecorder.cancelRecording()
            } else {
                guard audioRecorder.isRecording || audioRecorder.isPaused else { break }
                let duration = Int(audioRecorder.currentDuration)
                guard duration >= 1, let url = audioRecorder.stopRecording() else {
                    // 录音太短，静默处理
                    break
                }
                let localPath = url.path
                Task {
                    let reply = quotedMessage.flatMap { ReplyMessage.from($0) }
                    let sent = await IMService.shared.sendVoice(
                        localPath: localPath,
                        duration: duration,
                        conversationId: conversationId,
                        replyMessage: reply
                    )
                    await MainActor.run {
                        self.dismissQuote()
                        if let sent,
                           let localIdx = self.messages.firstIndex(where: { $0.type == .voice && $0.imagePath == localPath }) {
                            self.messages[localIdx] = sent
                            self.tableView.reloadRows(at: [IndexPath(row: localIdx, section: 0)], with: .none)
                        }
                    }
                }
            }

        case .cancelled, .failed:
            voiceInputButton.setTitle("按住 说话", for: .normal)
            voiceInputButton.backgroundColor = .fdSurface
            audioRecorder.cancelRecording()

        default: break
        }
    }

    private func awaitPermission() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var granted = false
        Task {
            granted = await audioRecorder.requestPermission()
            semaphore.signal()
        }
        semaphore.wait()
        return granted
    }

    // MARK: - Long Press Menu

    func cellDidLongPress(_ cell: UITableViewCell, message: ChatMessage) {
        // 关闭已有菜单
        actionMenu?.dismiss()

        // 构建可见按钮列表
        var actions: [MessageActionMenu.Action] = []
        if message.canCopy { actions.append(.copy) }
        if message.canRecall { actions.append(.recall) }
        if message.canQuote { actions.append(.quote) }
        guard !actions.isEmpty else { return }

        let cellRect = cell.convert(cell.bounds, to: view)
        let menu = MessageActionMenu()
        menu.onAction = { [weak self] action in
            self?.handleAction(action, message: message)
        }
        menu.configure(above: cellRect, in: view, actions: actions)
        view.addSubview(menu)
        actionMenu = menu
    }

    private func handleAction(_ action: MessageActionMenu.Action, message: ChatMessage) {
        actionMenu?.dismiss()
        switch action {
        case .copy:   handleCopy(message)
        case .recall: handleRecall(message)
        case .quote:  handleQuote(message)
        }
    }

    private func handleCopy(_ message: ChatMessage) {
        UIPasteboard.general.string = message.text
        showToast("已复制")
    }

    private func handleRecall(_ message: ChatMessage) {
        let alert = UIAlertController(title: "撤回消息", message: "确定撤回这条消息吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "撤回", style: .default) { [weak self] _ in
            self?.performRecall(message)
        })
        present(alert, animated: true)
    }

    private func performRecall(_ message: ChatMessage) {
        guard let msgId = Int(message.id) else { return }
        Task {
            let success = await IMService.shared.recallMessage(msgId)
            await MainActor.run {
                if success {
                    self.replaceMessageWithRecall(message)
                    self.showToast("已撤回")
                } else {
                    self.showToast("撤回失败，请重试")
                }
            }
        }
    }

    private func replaceMessageWithRecall(_ message: ChatMessage) {
        guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return }
        let recalMsg = ChatMessage(
            id: message.id,
            type: .recall,
            role: .user,
            senderName: nil, senderRole: nil, avatar: nil, portraitUrl: nil,
            text: "你撤回了一条消息",
            time: message.time,
            sentTime: message.sentTime,
            card: nil, meal: nil, report: nil,
            imagePath: nil, thumbWidth: nil, thumbHeight: nil,
            conversationId: message.conversationId,
            extra: nil, reply: nil, messageId: message.messageId
        )
        messages[idx] = recalMsg
        tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .fade)
    }

    private func handleQuote(_ message: ChatMessage) {
        quotedMessage = message
        showQuotePreview(for: ReplyMessage.from(message))
    }

    private func showQuotePreview(for reply: ReplyMessage) {
        quotePreviewBar?.removeFromSuperview()
        let bar = QuotePreviewBar()
        bar.configure(with: reply)
        bar.onDismiss = { [weak self] in
            self?.dismissQuote()
        }
        bar.onTap = { [weak self] in
            self?.handleQuotePreviewTap(reply: reply)
        }
        view.insertSubview(bar, belowSubview: inputBar)
        bar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputBar.snp.top)
            make.height.equalTo(52)
        }
        quotePreviewBar = bar
    }

    private func dismissQuote() {
        quotedMessage = nil
        quotePreviewBar?.dismiss()
        quotePreviewBar = nil
    }

    /// 点击 QuotePreviewBar 的引用内容区域
    private func handleQuotePreviewTap(reply: ReplyMessage) {
        if reply.isImage {
            showImagePreview(path: reply.text)
        } else if reply.isVoice {
            playVoice(urlPath: reply.text)
        } else if reply.isVideo {
            showToast("视频播放")
        }
    }

    /// 点击消息气泡内的引用区（replyView）
    func cellDidTapReply(_ cell: UITableViewCell, message: ChatMessage) {
        guard let reply = message.reply else { return }
        if reply.isImage {
            showImagePreview(path: reply.text)
        } else if reply.isVoice {
            playVoice(urlPath: reply.text)
        } else if reply.isVideo {
            showToast("视频播放")
        }
    }

    /// 播放语音（下载后 AVAudioPlayer 播放）
    private func playVoice(urlPath: String) {
        // 本地文件直接播
        if urlPath.hasPrefix("/"), FileManager.default.fileExists(atPath: urlPath) {
            playAudioFile(url: URL(fileURLWithPath: urlPath))
            return
        }
        // 远程 URL 先下载
        guard let remoteURL = URL(string: urlPath) else { return }
        showToast("正在加载语音...")
        Task {
            let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
            await MainActor.run {
                playAudioFile(url: tempURL)
            }
        }
    }

    private func playAudioFile(url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
        } catch {
            print("[Chat] playVoice ✗ error: \(error.localizedDescription)")
            showToast("语音播放失败")
        }
    }

    @objc private func dismissActionMenu() {
        actionMenu?.dismiss()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        actionMenu?.dismiss()
    }

    // MARK: - Helpers

    private func showToast(_ message: String) {
        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        container.layer.cornerRadius = 8
        container.clipsToBounds = true
        let label = UILabel()
        label.text = message
        label.font = .fdFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
        }
        UIView.animate(withDuration: 0.3, delay: 1.5, options: [], animations: {
            container.alpha = 0
        }) { _ in
            container.removeFromSuperview()
        }
    }

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

// MARK: - UIImagePickerController

extension ChatViewController {

    @objc private func showImagePicker() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "拍照", style: .default) { [weak self] _ in
            self?.openCamera()
        })
        sheet.addAction(UIAlertAction(title: "从相册选择", style: .default) { [weak self] _ in
            self?.openPhotoLibrary()
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(sheet, animated: true)
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("[Chat] Camera not available")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    private func openPhotoLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = (info[.originalImage] ?? info[.editedImage]) as? UIImage else { return }
        sendImage(image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func sendImage(_ image: UIImage) {
        // 乐观展示本地图片气泡
        let localPath = saveImageToTemp(image)
        let localMsg = ChatMessage(
            id: "local-img-\(Int(Date().timeIntervalSince1970 * 1000))",
            type: .image,
            role: .user,
            senderName: nil,
            senderRole: nil,
            avatar: nil,
            portraitUrl: nil,
            text: nil,
            time: "刚刚",
            sentTime: nil,
            card: nil,
            meal: nil,
            report: nil,
            imagePath: localPath,
            thumbWidth: Int(image.size.width),
            thumbHeight: Int(image.size.height),
            conversationId: conversationId,
            extra: nil,
            reply: nil,
            messageId: -1
        )
        messages.append(localMsg)
        UIView.performWithoutAnimation {
            tableView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .none)
        }
        scrollToBottom(animated: false)

        // 异步发送到融云
        Task {
            let reply = quotedMessage.flatMap { ReplyMessage.from($0) }
            let sentMsg = await IMService.shared.sendImage(image, conversationId: conversationId, replyMessage: reply)
            await MainActor.run {
                self.dismissQuote()
                if let sentMsg = sentMsg,
                   let localIdx = self.messages.firstIndex(where: { $0.id == localMsg.id }) {
                    self.messages[localIdx] = sentMsg
                    self.tableView.reloadRows(at: [IndexPath(row: localIdx, section: 0)], with: .none)
                }
            }
        }
    }

    private func saveImageToTemp(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let path = NSTemporaryDirectory() + "rc_img_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        try? data.write(to: URL(fileURLWithPath: path))
        return path
    }

    private func showImagePreview(path: String?) {
        guard let path = path else { return }
        let previewVC = ImagePreviewViewController(imagePath: path)
        previewVC.modalPresentationStyle = .fullScreen
        present(previewVC, animated: true)
    }
}

// MARK: - Image Preview

/// 全屏图片预览
private final class ImagePreviewViewController: UIViewController, UIScrollViewDelegate {

    private let imagePath: String
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let closeBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        b.tintColor = .white
        b.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        b.layer.cornerRadius = 16
        return b
    }()

    init(imagePath: String) {
        self.imagePath = imagePath
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never

        imageView.contentMode = .scaleAspectFit

        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(closeBtn)

        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        closeBtn.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(32)
        }

        closeBtn.addTarget(self, action: #selector(dismissPreview), for: .touchUpInside)
        loadImage()
    }

    private func layoutImageView(_ image: UIImage) {
        let viewSize = view.bounds.size
        let imgSize = image.size
        guard viewSize.width > 0, imgSize.width > 0 else { return }

        let ratio = min(viewSize.width / imgSize.width, viewSize.height / imgSize.height)
        let displayW = imgSize.width * ratio
        let displayH = imgSize.height * ratio

        imageView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(displayW)
            make.height.equalTo(displayH)
        }
    }

    private func loadImage() {
        if imagePath.hasPrefix("/") {
            if let img = UIImage(contentsOfFile: imagePath) {
                imageView.image = img
                layoutImageView(img)
            }
        } else if let url = URL(string: imagePath) {
            // Kingfisher 优先读缓存，无缓存则下载并缓存
            imageView.kf.setImage(with: url, options: [
                .transition(.fade(0.3)),
                .cacheOriginalImage
            ]) { [weak self] result in
                guard let self = self else { return }
                if case .success(let value) = result {
                    self.layoutImageView(value.image)
                }
            }
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
    }

    @objc private func dismissPreview() {
        dismiss(animated: true)
    }
}

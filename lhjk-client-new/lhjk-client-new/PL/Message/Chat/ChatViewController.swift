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

    // MARK: - ViewModel

    private let viewModel: ChatViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI State

    private var inputBottomConstraint: Constraint?
    private var isVoiceMode = false
    private let audioRecorder = AudioRecorder()
    private var actionMenu: MessageActionMenu?
    private var quotePreviewBar: QuotePreviewBar?

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
        self.viewModel = ChatViewModel(conversationId: conversationId)
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
        viewModel.markAsRead()
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = viewModel.conversation?.name

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

        setupQuickReplyButtons()
        loadMessages()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - ViewModel Binding

    override func bindViewModel() {
        // 消息列表变更 → 刷新 TableView + 滚动至底
        viewModel.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        // Toast 提示
        viewModel.toastPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.showToast(msg)
            }
            .store(in: &cancellables)

        // 图片预览
        viewModel.presentImagePreviewPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] path in
                self?.showImagePreview(path: path)
            }
            .store(in: &cancellables)

        // 语音播放
        viewModel.playVoicePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] path in
                self?.playVoice(urlPath: path)
            }
            .store(in: &cancellables)

        // 引用预览
        viewModel.showQuotePreviewPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reply in
                self?.showQuotePreview(for: reply)
            }
            .store(in: &cancellables)

        // 滚动至底
        viewModel.scrollToBottomPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] animated in
                self?.scrollToBottom(animated: animated)
            }
            .store(in: &cancellables)
    }

    // MARK: - Quick Replies (UI)

    private func setupQuickReplyButtons() {
        for r in viewModel.quickReplies() {
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
        viewModel.sendText(text)
    }

    // MARK: - Data Loading

    private func loadMessages() {
        Task {
            await viewModel.loadMessages()
            await MainActor.run {
                self.scrollToBottom(animated: false)
            }
        }
    }

    @objc private func handleRefresh() {
        Task {
            await viewModel.loadOlderMessages()
            await MainActor.run {
                self.refreshControl.endRefreshing()
            }
        }
    }

    // MARK: - UITableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let msg = viewModel.messages[indexPath.row]
        let tone = viewModel.conversation?.role.toneHex ?? "#FF7A50"
        let convRole = viewModel.conversation?.role ?? .manager

        switch msg.type {
        case .text:
            let cell = tableView.dequeueReusableCell(withIdentifier: TextBubbleCell.reuseID, for: indexPath) as! TextBubbleCell
            cell.delegate = self
            cell.configure(msg, tone: tone, convRole: convRole)
            return cell
        case .system:
            let cell = tableView.dequeueReusableCell(withIdentifier: SystemMessageCell.reuseID, for: indexPath) as! SystemMessageCell
            cell.configure(text: msg.text ?? "")
            return cell
        case .metricCard, .reportCard, .dietCard, .appointmentCard, .caseCard, .planCard:
            let cell = tableView.dequeueReusableCell(withIdentifier: ServiceCardCell.reuseID, for: indexPath) as! ServiceCardCell
            cell.configure(msg, tone: tone)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: ImageBubbleCell.reuseID, for: indexPath) as! ImageBubbleCell
            cell.delegate = self
            cell.configure(msg, tone: tone, convRole: convRole)
            cell.onTapImage = { [weak self] path in
                self?.showImagePreview(path: path)
            }
            return cell
        case .file:
            let cell = tableView.dequeueReusableCell(withIdentifier: FileBubbleCell.reuseID, for: indexPath) as! FileBubbleCell
            cell.delegate = self
            cell.configure(msg, tone: tone, convRole: convRole)
            return cell
        case .video:
            let cell = tableView.dequeueReusableCell(withIdentifier: VideoBubbleCell.reuseID, for: indexPath) as! VideoBubbleCell
            cell.delegate = self
            cell.configure(msg, tone: tone, convRole: convRole)
            return cell
        case .sysNotify:
            let cell = tableView.dequeueReusableCell(withIdentifier: SysNotifyCell.reuseID, for: indexPath) as! SysNotifyCell
            cell.delegate = self
            cell.configure(msg, tone: tone, convRole: convRole)
            return cell
        case .timeMarker, .recall:
            let cell = tableView.dequeueReusableCell(withIdentifier: CenteredTipCell.reuseID, for: indexPath) as! CenteredTipCell
            cell.configure(text: msg.text ?? "")
            return cell
        case .voice:
            let cell = tableView.dequeueReusableCell(withIdentifier: VoiceBubbleCell.reuseID, for: indexPath) as! VoiceBubbleCell
            cell.delegate = self
            cell.configure(msg, tone: tone, convRole: convRole)
            return cell
        }
    }

    // MARK: - Context Header

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let conv = viewModel.conversation else { return nil }
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

    // MARK: - Send

    @objc private func sendMessage() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        viewModel.sendText(text)
        textField.text = ""
        updateSendBtn()
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
                guard duration >= 1, let url = audioRecorder.stopRecording() else { break }
                viewModel.sendVoice(localPath: url.path, duration: duration)
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
        actionMenu?.dismiss()

        let actions = viewModel.availableActions(for: message)
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
        case .copy:
            if let text = viewModel.copyMessageText(message) {
                UIPasteboard.general.string = text
                showToast("已复制")
            }
        case .recall:
            let alert = UIAlertController(title: "撤回消息", message: "确定撤回这条消息吗？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "撤回", style: .default) { [weak self] _ in
                guard let self else { return }
                Task {
                    let success = await self.viewModel.recallMessage(message)
                    await MainActor.run {
                        self.showToast(success ? "已撤回" : "撤回失败，请重试")
                    }
                }
            })
            present(alert, animated: true)
        case .quote:
            viewModel.startQuote(message)
        }
    }

    /// 点击消息气泡内的引用区（replyView）
    func cellDidTapReply(_ cell: UITableViewCell, message: ChatMessage) {
        guard let reply = message.reply else { return }
        switch viewModel.quoteAction(for: reply) {
        case .showImage(let path): showImagePreview(path: path)
        case .playVoice(let path): playVoice(urlPath: path)
        case .playVideo: showToast("视频播放")
        case .none: break
        }
    }

    // MARK: - Quote Preview

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
        viewModel.dismissQuote()
        quotePreviewBar?.dismiss()
        quotePreviewBar = nil
    }

    private func handleQuotePreviewTap(reply: ReplyMessage) {
        switch viewModel.quoteAction(for: reply) {
        case .showImage(let path): showImagePreview(path: path)
        case .playVoice(let path): playVoice(urlPath: path)
        case .playVideo: showToast("视频播放")
        case .none: break
        }
    }

    // MARK: - Voice Playback

    private func playVoice(urlPath: String) {
        if urlPath.hasPrefix("/"), FileManager.default.fileExists(atPath: urlPath) {
            playAudioFile(url: URL(fileURLWithPath: urlPath))
            return
        }
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
        guard !viewModel.messages.isEmpty else { return }
        tableView.scrollToRow(at: IndexPath(row: viewModel.messages.count - 1, section: 0), at: .bottom, animated: animated)
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
        viewModel.sendImage(image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func showImagePreview(path: String?) {
        guard let path = path else { return }
        let previewVC = ImagePreviewViewController(imagePath: path)
        previewVC.modalPresentationStyle = .fullScreen
        present(previewVC, animated: true)
    }
}

// MARK: - Image Preview

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

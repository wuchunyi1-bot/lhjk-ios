import UIKit
import SnapKit
import Combine
import Kingfisher
import AVFoundation
import RongIMLibCore
import UniformTypeIdentifiers

/// 消息 Cell 长按回调协议
protocol ChatCellDelegate: AnyObject {
    func cellDidLongPress(_ cell: UITableViewCell, message: ChatMessage)
    func cellDidTapReply(_ cell: UITableViewCell, message: ChatMessage)
    func cellDidTapIMCard(_ cell: UITableViewCell, message: ChatMessage)
    func cellVoicePlaybackFailed(_ cell: UITableViewCell, message: String)
}

extension ChatCellDelegate {
    func cellDidTapReply(_ cell: UITableViewCell, message: ChatMessage) {}
    func cellDidTapIMCard(_ cell: UITableViewCell, message: ChatMessage) {}
    func cellVoicePlaybackFailed(_ cell: UITableViewCell, message: String) {}
}

/// 聊天详情页 — 参考 funde-client ConversationDetailView.vue
final class ChatViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate, ChatCellDelegate, ChatInputBarDelegate {

    // MARK: - ViewModel

    private let viewModel: ChatViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI State

    private var inputBottomConstraint: Constraint?
    private var tableBottomConstraint: Constraint?
    private var isInputBarEmbedded = false
    private var isVoiceCancelled = false
    private let audioRecorder = AudioRecorder()
    private let quoteVoicePlayback = VoicePlaybackController()
    private var actionMenu: MessageActionMenu?

    private let recordingOverlay: UIView = {
        let view = UIView()
        view.isHidden = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }()

    private let recordingBgView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "chat_input_recordingBg"))
        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let recordingHintLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 16)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "松手 发语音"
        return label
    }()

    private let recordingLineView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "chat_input_recordingLine"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private var quotePreviewBar: QuotePreviewBar?

    /// `getGroup.status != 1` 时底部提示（Figma 4497:5085）
    private let expiredHintLabel: UILabel = {
        let label = UILabel()
        label.text = "服务已过期，仅可查看历史消息"
        label.font = .fdFont(ofSize: 12, weight: .regular)
        label.textColor = ChatBubbleStyle.secondaryText
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

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
        return tv
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return rc
    }()

    private lazy var chatInputBar: ChatInputBar = {
        let bar = ChatInputBar()
        bar.delegate = self
        return bar
    }()

    // MARK: - Init

    init(
        conversationId: String,
        conversationType: RCConversationType = .ConversationType_GROUP
    ) {
        self.viewModel = ChatViewModel(
            conversationId: conversationId,
            conversationType: conversationType
        )
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
        title = viewModel.conversation?.name ?? "通知"

        view.addSubview(tableView)
        tableView.refreshControl = refreshControl

        view.addSubview(expiredHintLabel)
        expiredHintLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }

        view.addSubview(recordingOverlay)
        recordingOverlay.addSubview(recordingBgView)
        recordingOverlay.addSubview(recordingLineView)
        recordingOverlay.addSubview(recordingHintLabel)

        recordingOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        recordingBgView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(300)
        }

        setupGroupMembersBarButton()

        if viewModel.isMessagingReadOnly {
            applyTableOnlyLayout(showExpiredHint: true)
        } else if shouldDeferInputBarUntilGroupMetadataLoaded {
            applyTableOnlyLayout(showExpiredHint: false)
        } else {
            embedInputBarLayout()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        loadMessages()
    }

    private func embedInputBarLayout() {
        guard !isInputBarEmbedded else { return }
        expiredHintLabel.isHidden = true
        view.addSubview(chatInputBar)
        isInputBarEmbedded = true

        recordingLineView.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(183)
            make.height.equalTo(6)
            make.bottom.equalTo(chatInputBar.snp.top).offset(-36)
        }
        recordingHintLabel.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(recordingLineView.snp.top).offset(-28)
        }

        tableView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            tableBottomConstraint = make.bottom.equalTo(chatInputBar.snp.top).constraint
        }

        chatInputBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            inputBottomConstraint = make.bottom.equalToSuperview().constraint
        }
    }

    private func applyTableOnlyLayout(showExpiredHint: Bool) {
        if isInputBarEmbedded {
            chatInputBar.dismissPanel()
            chatInputBar.resignTextInput()
            chatInputBar.removeFromSuperview()
            isInputBarEmbedded = false
            inputBottomConstraint = nil
        }
        quotePreviewBar?.removeFromSuperview()
        quotePreviewBar = nil
        expiredHintLabel.isHidden = !showExpiredHint

        tableView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            if showExpiredHint {
                tableBottomConstraint = make.bottom.equalTo(expiredHintLabel.snp.top).offset(-12).constraint
            } else {
                tableBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
            }
        }

        recordingLineView.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(183)
            make.height.equalTo(6)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-120)
        }
        recordingHintLabel.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(recordingLineView.snp.top).offset(-28)
        }
    }

    private func applyMessagingReadOnlyUIIfNeeded() {
        if viewModel.isMessagingReadOnly {
            applyTableOnlyLayout(showExpiredHint: true)
        } else if shouldDeferInputBarUntilGroupMetadataLoaded {
            applyTableOnlyLayout(showExpiredHint: false)
        } else if !isInputBarEmbedded {
            embedInputBarLayout()
        } else {
            expiredHintLabel.isHidden = true
        }
    }

    private func setupGroupMembersBarButton() {
        guard viewModel.conversationType == .ConversationType_GROUP else { return }
        let button = UIButton(type: .system)
        button.setImage(.fdNavGroupMembers, for: .normal)
        button.addTarget(self, action: #selector(openGroupMembers), for: .touchUpInside)
        button.snp.makeConstraints { $0.size.equalTo(24) }
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }

    @objc private func openGroupMembers() {
        Router.shared.push("/conversations/:id/members", params: ["id": viewModel.conversationId])
    }

    private var shouldDeferInputBarUntilGroupMetadataLoaded: Bool {
        viewModel.conversationType == .ConversationType_GROUP
            && viewModel.conversation?.groupStatus == nil
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - ViewModel Binding

    override func bindViewModel() {
        viewModel.$conversation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conv in
                guard let self else { return }
                self.title = conv?.name ?? "通知"
                self.applyMessagingReadOnlyUIIfNeeded()
            }
            .store(in: &cancellables)

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

    private func loadMessages() {
        Task {
            await viewModel.refreshConversationMetadata()
            await viewModel.loadMessages()
            await MainActor.run {
                self.applyMessagingReadOnlyUIIfNeeded()
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
            cell.onTapFile = { [weak self] message in
                self?.openFileMessage(message)
            }
            return cell
        case .video:
            let cell = tableView.dequeueReusableCell(withIdentifier: VideoBubbleCell.reuseID, for: indexPath) as! VideoBubbleCell
            cell.delegate = self
            cell.configure(msg, tone: tone, convRole: convRole)
            return cell
        case .sysNotify, .vip, .serviceComment, .checkUserMsg:
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

    // MARK: - Keyboard

    @objc private func keyboardWillShow(_ n: Notification) {
        guard isInputBarEmbedded else { return }
        guard chatInputBar.activePanel == .none else { return }
        guard let kb = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        inputBottomConstraint?.update(offset: -kb.height)
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
        scrollToBottom(animated: false)
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        guard isInputBarEmbedded else { return }
        inputBottomConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
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

    func cellVoicePlaybackFailed(_ cell: UITableViewCell, message: String) {
        showToast(message)
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

    /// 点击协议卡片（可点矩阵）
    func cellDidTapIMCard(_ cell: UITableViewCell, message: ChatMessage) {
        guard let card = IMCardResolver.resolve(from: message),
              let action = IMCardResolver.tapAction(for: card) else { return }
        switch action {
        case .openPageUrl(let pageUrl):
            NotificationMessageMapper.openRoute(pageUrl, from: self)
        case .openRoute(let path):
            NotificationMessageMapper.openRoute(path, from: self)
        case .unavailable(let tip):
            showToast(tip)
        }
    }

    // MARK: - Quote Preview

    private func showQuotePreview(for reply: ReplyMessage) {
        guard isInputBarEmbedded else { return }
        quotePreviewBar?.removeFromSuperview()
        let bar = QuotePreviewBar()
        bar.configure(with: reply)
        bar.onDismiss = { [weak self] in
            self?.dismissQuote()
        }
        bar.onTap = { [weak self] in
            self?.handleQuotePreviewTap(reply: reply)
        }
        view.insertSubview(bar, belowSubview: chatInputBar)
        bar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(chatInputBar.snp.top)
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

    // MARK: - File Preview

    private func openFileMessage(_ message: ChatMessage) {
        guard let file = message.fileContent else {
            showToast("无法打开文件")
            return
        }

        let suffix = (file.fileSuffix ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if suffix == "mp3" {
            guard let urlPath = file.fileUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !urlPath.isEmpty else {
                showToast("无法打开音频")
                return
            }
            playVoice(urlPath: urlPath)
            return
        }

        guard let urlString = resolveFileWebURL(file) else {
            showToast("无法打开文件")
            return
        }

        let title = (file.fileName ?? "文件").trimmingCharacters(in: .whitespacesAndNewlines)
        let webVC = WebViewController(urlString: urlString, title: title.isEmpty ? "文件" : title)
        navigationController?.pushViewController(webVC, animated: true)
    }

    private func resolveFileWebURL(_ file: FileMessage) -> String? {
        guard let raw = file.fileUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }

        if raw.hasPrefix("http://") || raw.hasPrefix("https://") || raw.hasPrefix("file://") {
            return raw
        }

        if raw.hasPrefix("/") {
            return URL(fileURLWithPath: raw).absoluteString
        }

        return URL(string: raw)?.absoluteString ?? raw
    }

    // MARK: - Voice Playback

    private func playVoice(urlPath: String) {
        print("[Voice] quotePlay ref=\(urlPath)")
        if urlPath.hasPrefix("/"), FileManager.default.fileExists(atPath: urlPath) {
            playAudioFile(url: URL(fileURLWithPath: urlPath), messageId: -1)
            return
        }
        guard let remoteURL = URL(string: urlPath) else {
            print("[Voice] quotePlay ✗ invalid url ref=\(urlPath)")
            return
        }
        showToast("正在加载语音...")
        Task {
            do {
                let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
                await MainActor.run {
                    VoicePlaybackLogger.logRemoteDownload(
                        url: remoteURL,
                        tempPath: tempURL.path,
                        destPath: nil,
                        error: nil
                    )
                    playAudioFile(url: tempURL, messageId: -1)
                }
            } catch {
                await MainActor.run {
                    VoicePlaybackLogger.logRemoteDownload(
                        url: remoteURL,
                        tempPath: nil,
                        destPath: nil,
                        error: error
                    )
                    showToast("语音播放失败")
                }
            }
        }
    }

    private func playAudioFile(url: URL, messageId: Int) {
        quoteVoicePlayback.play(
            url: url,
            messageId: messageId,
            onStarted: {},
            onFinished: {},
            onFailed: { [weak self] _ in
                self?.showToast("语音播放失败")
            }
        )
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        actionMenu?.dismiss()
        chatInputBar.dismissPanel()
        chatInputBar.resignTextInput()
    }

    // MARK: - Helpers

    private func showToast(_ message: String) {
        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        container.layer.cornerRadius = 8
        container.clipsToBounds = true
        let label = UILabel()
        label.text = message
        label.font = .fdFont(ofSize: 16)
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

// MARK: - ChatInputBarDelegate

extension ChatViewController {
    func chatInputBarDidTapToggleMode(_ bar: ChatInputBar) {
        if !bar.isVoiceMode {
            requestMicPermissionIfNeeded()
            bar.dismissPanel()
        }
        bar.setVoiceMode(!bar.isVoiceMode)
    }

    func chatInputBarDidTapEmoji(_ bar: ChatInputBar) {
        if bar.isVoiceMode {
            bar.setVoiceMode(false, animated: false)
        }
        let nextPanel: ChatInputBar.Panel = bar.activePanel == .emoji ? .none : .emoji
        bar.setPanel(nextPanel)
        if nextPanel == .emoji {
            inputBottomConstraint?.update(offset: 0)
            UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
            scrollToBottom(animated: false)
        }
    }

    func chatInputBarDidTapMore(_ bar: ChatInputBar) {
        if bar.isVoiceMode {
            bar.setVoiceMode(false, animated: false)
        }
        let nextPanel: ChatInputBar.Panel = bar.activePanel == .more ? .none : .more
        bar.setPanel(nextPanel)
        if nextPanel == .more {
            inputBottomConstraint?.update(offset: 0)
            UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
            scrollToBottom(animated: false)
        }
    }

    func chatInputBarDidTapPhoto(_ bar: ChatInputBar) {
        bar.dismissPanel()
        showImagePicker()
    }

    func chatInputBarDidTapFile(_ bar: ChatInputBar) {
        bar.dismissPanel()
        showDocumentPicker()
    }

    func chatInputBar(_ bar: ChatInputBar, didChangeText text: String) {}

    func chatInputBarDidSend(_ bar: ChatInputBar) {
        let trimmed = bar.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.sendText(trimmed)
        bar.text = ""
    }

    func chatInputBarDidBeginVoicePress(_ bar: ChatInputBar) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            guard beginVoiceRecording() else { return }
            showRecordingOverlay(isCancelled: false)
        case .notDetermined:
            requestMicPermissionIfNeeded()
        default:
            showToast("请在设置中开启麦克风权限")
        }
    }

    func chatInputBarDidUpdateVoicePress(_ bar: ChatInputBar, isCancelled: Bool) {
        isVoiceCancelled = isCancelled
        showRecordingOverlay(isCancelled: isCancelled)
    }

    func chatInputBarDidEndVoicePress(_ bar: ChatInputBar, isCancelled: Bool) {
        hideRecordingOverlay()
        if isCancelled || isVoiceCancelled {
            audioRecorder.cancelRecording()
            return
        }
        guard audioRecorder.isRecording || audioRecorder.isPaused else { return }
        let duration = Int(audioRecorder.currentDuration)
        guard duration >= 1, let url = audioRecorder.stopRecording() else {
            showToast("说话时间太短")
            return
        }
        viewModel.sendVoice(localPath: url.path, duration: duration)
    }

    private func requestMicPermissionIfNeeded() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    if !granted {
                        self?.showToast("需要麦克风权限才能发送语音")
                    }
                }
            }
        default:
            showToast("请在设置中开启麦克风权限")
        }
    }

    @discardableResult
    private func beginVoiceRecording() -> Bool {
        guard !audioRecorder.isRecording else { return true }
        isVoiceCancelled = false
        let fm = MediaFileManager()
        let url = URL(fileURLWithPath: fm.basePath(.temp) + "/voice_\(Int(Date().timeIntervalSince1970)).wav")
        do {
            try audioRecorder.startRecording(to: url)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            print("[Chat-PL] startRecording ✓ \(url.lastPathComponent)")
            return true
        } catch {
            print("[Chat-PL] startRecording ✗ \(error.localizedDescription)")
            showToast("录音失败")
            return false
        }
    }

    private func showRecordingOverlay(isCancelled: Bool) {
        recordingHintLabel.text = isCancelled ? "松手 取消" : "松手 发语音"
        recordingOverlay.isHidden = false
        view.bringSubviewToFront(recordingOverlay)
    }

    private func hideRecordingOverlay() {
        recordingOverlay.isHidden = true
        recordingHintLabel.text = "松手 发语音"
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
        present(picker, animated: true) {
            WebViewSystemChromeLocalizer.scheduleLocalizationAfterPresentingPicker()
        }
    }

    private func openPhotoLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true) {
            WebViewSystemChromeLocalizer.scheduleLocalizationAfterPresentingPicker()
        }
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

    private func showDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item], asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = self
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("rc_file_\(Int(Date().timeIntervalSince1970 * 1000))_\(url.lastPathComponent)")
        do {
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            try FileManager.default.copyItem(at: url, to: tempURL)
            viewModel.sendFile(localURL: tempURL)
        } catch {
            print("[Chat-PL] copy file ✗ \(error.localizedDescription)")
            showToast("无法读取该文件")
        }
    }
}

// MARK: - Chat Input Bar

protocol ChatInputBarDelegate: AnyObject {
    func chatInputBarDidTapToggleMode(_ bar: ChatInputBar)
    func chatInputBarDidTapEmoji(_ bar: ChatInputBar)
    func chatInputBarDidTapMore(_ bar: ChatInputBar)
    func chatInputBarDidTapPhoto(_ bar: ChatInputBar)
    func chatInputBarDidTapFile(_ bar: ChatInputBar)
    func chatInputBar(_ bar: ChatInputBar, didChangeText text: String)
    func chatInputBarDidSend(_ bar: ChatInputBar)
    func chatInputBarDidBeginVoicePress(_ bar: ChatInputBar)
    func chatInputBarDidUpdateVoicePress(_ bar: ChatInputBar, isCancelled: Bool)
    func chatInputBarDidEndVoicePress(_ bar: ChatInputBar, isCancelled: Bool)
}

/// 聊天详情底部输入区 — 对齐 Figma 3876:34690 / 35344 / 34873
final class ChatInputBar: UIView {

    enum Panel {
        case none
        case more
        case emoji
    }

    weak var delegate: ChatInputBarDelegate?

    private(set) var isVoiceMode = false
    private(set) var activePanel: Panel = .none

    var placeholderText: String = "发信息给..." {
        didSet { updateInputPresentation() }
    }

    var text: String {
        get { textField.text ?? "" }
        set {
            textField.text = newValue
            updateInputPresentation()
        }
    }

    private enum Layout {
        static let rowHeight: CGFloat = 66
        static let collapsedHeight: CGFloat = 66
        static let morePanelHeight: CGFloat = 157
        static let emojiPanelHeight: CGFloat = 232
        static let morePanelContentHeight: CGFloat = morePanelHeight - collapsedHeight
        static let emojiPanelContentHeight: CGFloat = emojiPanelHeight - collapsedHeight
        static let horizontalInset: CGFloat = 16
        static let leftButtonLeading: CGFloat = 14
        static let leftButtonSize = CGSize(width: 52, height: 52)
        static let rightButtonTrailing: CGFloat = 12
        static let rightButtonSize = CGSize(width: 56, height: 56)
        static let fieldHeight: CGFloat = 48
        static let fieldTrailingGap: CGFloat = 4
        /// 左侧按钮压入输入框约 50pt，占位/文字从 56pt 起（对齐 Figma 35346）
        static let textLeadingInset: CGFloat = leftButtonLeading + leftButtonSize.width - horizontalInset + 6
        static let iconSize: CGFloat = 24
        static let panelItemWidth: CGFloat = 44
        static let panelItemIconHeight: CGFloat = 44
        static let panelItemLeading: CGFloat = 20
        static let panelItemSpacing: CGFloat = 42
        static let panelItemTop: CGFloat = 4
        static let panelItemLabelGap: CGFloat = 6
    }

    private let backgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    private let backgroundGradient = CAGradientLayer()
    private let contentRow = UIView()

    private let centerFieldView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let leftButtonWrap = UIView()
    private let rightButtonWrap = UIView()

    private lazy var leftButton: UIButton = makeToolbarButton(action: #selector(toggleModeTapped))

    private lazy var rightButton: UIButton = makeToolbarButton(action: #selector(moreTapped))

    private lazy var fieldEmojiButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(emojiTapped), for: .touchUpInside)
        return button
    }()

    private lazy var voiceLabel: UILabel = {
        let label = UILabel()
        label.text = "按住说话"
        label.font = .fdFont(ofSize: 16, weight: .medium)
        label.textColor = .fdText
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleVoiceLongPress(_:)))
        longPress.minimumPressDuration = 0.1
        label.addGestureRecognizer(longPress)
        return label
    }()

    private lazy var textField: UITextField = {
        let field = UITextField()
        field.font = .fdFont(ofSize: 16)
        field.textColor = .fdText
        field.backgroundColor = .white
        field.returnKeyType = .send
        field.delegate = self
        field.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        return field
    }()

    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 16)
        label.textColor = UIColor(hexString: "#8591AB")
        label.text = placeholderText
        label.isUserInteractionEnabled = false
        return label
    }()

    private let panelContainer = UIView()
    private var panelAreaHeightConstraint: Constraint?
    private var emojiCollectionTopConstraint: Constraint?
    private var emojiCollectionHeightConstraint: Constraint?

    private lazy var photoItem = makePanelItem(
        icon: panelAssetIcon("chat_input_img"),
        title: "图片",
        action: #selector(photoTapped)
    )

    private lazy var fileItem = makePanelItem(
        icon: panelAssetIcon("chat_input_file"),
        title: "文件",
        action: #selector(fileTapped)
    )

    private lazy var emojiCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 8
        layout.itemSize = CGSize(width: 36, height: 36)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(ChatEmojiCell.self, forCellWithReuseIdentifier: ChatEmojiCell.reuseID)
        return cv
    }()

    private var heightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateInputPresentation()
        updateHeight(animated: false)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundGradient.frame = backgroundView.bounds
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        updateInputPresentation()
        updateHeight(animated: false)
    }

    func setVoiceMode(_ enabled: Bool, animated: Bool = true) {
        guard isVoiceMode != enabled else { return }
        isVoiceMode = enabled
        if enabled {
            textField.resignFirstResponder()
            activePanel = .none
        }
        updateInputPresentation()
        updateHeight(animated: animated)
    }

    func setPanel(_ panel: Panel, animated: Bool = true) {
        activePanel = panel
        if panel != .none {
            textField.resignFirstResponder()
        }
        updateInputPresentation()
        updateHeight(animated: animated)
    }

    func dismissPanel() {
        guard activePanel != .none else { return }
        activePanel = .none
        updateInputPresentation()
        updateHeight(animated: true)
    }

    func focusTextInput() {
        setVoiceMode(false, animated: false)
        if activePanel != .none {
            setPanel(.none, animated: false)
        }
        textField.becomeFirstResponder()
    }

    func resignTextInput() {
        textField.resignFirstResponder()
    }

    private func setupUI() {
        backgroundColor = .clear
        backgroundGradient.colors = [
            UIColor.white.cgColor,
            UIColor(hexString: "#FDF6F3").cgColor
        ]
        backgroundGradient.locations = [0.06566, 0.23239]
        backgroundGradient.startPoint = CGPoint(x: 0.5, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 0.5, y: 1)
        backgroundView.layer.insertSublayer(backgroundGradient, at: 0)

        addSubview(backgroundView)
        addSubview(contentRow)
        addSubview(panelContainer)

        backgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }

        contentRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.rowHeight)
        }

        panelContainer.snp.makeConstraints { make in
            make.top.equalTo(contentRow.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            panelAreaHeightConstraint = make.height.equalTo(0).constraint
        }

        contentRow.addSubview(centerFieldView)
        contentRow.addSubview(rightButtonWrap)
        contentRow.addSubview(leftButtonWrap)

        leftButtonWrap.addSubview(leftButton)
        rightButtonWrap.addSubview(rightButton)

        rightButtonWrap.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Layout.rightButtonTrailing)
            make.centerY.equalToSuperview()
            make.size.equalTo(Layout.rightButtonSize)
        }

        leftButtonWrap.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Layout.leftButtonLeading)
            make.centerY.equalToSuperview()
            make.size.equalTo(Layout.leftButtonSize)
        }

        centerFieldView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Layout.horizontalInset)
            make.trailing.equalTo(rightButtonWrap.snp.leading).offset(-Layout.fieldTrailingGap)
            make.centerY.equalToSuperview()
            make.height.equalTo(Layout.fieldHeight)
        }

        leftButton.snp.makeConstraints { $0.edges.equalToSuperview() }
        rightButton.snp.makeConstraints { $0.edges.equalToSuperview() }

        centerFieldView.addSubview(voiceLabel)
        centerFieldView.addSubview(textField)
        centerFieldView.addSubview(placeholderLabel)
        centerFieldView.addSubview(fieldEmojiButton)

        let centerTap = UITapGestureRecognizer(target: self, action: #selector(centerFieldTapped))
        centerTap.cancelsTouchesInView = false
        centerTap.delegate = self
        centerFieldView.addGestureRecognizer(centerTap)

        panelContainer.addSubview(photoItem.view)
        panelContainer.addSubview(fileItem.view)
        panelContainer.addSubview(emojiCollection)

        voiceLabel.snp.makeConstraints { $0.edges.equalToSuperview() }

        textField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Layout.textLeadingInset)
            make.trailing.equalTo(fieldEmojiButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(21)
        }

        placeholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Layout.textLeadingInset)
            make.trailing.lessThanOrEqualTo(fieldEmojiButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }

        fieldEmojiButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(Layout.iconSize)
        }

        photoItem.view.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Layout.panelItemLeading)
            make.top.equalToSuperview().offset(Layout.panelItemTop)
            make.width.equalTo(Layout.panelItemWidth)
        }

        fileItem.view.snp.makeConstraints { make in
            make.leading.equalTo(photoItem.view.snp.trailing).offset(Layout.panelItemSpacing)
            make.top.equalTo(photoItem.view)
            make.width.equalTo(Layout.panelItemWidth)
        }

        emojiCollection.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            emojiCollectionTopConstraint = make.top.equalToSuperview().offset(0).constraint
            emojiCollectionHeightConstraint = make.height.equalTo(0).constraint
        }

        snp.makeConstraints { make in
            heightConstraint = make.height.equalTo(totalBarHeight()).constraint
        }

        applyAssetIcon(fieldEmojiButton, asset: "chat_input_emoji", size: Layout.iconSize)
        updateInputPresentation()
    }

    private func panelAreaHeight(for panel: Panel) -> CGFloat {
        let safeBottom = safeAreaInsets.bottom
        switch panel {
        case .none: return safeBottom
        case .more: return Layout.morePanelContentHeight + safeBottom
        case .emoji: return Layout.emojiPanelContentHeight + safeBottom
        }
    }

    private func makeToolbarButton(action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.adjustsImageWhenHighlighted = false
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func applyAssetButton(_ button: UIButton, asset: String) {
        guard let image = UIImage(named: asset) else {
            print("[Chat-PL] missing asset \(asset)")
            return
        }
        button.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = .clear
    }

    private func applyAssetIcon(_ button: UIButton, asset: String, size: CGFloat) {
        guard let image = UIImage(named: asset) else {
            print("[Chat-PL] missing asset \(asset)")
            return
        }
        button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor(hexString: "#1F2942")
        button.backgroundColor = .clear
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.imageView?.contentMode = .scaleAspectFit
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateHeight(animated: false)
    }

    private func totalBarHeight() -> CGFloat {
        let content: CGFloat
        switch activePanel {
        case .none: content = Layout.collapsedHeight
        case .more: content = Layout.morePanelHeight
        case .emoji: content = Layout.emojiPanelHeight
        }
        return content + safeAreaInsets.bottom
    }

    private func panelAssetIcon(_ name: String) -> UIImage? {
        UIImage(named: name)?.withRenderingMode(.alwaysOriginal)
    }

    private func makePanelItem(icon: UIImage?, title: String, action: Selector) -> (view: UIView, button: UIButton) {
        let container = UIView()

        let button = UIButton(type: .custom)
        button.addTarget(self, action: action, for: .touchUpInside)

        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false
        iconView.image = icon

        let label = UILabel()
        label.text = title
        label.font = .fdFont(ofSize: 14, weight: .medium)
        label.textColor = .fdText
        label.textAlignment = .center

        container.addSubview(iconView)
        container.addSubview(label)
        container.addSubview(button)

        iconView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.equalTo(Layout.panelItemWidth)
            make.height.equalTo(Layout.panelItemIconHeight)
        }
        label.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(Layout.panelItemLabelGap)
            make.leading.trailing.bottom.equalToSuperview()
        }
        button.snp.makeConstraints { $0.edges.equalToSuperview() }

        return (container, button)
    }

    private func updateInputPresentation() {
        let showVoice = isVoiceMode
        voiceLabel.isHidden = !showVoice
        textField.isHidden = showVoice
        placeholderLabel.isHidden = showVoice
        fieldEmojiButton.isHidden = false

        if !showVoice {
            placeholderLabel.text = placeholderText
            placeholderLabel.isHidden = !(textField.text ?? "").isEmpty
        }

        if showVoice {
            applyAssetButton(leftButton, asset: "chat_input_keybord")
        } else {
            applyAssetButton(leftButton, asset: "chat_input_voice")
        }
        applyAssetButton(rightButton, asset: "chat_input_plus")
        applyAssetIcon(fieldEmojiButton, asset: "chat_input_emoji", size: Layout.iconSize)

        let panelHeight = panelAreaHeight(for: activePanel)
        panelContainer.isHidden = activePanel == .none && safeAreaInsets.bottom <= 0
        panelAreaHeightConstraint?.update(offset: panelHeight)
        photoItem.view.isHidden = activePanel != .more
        fileItem.view.isHidden = activePanel != .more
        emojiCollection.isHidden = activePanel != .emoji
        if activePanel == .emoji {
            emojiCollectionTopConstraint?.update(offset: 8)
            emojiCollectionHeightConstraint?.update(offset: Layout.emojiPanelContentHeight - 16)
            emojiCollection.reloadData()
            emojiCollection.layoutIfNeeded()
        } else {
            emojiCollectionTopConstraint?.update(offset: 0)
            emojiCollectionHeightConstraint?.update(offset: 0)
        }
    }

    private func updateHeight(animated: Bool) {
        heightConstraint?.update(offset: totalBarHeight())

        guard animated else { return }
        UIView.animate(withDuration: 0.25) {
            self.superview?.layoutIfNeeded()
        }
    }

    @objc private func textFieldChanged() {
        placeholderLabel.isHidden = !(textField.text ?? "").isEmpty
        delegate?.chatInputBar(self, didChangeText: textField.text ?? "")
    }

    @objc private func centerFieldTapped() {
        guard !isVoiceMode else { return }
        focusTextInput()
    }

    @objc private func toggleModeTapped() {
        delegate?.chatInputBarDidTapToggleMode(self)
    }

    @objc private func emojiTapped() {
        delegate?.chatInputBarDidTapEmoji(self)
    }

    @objc private func moreTapped() {
        delegate?.chatInputBarDidTapMore(self)
    }

    @objc private func photoTapped() {
        delegate?.chatInputBarDidTapPhoto(self)
    }

    @objc private func fileTapped() {
        delegate?.chatInputBarDidTapFile(self)
    }

    @objc private func handleVoiceLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: voiceLabel)
        let isCancelled = location.y < -60

        switch gesture.state {
        case .began:
            dismissPanel()
            voiceLabel.text = "按住说话"
            voiceLabel.textColor = .fdText
            delegate?.chatInputBarDidBeginVoicePress(self)
        case .changed:
            delegate?.chatInputBarDidUpdateVoicePress(self, isCancelled: isCancelled)
        case .ended:
            voiceLabel.text = "按住说话"
            voiceLabel.textColor = .fdText
            delegate?.chatInputBarDidEndVoicePress(self, isCancelled: isCancelled)
        case .cancelled, .failed:
            voiceLabel.text = "按住说话"
            voiceLabel.textColor = .fdText
            delegate?.chatInputBarDidEndVoicePress(self, isCancelled: true)
        default:
            break
        }
    }
}

extension ChatInputBar: UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if activePanel != .none {
            setPanel(.none, animated: false)
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: centerFieldView)
        if fieldEmojiButton.frame.contains(point) { return false }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.chatInputBarDidSend(self)
        return false
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        RongEmoji.allEmojis.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatEmojiCell.reuseID, for: indexPath) as! ChatEmojiCell
        cell.configure(RongEmoji.allEmojis[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emoji = RongEmoji.allEmojis[indexPath.item]
        textField.text = (textField.text ?? "") + emoji
        textFieldChanged()
    }
}

private final class ChatEmojiCell: UICollectionViewCell {
    static let reuseID = "ChatEmojiCell"

    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 28)
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ emoji: String) {
        label.text = emoji
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

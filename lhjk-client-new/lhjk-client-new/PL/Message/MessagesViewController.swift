import UIKit
import SnapKit

/// 消息模块根页 — 容器 VC，通过自定义分段 Tab 切换团队对话与通知中心
/// 对齐 Figma 3444:5583 / 3444:5773（标题行 + 团队对话/通知中心曲线分段 + 自然滚动列表）
final class MessagesViewController: BaseViewController {

    // MARK: - Child VCs

    private let chatListVC = ConversationListViewController()
    private let notiListVC = NotificationListViewController()

    private var activeTab: String = "chat"

    // MARK: - UI

    /// 顶栏（标题 18pt SemiBold #1F2430 / 副标题 12pt #717885）
    private let brandHeader = TabHubBrandHeaderView()

    /// Tab 曲线背景容器（height 73，裁切展示 375x185 背景图的顶部曲线）
    private let tabContainerView: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.backgroundColor = .clear
        return v
    }()

    /// 曲线背景图（团队对话 msg_tab_left / 通知中心 msg_tab_right）
    private let tabBackgroundImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "msg_tab_left"))
        iv.contentMode = .scaleToFill
        iv.isUserInteractionEnabled = false
        return iv
    }()

    private lazy var segmentedControl: MessageSegmentedControl = {
        let c = MessageSegmentedControl()
        c.items = [
            MessageSegmentedControl.Item(title: "团队对话", badge: 0),
            MessageSegmentedControl.Item(title: "通知中心", badge: 0),
        ]
        c.onSelect = { [weak self] idx in
            self?.switchTab(to: idx)
        }
        return c
    }()

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = UIColor(hexString: "#FDF6F3")

        brandHeader.configure(
            title: "消息",
            subtitle: "您的健管团队 7X24 在线",
            titleColor: UIColor(hexString: "#1F2430")
        )

        [
            brandHeader,
            tabContainerView,
            segmentedControl,
            containerView,
        ].forEach(view.addSubview)

        tabContainerView.addSubview(tabBackgroundImageView)

        brandHeader.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }

        tabContainerView.snp.makeConstraints { make in
            make.top.equalTo(brandHeader.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(73)
        }

        tabBackgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(185)
        }

        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(brandHeader.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(73)
        }

        containerView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        [chatListVC, notiListVC].forEach {
            addChild($0)
            containerView.addSubview($0.view)
            $0.view.snp.makeConstraints { $0.edges.equalToSuperview() }
            $0.didMove(toParent: self)
            $0.view.isHidden = true
        }

        chatListVC.onDataChanged = { [weak self] in self?.updateSegmentBadges() }
        notiListVC.onDataChanged = { [weak self] in self?.updateSegmentBadges() }
        chatListVC.view.isHidden = false
        updateSegmentBadges()
    }

    // MARK: - Tab Switching

    private func switchTab(to index: Int) {
        let isChat = index == 0
        activeTab = isChat ? "chat" : "noti"

        UIView.transition(with: tabBackgroundImageView, duration: 0.2, options: .transitionCrossDissolve) { [weak self] in
            self?.tabBackgroundImageView.image = UIImage(named: isChat ? "msg_tab_left" : "msg_tab_right")
        }

        chatListVC.view.isHidden = !isChat
        notiListVC.view.isHidden = isChat
        refreshCurrentChild()
    }

    // MARK: - Actions

    private func refreshCurrentChild() {
        if activeTab == "chat" {
            chatListVC.loadData()
        } else {
            notiListVC.loadData()
        }
    }

    private func updateSegmentBadges() {
        let chatBadge = chatListVC.totalUnread
        let notiBadge = notiListVC.unreadCount

        segmentedControl.items = [
            MessageSegmentedControl.Item(title: "团队对话", badge: chatBadge),
            MessageSegmentedControl.Item(title: "通知中心", badge: notiBadge),
        ]
        segmentedControl.selectedIndex = activeTab == "chat" ? 0 : 1
    }
}

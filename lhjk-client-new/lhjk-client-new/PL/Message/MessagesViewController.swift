import UIKit
import SnapKit

/// 消息模块根页 — 容器 VC，通过自定义分段 Tab 切换两个子 VC
/// 对齐 Figma 3042:740（标题行 + 团队对话/通知中心分段 + 圆角白卡列表）
final class MessagesViewController: BaseViewController {

    // MARK: - Child VCs

    private let chatListVC = ConversationListViewController()
    private let notiListVC = NotificationListViewController()

    private var activeTab: String = "chat"

    // MARK: - UI

    /// 与服务 / 健康共用顶栏字号与间距（标题 fdH2 / 副标题 12）
    private let brandHeader = TabHubBrandHeaderView()

    /// Figma 3042:740：选中「团队对话」时的曲线背景
    private let activeTabBackgroundView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "msg_tab_active"))
        view.contentMode = .scaleToFill
        view.isUserInteractionEnabled = false
        return view
    }()

    /// Figma 3042:740：选中「通知中心」时的右侧曲线背景
    private let inactiveTabBackgroundView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "msg_tab_inactive"))
        view.contentMode = .scaleToFill
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()

    private lazy var segmentedControl: MessageSegmentedControl = {
        let c = MessageSegmentedControl()
        c.items = [
            MessageSegmentedControl.Item(title: "团队对话", badge: 0),
            MessageSegmentedControl.Item(title: "通知中心", badge: 0),
        ]
        c.onSelect = { [weak self] idx in
            self?.activeTab = idx == 0 ? "chat" : "noti"
            self?.chatListVC.view.isHidden = idx != 0
            self?.notiListVC.view.isHidden = idx == 0
            self?.updateTabBackground()
            self?.refreshCurrentChild()
        }
        return c
    }()

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdBg
        return v
    }()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        brandHeader.configure(
            title: "消息",
            subtitle: "您的健管团队 7X24 在线",
            titleColor: .fdText
        )

        [
            brandHeader,
            activeTabBackgroundView,
            inactiveTabBackgroundView,
            segmentedControl,
            containerView,
        ].forEach(view.addSubview)

        brandHeader.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }

        activeTabBackgroundView.snp.makeConstraints { make in
            make.top.equalTo(brandHeader.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(185)
        }
        inactiveTabBackgroundView.snp.makeConstraints { make in
            make.top.equalTo(brandHeader.snp.bottom).offset(6)
            make.trailing.equalToSuperview()
            make.width.equalTo(212)
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
        updateTabBackground()
        updateSegmentBadges()
    }

    private func updateTabBackground() {
        let isChat = activeTab == "chat"
        activeTabBackgroundView.isHidden = !isChat
        inactiveTabBackgroundView.isHidden = isChat
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

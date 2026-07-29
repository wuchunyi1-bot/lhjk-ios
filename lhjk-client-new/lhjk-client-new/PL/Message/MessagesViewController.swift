import UIKit
import SnapKit

/// 消息模块根页 — 容器 VC，通过分段 Tab 切换两个子 VC
/// 参考 funde-client MessagesView.vue
final class MessagesViewController: BaseViewController {

    // MARK: - Child VCs

    private let chatListVC = ConversationListViewController()
    private let notiListVC = NotificationListViewController()

    private var activeTab: String = "chat"

    // MARK: - UI

    private let brandHeader: TabHubBrandHeaderView = {
        let v = TabHubBrandHeaderView()
        v.configure(
            title: "消息",
            subtitle: "您的健管团队 7×24 在线",
            titleColor: .fdText
        )
        return v
    }()

    private lazy var segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["团队对话", "通知中心"])
        sc.selectedSegmentIndex = 0
        sc.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return sc
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

        [brandHeader, segmentControl, containerView].forEach(view.addSubview)

        brandHeader.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }

        segmentControl.snp.makeConstraints { make in
            make.top.equalTo(brandHeader.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        containerView.snp.makeConstraints { make in
            make.top.equalTo(segmentControl.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // 添加两个子 VC
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
    }

    // MARK: - Actions

    @objc private func segmentChanged() {
        activeTab = segmentControl.selectedSegmentIndex == 0 ? "chat" : "noti"

        chatListVC.view.isHidden = activeTab != "chat"
        notiListVC.view.isHidden = activeTab == "chat"

        refreshCurrentChild()
    }

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

        let chatTitle = chatBadge > 0 ? "团队对话 \(chatBadge)" : "团队对话"
        let notiTitle = notiBadge > 0 ? "通知中心 \(notiBadge)" : "通知中心"

        segmentControl.setTitle(chatTitle, forSegmentAt: 0)
        segmentControl.setTitle(notiTitle, forSegmentAt: 1)
    }
}

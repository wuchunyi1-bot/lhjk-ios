import UIKit
import SnapKit

/// 优惠券模块容器 — 对齐 `OrderListViewController`
final class CouponListViewController: BaseViewController {

    private struct TabItem {
        let filter: CouponStatusFilter
        let emptyTitle: String
        var title: String { filter.title }
    }

    private let tabs: [TabItem] = [
        TabItem(filter: .all, emptyTitle: "暂无相关优惠券"),
        TabItem(filter: .available, emptyTitle: "暂无待使用优惠券"),
        TabItem(filter: .used, emptyTitle: "暂无已领用优惠券"),
        TabItem(filter: .expired, emptyTitle: "暂无已过期优惠券"),
    ]

    private var selectedTabIndex = 0
    private var childVCs: [CouponTabViewController] = []
    private var currentChildVC: CouponTabViewController?
    private var availableCount = 0

    private lazy var tabCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .fdBg
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(OrderTabCell.self, forCellWithReuseIdentifier: OrderTabCell.reuseID)
        return cv
    }()

    private let containerView = UIView()

    override var shouldAutomaticallyForwardAppearanceMethods: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        availableCount = AppContainer.shared.voucherService.availableCouponCount
        buildChildVCs()
        refreshAvailableBadge()
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        let tabContainer = UIView()
        tabContainer.backgroundColor = .fdBg
        view.addSubview(tabContainer)
        tabContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        tabContainer.addSubview(tabCollectionView)
        tabCollectionView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(tabContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if currentChildVC == nil {
            showChildVC(at: selectedTabIndex)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        availableCount = AppContainer.shared.voucherService.availableCouponCount
        tabCollectionView.reloadData()
        refreshAvailableBadge()
        currentChildVC?.beginAppearanceTransition(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        currentChildVC?.endAppearanceTransition()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentChildVC?.beginAppearanceTransition(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        currentChildVC?.endAppearanceTransition()
    }

    func refreshVisibleTab() {
        availableCount = AppContainer.shared.voucherService.availableCouponCount
        tabCollectionView.reloadData()
        refreshAvailableBadge()
        currentChildVC?.refresh()
    }

    private func buildChildVCs() {
        childVCs = tabs.map {
            let child = CouponTabViewController(filter: $0.filter, emptyTitle: $0.emptyTitle)
            child.onAvailableCountUpdated = { [weak self] count in
                self?.applyAvailableCount(count)
            }
            return child
        }
    }

    private func refreshAvailableBadge() {
        Task { [weak self] in
            let count = try? await AppContainer.shared.couponService.refreshAvailableCouponCount()
            await MainActor.run {
                self?.applyAvailableCount(count ?? AppContainer.shared.voucherService.availableCouponCount)
            }
        }
    }

    private func applyAvailableCount(_ count: Int) {
        availableCount = count
        tabCollectionView.reloadData()
    }

    private func showChildVC(at index: Int) {
        guard index >= 0, index < childVCs.count else { return }
        let isVisible = isViewLoaded && view.window != nil

        if let old = currentChildVC, isVisible {
            old.beginAppearanceTransition(false, animated: false)
            old.endAppearanceTransition()
        }

        for vc in children {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }

        let child = childVCs[index]
        addChild(child)
        containerView.addSubview(child.view)
        child.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        child.didMove(toParent: self)
        currentChildVC = child

        if isVisible {
            child.beginAppearanceTransition(true, animated: false)
            child.endAppearanceTransition()
        }
    }

    private func selectTab(at index: Int) {
        guard index != selectedTabIndex else { return }
        selectedTabIndex = index
        tabCollectionView.reloadData()
        tabCollectionView.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
        showChildVC(at: index)
    }

    private func tabTitle(at index: Int) -> String {
        let item = tabs[index]
        if item.filter == .available, availableCount > 0 {
            return "\(item.title) \(availableCount)"
        }
        return item.title
    }
}

extension CouponListViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tabs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrderTabCell.reuseID,
            for: indexPath
        ) as! OrderTabCell
        cell.configure(title: tabTitle(at: indexPath.item), isSelected: indexPath.item == selectedTabIndex)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectTab(at: indexPath.item)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let title = tabTitle(at: indexPath.item)
        let width = title.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.fdCaptionSemibold],
            context: nil
        ).width + 16
        return CGSize(width: ceil(width), height: 30)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}

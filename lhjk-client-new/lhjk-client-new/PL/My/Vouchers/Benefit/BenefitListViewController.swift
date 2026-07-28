import UIKit
import SnapKit

/// 权益卡模块容器 — 对齐 `OrderListViewController`（状态 Tab + 独立子 VC）
final class BenefitListViewController: BaseViewController {

    private struct TabItem {
        let filter: BenefitStatusFilter
        let emptyText: String
        var title: String { filter.title }
    }

    private let tabs: [TabItem] = [
        TabItem(filter: .all, emptyText: "暂无相关权益卡"),
        TabItem(filter: .available, emptyText: "暂无待使用权益卡"),
        TabItem(filter: .redeemed, emptyText: "暂无已兑换权益卡"),
        TabItem(filter: .expired, emptyText: "暂无已过期权益卡"),
        TabItem(filter: .transferRecords, emptyText: "暂无转赠记录"),
    ]

    private var selectedTabIndex = 0
    private var childVCs: [BenefitTabViewController] = []
    private var currentChildVC: BenefitTabViewController?
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
        availableCount = AppContainer.shared.voucherService.availableBenefitCount
        buildChildVCs()
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
        availableCount = AppContainer.shared.voucherService.availableBenefitCount
        tabCollectionView.reloadData()
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
        availableCount = AppContainer.shared.voucherService.availableBenefitCount
        tabCollectionView.reloadData()
        currentChildVC?.refresh()
    }

    private func buildChildVCs() {
        childVCs = tabs.map {
            BenefitTabViewController(filter: $0.filter, emptyText: $0.emptyText)
        }
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

extension BenefitListViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
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

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
        TabItem(filter: .used, emptyTitle: "暂无已使用优惠券"),
        TabItem(filter: .expired, emptyTitle: "暂无已过期优惠券"),
    ]

    private var selectedTabIndex = 0
    private var childVCs: [CouponTabViewController] = []
    private var currentChildVC: CouponTabViewController?
    private var availableCount = 0

    private lazy var tabCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.isScrollEnabled = false
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(CouponFilterTabCell.self, forCellWithReuseIdentifier: CouponFilterTabCell.reuseID)
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
        view.backgroundColor = .white

        let tabContainer = UIView()
        tabContainer.backgroundColor = .white
        view.addSubview(tabContainer)
        tabContainer.addSubview(tabCollectionView)
        tabContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
        tabCollectionView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(6)
        }

        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(tabContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layout = tabCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.invalidateLayout()
        }
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
            withReuseIdentifier: CouponFilterTabCell.reuseID,
            for: indexPath
        ) as! CouponFilterTabCell
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
        let tabWidth = collectionView.bounds.width / CGFloat(tabs.count)
        return CGSize(width: tabWidth, height: 46)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        .zero
    }
}

// MARK: - CouponFilterTabCell

/// 优惠券筛选 Tab — 对齐 Figma 3838:33165
private final class CouponFilterTabCell: UICollectionViewCell {
    static let reuseID = "CouponFilterTabCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .fdFont(ofSize: 16, weight: .regular)
        return label
    }()

    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hexString: "#FF7A50")
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        contentView.addSubview(indicatorView)

        // 标题固定垂直位置；下划线始终占位，选中仅改透明度，避免文字上下跳动
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(2)
            make.leading.greaterThanOrEqualToSuperview().offset(4)
            make.trailing.lessThanOrEqualToSuperview().offset(-4)
        }

        indicatorView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.width.equalTo(18)
            make.height.equalTo(4)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        if isSelected {
            titleLabel.font = .fdFont(ofSize: 16, weight: .medium)
            titleLabel.textColor = UIColor(hexString: "#1F2942")
            indicatorView.alpha = 1
        } else {
            titleLabel.font = .fdFont(ofSize: 16, weight: .regular)
            titleLabel.textColor = UIColor(hexString: "#535D72")
            indicatorView.alpha = 0
        }
    }
}

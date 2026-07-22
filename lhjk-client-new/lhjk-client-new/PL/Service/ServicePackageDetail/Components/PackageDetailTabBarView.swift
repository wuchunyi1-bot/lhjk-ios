import UIKit
import SnapKit

enum PackageDetailTab: Equatable {
    case content
    case detail
}

protocol PackageDetailTabBarViewDelegate: AnyObject {
    func tabBarView(_ view: PackageDetailTabBarView, didSelect tab: PackageDetailTab)
}

final class PackageDetailTabBarView: UIView {

    weak var delegate: PackageDetailTabBarViewDelegate?

    private let contentButton = UIButton(type: .system)
    private let detailButton = UIButton(type: .system)
    private let indicator = UIView()
    private let border = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func setDetailTabVisible(_ visible: Bool) {
        detailButton.isHidden = !visible
        if !visible, detailButton.isSelected {
            select(.content, animated: false)
        }
        invalidateIntrinsicContentSize()
        guard bounds.width > 0 else { return }
        setNeedsLayout()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }

    func select(_ tab: PackageDetailTab, animated: Bool) {
        contentButton.isSelected = tab == .content
        detailButton.isSelected = tab == .detail
        contentButton.titleLabel?.font = tab == .content ? .fdFont(ofSize: 15, weight: .heavy) : .fdBodySemibold
        detailButton.titleLabel?.font = tab == .detail ? .fdFont(ofSize: 15, weight: .heavy) : .fdBodySemibold

        let target = tab == .content ? contentButton : detailButton
        indicator.snp.remakeConstraints {
            $0.bottom.equalToSuperview()
            $0.width.equalTo(32)
            $0.height.equalTo(3)
            $0.centerX.equalTo(target)
        }

        guard animated else { return }
        UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
    }

    private func setupUI() {
        border.backgroundColor = .fdBorder
        addSubview(border)
        border.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }

        configureButton(contentButton, title: "权益", tag: 0)
        configureButton(detailButton, title: "详情", tag: 1)
        contentButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        detailButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [contentButton, detailButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(border.snp.top).offset(-8)
        }

        indicator.backgroundColor = .fdPrimary
        indicator.layer.cornerRadius = 1.5
        addSubview(indicator)
        indicator.snp.makeConstraints {
            $0.bottom.equalToSuperview()
            $0.width.equalTo(32)
            $0.height.equalTo(3)
            $0.centerX.equalTo(contentButton)
        }
    }

    private func configureButton(_ button: UIButton, title: String, tag: Int) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.fdSubtext, for: .normal)
        button.setTitleColor(.fdText, for: .selected)
        button.titleLabel?.font = .fdBodySemibold
        button.tag = tag
    }

    @objc private func tabTapped(_ sender: UIButton) {
        delegate?.tabBarView(self, didSelect: sender.tag == 0 ? .content : .detail)
    }
}

// MARK: - Floors

/// 套餐详情下半区 — 白色卡片内：Tab + 权益楼层 + 详情楼层（连续展示）
final class PackageDetailFloorsView: UIView {

    weak var tabDelegate: PackageDetailTabBarViewDelegate?

    let tabBarView = PackageDetailTabBarView()
    /// 权益楼层锚点（供滚动定位）
    let contentFloorAnchor = UIView()
    /// 详情楼层锚点（供滚动定位）
    let detailFloorAnchor = UIView()
    private let contentStack = UIStackView()
    private let detailView = PackageDetailCardView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(
        package: ServicePackageDetail,
        groups: [ServicePackageComboGroup],
        radioPicks: [String: Int],
        checkPicks: [String: Set<Int>],
        makeGroupView: (ServicePackageComboGroup) -> PackageComboGroupView
    ) {
        let hasDetail = !package.detailImageURLs.isEmpty
        tabBarView.setDetailTabVisible(hasDetail)
        detailView.configure(with: package)
        detailFloorAnchor.isHidden = !hasDetail
        detailView.isHidden = !hasDetail

        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for group in groups {
            contentStack.addArrangedSubview(makeGroupView(group))
        }

        setNeedsLayout()
    }

    /// 楼层锚点在 floorsView 坐标系中的 minY（不含 sticky 扣减）
    func floorMinY(for tab: PackageDetailTab) -> CGFloat? {
        guard bounds.width > 0 else { return nil }
        layoutIfNeeded()
        switch tab {
        case .content:
            return contentFloorAnchor.convert(contentFloorAnchor.bounds, to: self).minY
        case .detail:
            guard !detailFloorAnchor.isHidden else { return nil }
            return detailFloorAnchor.convert(detailFloorAnchor.bounds, to: self).minY
        }
    }

    private func setupUI() {
        backgroundColor = .fdSurface
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8

        tabBarView.delegate = self

        contentStack.axis = .vertical
        contentStack.spacing = 10

        let mainStack = UIStackView(arrangedSubviews: [
            tabBarView,
            contentFloorAnchor,
            contentStack,
            detailFloorAnchor,
            detailView
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 0
        mainStack.isLayoutMarginsRelativeArrangement = true
        mainStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        mainStack.setCustomSpacing(12, after: tabBarView)
        mainStack.setCustomSpacing(12, after: contentStack)
        addSubview(mainStack)

        contentFloorAnchor.snp.makeConstraints { $0.height.equalTo(0) }
        detailFloorAnchor.snp.makeConstraints { $0.height.equalTo(0) }

        mainStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

extension PackageDetailFloorsView: PackageDetailTabBarViewDelegate {
    func tabBarView(_ view: PackageDetailTabBarView, didSelect tab: PackageDetailTab) {
        tabDelegate?.tabBarView(view, didSelect: tab)
    }
}

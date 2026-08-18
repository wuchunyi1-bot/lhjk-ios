import UIKit
import SnapKit

enum PackageDetailTab: Equatable {
    case content
    case detail
}

protocol PackageDetailTabBarViewDelegate: AnyObject {
    func tabBarView(_ view: PackageDetailTabBarView, didSelect tab: PackageDetailTab)
}

/// 套餐详情下半区顶部 Tab 头 — 对齐 Figma 3449:7825 / 3449:7946
final class PackageDetailTabBarView: UIView {

    weak var delegate: PackageDetailTabBarViewDelegate?

    private let watermarkLabel = UILabel()
    private let contentButton = UIButton(type: .custom)
    private let detailButton = UIButton(type: .custom)
    private let indicator = UIView()

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
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }

    func select(_ tab: PackageDetailTab, animated: Bool) {
        contentButton.isSelected = tab == .content
        detailButton.isSelected = tab == .detail
        contentButton.titleLabel?.font = tab == .content ? .fdFont(ofSize: 18, weight: .bold) : .fdFont(ofSize: 16, weight: .regular)
        detailButton.titleLabel?.font = tab == .detail ? .fdFont(ofSize: 18, weight: .bold) : .fdFont(ofSize: 16, weight: .regular)

        let target = tab == .content ? contentButton : detailButton
        indicator.snp.remakeConstraints {
            $0.bottom.equalToSuperview().offset(-4)
            $0.width.equalTo(26)
            $0.height.equalTo(4)
            $0.centerX.equalTo(target)
        }

        guard animated else { return }
        UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
    }

    private func setupUI() {
        clipsToBounds = true

        // 水印文字 BENEFITS
        watermarkLabel.text = "BENEFITS"
        watermarkLabel.font = .fdFont(ofSize: 52, weight: .bold)
        watermarkLabel.textColor = UIColor(hexString: "#FFE9C9").withAlphaComponent(0.35)
        watermarkLabel.transform = CGAffineTransform(shearX: -0.2, y: 0)
        addSubview(watermarkLabel)
        watermarkLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(10)
            $0.centerY.equalToSuperview()
        }

        configureButton(contentButton, title: "权益", tag: 0)
        configureButton(detailButton, title: "详情", tag: 1)
        contentButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        detailButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)

        let buttonsStack = UIStackView(arrangedSubviews: [contentButton, detailButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 16
        buttonsStack.alignment = .center
        addSubview(buttonsStack)
        buttonsStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.top.bottom.equalToSuperview()
        }

        indicator.backgroundColor = UIColor(hexString: "#FD383F")
        indicator.layer.cornerRadius = 2
        addSubview(indicator)
        indicator.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-4)
            $0.width.equalTo(26)
            $0.height.equalTo(4)
            $0.centerX.equalTo(contentButton)
        }

        select(.content, animated: false)
    }

    private func configureButton(_ button: UIButton, title: String, tag: Int) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor(hexString: "#6D7381"), for: .normal)
        button.setTitleColor(UIColor(hexString: "#1F2430"), for: .selected)
        button.titleLabel?.font = .fdFont(ofSize: 16, weight: .regular)
        button.tag = tag
    }

    @objc private func tabTapped(_ sender: UIButton) {
        let tab: PackageDetailTab = sender.tag == 0 ? .content : .detail
        select(tab, animated: true)
        delegate?.tabBarView(self, didSelect: tab)
    }
}

// MARK: - CGAffineTransform Extension

private extension CGAffineTransform {
    init(shearX: CGFloat, y: CGFloat) {
        self.init(a: 1, b: y, c: shearX, d: 1, tx: 0, ty: 0)
    }
}

// MARK: - Floors

/// 套餐详情下半区 — 白色卡片内：Tab + 权益楼层 + 详情全量长图（连续展示）
final class PackageDetailFloorsView: UIView {

    weak var tabDelegate: PackageDetailTabBarViewDelegate?
    var onHeightChanged: (() -> Void)?

    let tabBarView = PackageDetailTabBarView()
    /// 权益楼层锚点（供滚动定位）
    let contentFloorAnchor = UIView()
    /// 详情楼层锚点（供滚动定位）
    let detailFloorAnchor = UIView()
    private let contentStack = UIStackView()
    private let detailView = PackageDetailCardView()
    private let illustImageView = UIImageView()

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

    /// 楼层锚点在 floorsView 坐标系中的 minY
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
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8

        illustImageView.image = UIImage(named: "package_detail_benefits_illust")
        illustImageView.contentMode = .scaleAspectFit
        illustImageView.alpha = 0.4
        illustImageView.isUserInteractionEnabled = false
        addSubview(illustImageView)
        illustImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(-4)
            $0.trailing.equalToSuperview().offset(4)
            $0.size.equalTo(92)
        }

        tabBarView.delegate = self

        contentStack.axis = .vertical
        contentStack.spacing = 12

        detailView.onImagesLoaded = { [weak self] in
            self?.onHeightChanged?()
        }

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
        mainStack.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 16, right: 14)
        mainStack.setCustomSpacing(12, after: tabBarView)
        mainStack.setCustomSpacing(16, after: contentStack)
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


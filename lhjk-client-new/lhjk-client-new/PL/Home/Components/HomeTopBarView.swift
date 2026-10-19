import SnapKit
import UIKit

/// 首页顶栏：当前服务机构、搜索、购物车。只有「切换」进入机构选择。
final class HomeTopBarView: UIView {

    var onInstitutionTap: (() -> Void)?
    var onSearchTap: (() -> Void)?
    var onCartTap: (() -> Void)?

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "order_institution_icon"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 18, weight: .bold)
        l.textColor = .fdText
        l.lineBreakMode = .byTruncatingTail
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()

    private let switchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("切换", for: .normal)
        button.setTitleColor(.fdPrimary, for: .normal)
        button.titleLabel?.font = .fdCaptionSemibold
        button.setImage(UIImage(named: "institution_switch")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.semanticContentAttribute = .forceLeftToRight
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private let addressLabel: UILabel = {
        let l = UILabel()
        l.font = .fdCaption
        l.textColor = .fdSubtext
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let searchButton = UIButton(type: .system)
    private let cartButton = ServiceCartBadgeButton(style: .hub)
    private var heightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg

        let nameRow = UIStackView(arrangedSubviews: [nameLabel, switchButton])
        nameRow.axis = .horizontal
        nameRow.spacing = 4
        nameRow.alignment = .center
        let copy = UIStackView(arrangedSubviews: [nameRow, addressLabel])
        copy.axis = .vertical
        copy.spacing = 2
        copy.alignment = .leading
        copy.setContentHuggingPriority(.required, for: .vertical)
        copy.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(iconView)
        addSubview(copy)

        switchButton.addTarget(self, action: #selector(institutionTapped), for: .touchUpInside)
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.tintColor = .fdText2
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        cartButton.addTarget(self, action: #selector(cartTapped), for: .touchUpInside)
        addSubview(searchButton)
        addSubview(cartButton)

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(nameRow)
            $0.size.equalTo(36)
        }
        copy.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalTo(iconView.snp.trailing).offset(10)
            $0.trailing.equalTo(searchButton.snp.leading).offset(-4)
        }
        cartButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalTo(nameRow)
            $0.size.equalTo(40)
        }
        searchButton.snp.makeConstraints {
            $0.trailing.equalTo(cartButton.snp.leading)
            $0.centerY.equalTo(nameRow)
            $0.size.equalTo(40)
        }
        snp.makeConstraints { make in
            heightConstraint = make.height.equalTo(64).constraint
        }
        apply(name: "请选择服务机构", address: "")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let target = fittedHeight()
        guard abs(target - bounds.height) > 0.5 else { return }
        heightConstraint?.update(offset: target)
    }

    func apply(name: String, address: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        nameLabel.text = trimmedName.isEmpty ? "请选择服务机构" : trimmedName
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        addressLabel.text = trimmedAddress
        addressLabel.isHidden = trimmedAddress.isEmpty
        setNeedsLayout()
    }

    /// 高度只按名称、切换和地址的字号计算，避免被下方列表把地址行拉高。
    private func fittedHeight() -> CGFloat {
        let titleHeight = max(nameLabel.font.lineHeight, switchButton.titleLabel?.font.lineHeight ?? 0)
        let rowHeight = max(36, titleHeight + 16)
        let addressHeight = addressLabel.isHidden ? 0 : (2 + addressLabel.font.lineHeight)
        return ceil(8 + rowHeight + addressHeight + 8)
    }

    func applyCartCount(_ count: Int) {
        cartButton.apply(count: count)
    }

    @objc private func institutionTapped() { onInstitutionTap?() }
    @objc private func searchTapped() { onSearchTap?() }
    @objc private func cartTapped() { onCartTap?() }
}

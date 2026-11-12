import SnapKit
import UIKit

/// 首页顶栏：橙色底、机构名后跟切换图标、地址。点机构区域进入选择。
final class HomeTopBarView: UIView {

    var onInstitutionTap: (() -> Void)?
    var onSearchTap: (() -> Void)?
    var onCartTap: (() -> Void)?

    private let switchIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "institution_switch")?.withRenderingMode(.alwaysTemplate))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(designSize: 19, seniorSize: 23, weight: .semibold)
        l.textColor = .white
        l.lineBreakMode = .byTruncatingTail
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()

    private let addressLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor.white.withAlphaComponent(0.9)
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let searchButton = UIButton(type: .system)
    private let cartButton = ServiceCartBadgeButton(style: .nav)
    private var heightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdPrimary

        let nameRow = UIStackView(arrangedSubviews: [nameLabel, switchIcon])
        nameRow.axis = .horizontal
        nameRow.spacing = 4
        nameRow.alignment = .center
        let copy = UIStackView(arrangedSubviews: [nameRow, addressLabel])
        copy.axis = .vertical
        copy.spacing = 2
        copy.alignment = .leading
        copy.setContentHuggingPriority(.required, for: .horizontal)
        copy.setContentHuggingPriority(.required, for: .vertical)
        copy.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(copy)
        switchIcon.snp.makeConstraints { $0.size.equalTo(CGSize(width: 14, height: 12)) }

        let institutionTap = UIControl()
        institutionTap.addTarget(self, action: #selector(institutionTapped), for: .touchUpInside)
        addSubview(institutionTap)

        searchButton.setImage(.fdNavSearch, for: .normal)
        searchButton.tintColor = .white
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        cartButton.applyTemplateIcon(.fdNavCart, tint: .white)
        cartButton.addTarget(self, action: #selector(cartTapped), for: .touchUpInside)
        addSubview(searchButton)
        addSubview(cartButton)

        copy.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualTo(searchButton.snp.leading).offset(-8)
        }
        institutionTap.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.trailing.equalTo(searchButton.snp.leading)
        }
        cartButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalTo(nameLabel)
            $0.size.equalTo(24)
        }
        searchButton.snp.makeConstraints {
            $0.trailing.equalTo(cartButton.snp.leading).offset(-8)
            $0.centerY.equalTo(nameLabel)
            $0.size.equalTo(24)
        }
        snp.makeConstraints { make in
            heightConstraint = make.height.equalTo(56).constraint
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

    /// 高度只按名称和地址的字号计算，避免被下方列表把地址行拉高。
    private func fittedHeight() -> CGFloat {
        let rowHeight = max(24, nameLabel.font.lineHeight)
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

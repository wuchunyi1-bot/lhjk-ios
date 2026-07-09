import UIKit
import SnapKit

/// 服务首页顶栏 — 机构切换 + 搜索/购物车
/// 对齐 `ServicesView.vue` → `services-header`（UIKit 固定顶栏，等效 Vue sticky）
final class ServiceHubHeaderView: UIView {

    var onInstitutionTap: (() -> Void)?
    var onSearchTap: (() -> Void)?
    var onCartTap: (() -> Void)?

    private let institutionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = .fdH3
        btn.setTitleColor(.fdText, for: .normal)
        btn.contentHorizontalAlignment = .leading
        btn.titleLabel?.lineBreakMode = .byTruncatingTail
        return btn
    }()

    private let chevronView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.down"))
        iv.tintColor = .fdText2
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let searchButton = ServiceHubHeaderView.iconButton(systemName: "magnifyingglass", accessibility: "搜索套餐")
    private let cartButton = ServiceHubHeaderView.iconButton(systemName: "cart", accessibility: "购物车")

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg
        setupLayout()
        institutionButton.addTarget(self, action: #selector(institutionTapped), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        cartButton.addTarget(self, action: #selector(cartTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(institutionName: String, showsInstitutionPicker: Bool = false) {
        institutionButton.setTitle(institutionName, for: .normal)
        chevronView.isHidden = !showsInstitutionPicker
        institutionButton.isUserInteractionEnabled = showsInstitutionPicker
    }

    private func setupLayout() {
        let institutionRow = UIStackView(arrangedSubviews: [institutionButton, chevronView])
        institutionRow.spacing = 2
        institutionRow.alignment = .center

        let actions = UIStackView(arrangedSubviews: [searchButton, cartButton])
        actions.spacing = 8
        actions.alignment = .center

        let bar = UIStackView(arrangedSubviews: [institutionRow, actions])
        bar.distribution = .equalSpacing
        bar.alignment = .center
        addSubview(bar)

        chevronView.snp.makeConstraints { $0.size.equalTo(18) }
        searchButton.snp.makeConstraints { $0.size.equalTo(44) }
        cartButton.snp.makeConstraints { $0.size.equalTo(44) }
        institutionButton.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }

        bar.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        snp.makeConstraints { $0.height.equalTo(52) }
    }

    private static func iconButton(systemName: String, accessibility: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: systemName), for: .normal)
        btn.tintColor = .fdText2
        btn.accessibilityLabel = accessibility
        return btn
    }

    @objc private func institutionTapped() { onInstitutionTap?() }
    @objc private func searchTapped() { onSearchTap?() }
    @objc private func cartTapped() { onCartTap?() }
}

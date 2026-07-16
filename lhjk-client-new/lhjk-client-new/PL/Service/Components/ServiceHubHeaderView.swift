import UIKit
import SnapKit

/// 服务首页顶栏 — 对齐 `ServicesView.vue` → `services-header`
///
/// 左侧固定文案「健康服务」+「德系健康管理 · 9 大产品线」；右侧仅购物车。无搜索、无机构切换。
final class ServiceHubHeaderView: UIView {

    var onCartTap: (() -> Void)?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "健康服务"
        l.font = .fdH3
        l.textColor = .fdText
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "德系健康管理 · 9 大产品线"
        l.font = .fdCaption
        l.textColor = .fdSubtext
        return l
    }()

    private let cartButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "cart"), for: .normal)
        btn.tintColor = .fdText2
        btn.accessibilityLabel = "购物车"
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg
        setupLayout()
        cartButton.addTarget(self, action: #selector(cartTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        let copyStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        copyStack.axis = .vertical
        copyStack.spacing = 2
        copyStack.alignment = .leading

        addSubview(copyStack)
        addSubview(cartButton)

        cartButton.snp.makeConstraints {
            $0.size.equalTo(44)
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
        copyStack.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.lessThanOrEqualTo(cartButton.snp.leading).offset(-12)
            $0.top.bottom.equalToSuperview().inset(6)
        }
        snp.makeConstraints { $0.height.equalTo(56) }
    }

    @objc private func cartTapped() { onCartTap?() }
}

import UIKit
import SnapKit

/// 服务首页顶栏 — 复用 `TabHubBrandHeaderView` + 右侧购物车
final class ServiceHubHeaderView: UIView {

    var onCartTapped: (() -> Void)?

    private let brandHeader = TabHubBrandHeaderView()
    private let cartButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(.fdNavCart, for: .normal)
        b.tintColor = .fdText
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg
        addSubview(brandHeader)
        addSubview(cartButton)
        brandHeader.configure(
            title: "健康服务",
            subtitle: "德系健康管理·9大产品线",
            titleColor: .fdText
        )
        brandHeader.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.trailing.equalTo(cartButton.snp.leading).offset(-8)
        }
        cartButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(brandHeader)
            $0.size.equalTo(24)
        }
        cartButton.addTarget(self, action: #selector(cartTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func cartTapped() {
        onCartTapped?()
    }
}

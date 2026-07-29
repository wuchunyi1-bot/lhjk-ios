import UIKit
import SnapKit

/// 服务首页顶栏 — 复用 `TabHubBrandHeaderView`
final class ServiceHubHeaderView: UIView {

    private let brandHeader = TabHubBrandHeaderView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg
        addSubview(brandHeader)
        brandHeader.configure(
            title: "健康服务",
            subtitle: "德系健康管理 · 9 大产品线",
            titleColor: .fdText
        )
        brandHeader.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }
}

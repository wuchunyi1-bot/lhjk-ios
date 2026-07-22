import UIKit
import SnapKit

/// 服务首页顶栏 — 对齐 `ServicesView.vue` → `services-header`
///
/// 左侧固定文案「健康服务」+「德系健康管理 · 9 大产品线」；无搜索、无机构切换、无购物车。
/// 购物车入口仅保留：选择套餐页导航栏、「我的」金刚区。
final class ServiceHubHeaderView: UIView {

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        let copyStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        copyStack.axis = .vertical
        copyStack.spacing = 2
        copyStack.alignment = .leading

        addSubview(copyStack)
        copyStack.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview().inset(6)
        }
        snp.makeConstraints { $0.height.equalTo(56) }
    }
}

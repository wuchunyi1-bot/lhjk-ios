import UIKit
import SnapKit

/// 竖排风险等级显示（3 行 label + 彩色数字）
/// 参考 funde-client: hp-risk-col
final class RiskBarView: UIView {

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(items: [RiskItem]) {
        subviews.forEach { $0.removeFromSuperview() }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .leading
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        for item in items {
            let itemView = buildRiskItem(item)
            stack.addArrangedSubview(itemView)
        }
    }

    private func buildRiskItem(_ item: RiskItem) -> UIView {
        let container = UIView()

        let label = UILabel()
        label.text = item.label
        label.font = .fdMicro
        label.textColor = .fdSubtext

        let countLabel = UILabel()
        countLabel.text = "\(item.count)"
        countLabel.font = .fdMonoFont(ofSize: 26, weight: .bold)
        countLabel.textColor = item.color

        container.addSubview(label)
        container.addSubview(countLabel)

        label.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        countLabel.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(2)
            make.leading.trailing.bottom.equalToSuperview()
        }

        return container
    }
}

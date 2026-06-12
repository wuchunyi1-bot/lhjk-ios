import UIKit
import SnapKit

/// 通用功能行 — icon + label + detail + chevron
/// 参考 funde-client: fd-func-row
final class FuncRowView: UIView {

    // MARK: - UI

    private let iconContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .fdText
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .fdMuted
        label.textAlignment = .right
        return label
    }()

    private let arrowImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = .fdMuted
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .fdBorder
        return view
    }()

    /// 用于路由匹配的标题
    let routeTitle: String

    // MARK: - Init

    init(
        icon: String,
        iconColor: UIColor,
        title: String,
        detail: String? = nil,
        showDivider: Bool = true
    ) {
        self.routeTitle = title

        super.init(frame: .zero)

        iconContainer.backgroundColor = iconColor.withAlphaComponent(0.10)
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = iconColor
        titleLabel.text = title
        detailLabel.text = detail
        detailLabel.isHidden = (detail == nil)
        dividerView.isHidden = !showDivider

        setupUI()
        setupTap()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(detailLabel)
        addSubview(arrowImageView)
        addSubview(dividerView)

        iconContainer.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(32)
        }
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(detailLabel.snp.leading).offset(-8)
        }
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        arrowImageView.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        detailLabel.snp.makeConstraints { make in
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
        }

        dividerView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }

        self.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
    }

    private func setupTap() {
        isUserInteractionEnabled = true
    }
}

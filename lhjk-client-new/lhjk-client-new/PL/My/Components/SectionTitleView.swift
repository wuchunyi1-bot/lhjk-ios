import UIKit
import SnapKit

/// 区块标题行 — 左侧标题 + 右侧可选"更多"链接
/// 参考 funde-client: fd-section-title
final class SectionTitleView: UIView {

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .fdSubtext
        return label
    }()

    private let moreButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = .systemFont(ofSize: 13)
        btn.setTitleColor(.fdSubtext, for: .normal)
        return btn
    }()

    var onMoreTapped: (() -> Void)?

    // MARK: - Init

    init(title: String, more: String? = nil) {
        super.init(frame: .zero)

        titleLabel.text = title

        if let more = more {
            moreButton.setTitle(more, for: .normal)
            moreButton.addTarget(self, action: #selector(moreTap), for: .touchUpInside)
            moreButton.isHidden = false
        } else {
            moreButton.isHidden = true
        }

        addSubview(titleLabel)
        addSubview(moreButton)

        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        moreButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        self.snp.makeConstraints { make in
            make.height.equalTo(28)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func moreTap() {
        onMoreTapped?()
    }
}

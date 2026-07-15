import UIKit
import SnapKit

enum PackageDetailTab: Equatable {
    case content
    case detail
}

protocol PackageDetailTabBarViewDelegate: AnyObject {
    func tabBarView(_ view: PackageDetailTabBarView, didSelect tab: PackageDetailTab)
}

final class PackageDetailTabBarView: UIView {

    weak var delegate: PackageDetailTabBarViewDelegate?

    private let contentButton = UIButton(type: .system)
    private let detailButton = UIButton(type: .system)
    private let indicator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func select(_ tab: PackageDetailTab, animated: Bool) {
        contentButton.isSelected = tab == .content
        detailButton.isSelected = tab == .detail
        contentButton.titleLabel?.font = tab == .content ? .fdFont(ofSize: 15, weight: .heavy) : .fdBodySemibold
        detailButton.titleLabel?.font = tab == .detail ? .fdFont(ofSize: 15, weight: .heavy) : .fdBodySemibold

        let target = tab == .content ? contentButton : detailButton
        indicator.snp.remakeConstraints {
            $0.bottom.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(3)
            $0.centerX.equalTo(target)
        }

        guard animated else { return }
        UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
    }

    private func setupUI() {
        let border = UIView()
        border.backgroundColor = .fdBorder
        addSubview(border)
        border.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(2)
        }

        configureButton(contentButton, title: "套餐内容", tag: 0)
        configureButton(detailButton, title: "套餐详情", tag: 1)
        contentButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        detailButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [contentButton, detailButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }

        indicator.backgroundColor = .fdPrimary
        indicator.layer.cornerRadius = 1.5
        addSubview(indicator)
        indicator.snp.makeConstraints {
            $0.bottom.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(3)
            $0.centerX.equalTo(contentButton)
        }
    }

    private func configureButton(_ button: UIButton, title: String, tag: Int) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.fdSubtext, for: .normal)
        button.setTitleColor(.fdText, for: .selected)
        button.titleLabel?.font = .fdBodySemibold
        button.tag = tag
    }

    @objc private func tabTapped(_ sender: UIButton) {
        delegate?.tabBarView(self, didSelect: sender.tag == 0 ? .content : .detail)
    }
}

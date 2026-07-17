import UIKit
import SnapKit

final class PackageDetailOrderBarView: UIView {

    var onAddToCart: (() -> Void)?
    var onOrder: (() -> Void)?

    private let payableLabel = UILabel()
    private let cartButton = UIButton(type: .system)
    private let orderButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func setPayableText(_ text: String) {
        payableLabel.text = text
    }

    func setActionsEnabled(_ enabled: Bool) {
        cartButton.isEnabled = enabled
        orderButton.isEnabled = enabled
        cartButton.alpha = enabled ? 1 : 0.5
        orderButton.alpha = enabled ? 1 : 0.5
    }

    func attach(to parent: UIView, below scrollView: UIView) {
        parent.addSubview(self)
        snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview() }
        scrollView.snp.remakeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.snp.top)
        }
    }

    private func setupUI() {
        backgroundColor = UIColor.fdSurface.withAlphaComponent(0.96)

        let border = UIView()
        border.backgroundColor = .fdBorder
        addSubview(border)
        border.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }

        let tip = UILabel()
        tip.text = "应付"
        tip.font = .fdMicro
        tip.textColor = .fdSubtext
        payableLabel.font = .fdMonoFont(ofSize: 20, weight: .heavy)
        payableLabel.textColor = .fdPrimary
        let priceStack = UIStackView(arrangedSubviews: [tip, payableLabel])
        priceStack.axis = .vertical
        priceStack.spacing = 2

        cartButton.setTitle("加入购物车", for: .normal)
        cartButton.setTitleColor(.fdPrimary, for: .normal)
        cartButton.titleLabel?.font = .fdBody
        cartButton.layer.cornerRadius = 22
        cartButton.layer.borderWidth = 1
        cartButton.layer.borderColor = UIColor.fdPrimary.cgColor
        cartButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        cartButton.addTarget(self, action: #selector(tapCart), for: .touchUpInside)

        orderButton.setTitle("立即下单", for: .normal)
        orderButton.setTitleColor(.white, for: .normal)
        orderButton.titleLabel?.font = .fdBodySemibold
        orderButton.backgroundColor = .fdPrimary
        orderButton.layer.cornerRadius = 22
        orderButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        orderButton.addTarget(self, action: #selector(tapOrder), for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [cartButton, orderButton])
        actions.axis = .horizontal
        actions.spacing = 10
        cartButton.snp.makeConstraints { $0.height.equalTo(44) }
        orderButton.snp.makeConstraints { $0.height.equalTo(44) }

        addSubview(priceStack)
        addSubview(actions)
        priceStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(actions)
        }
        actions.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(10)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-10)
            $0.leading.greaterThanOrEqualTo(priceStack.snp.trailing).offset(12)
        }
    }

    @objc private func tapCart() { onAddToCart?() }
    @objc private func tapOrder() { onOrder?() }
}

import UIKit
import SnapKit

final class PackageDetailOrderBarView: UIView {

    var onAddToCart: (() -> Void)?
    var onOrder: (() -> Void)?

    private let payableLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func setPayableText(_ text: String) {
        payableLabel.text = text
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

        let cart = UIButton(type: .system)
        cart.setTitle("加入购物车", for: .normal)
        cart.setTitleColor(.fdPrimary, for: .normal)
        cart.titleLabel?.font = .fdBody
        cart.layer.cornerRadius = 22
        cart.layer.borderWidth = 1
        cart.layer.borderColor = UIColor.fdPrimary.cgColor
        cart.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        cart.addTarget(self, action: #selector(tapCart), for: .touchUpInside)

        let order = UIButton(type: .system)
        order.setTitle("立即下单", for: .normal)
        order.setTitleColor(.white, for: .normal)
        order.titleLabel?.font = .fdBodySemibold
        order.backgroundColor = .fdPrimary
        order.layer.cornerRadius = 22
        order.contentEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        order.addTarget(self, action: #selector(tapOrder), for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [cart, order])
        actions.axis = .horizontal
        actions.spacing = 10
        cart.snp.makeConstraints { $0.height.equalTo(44) }
        order.snp.makeConstraints { $0.height.equalTo(44) }

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

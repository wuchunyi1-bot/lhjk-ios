import UIKit
import SnapKit

/// 套餐详情底部操作栏 — 对齐 Figma 3449:7811
final class PackageDetailOrderBarView: UIView {

    var onAddToCart: (() -> Void)?
    var onOrder: (() -> Void)?

    private let tipLabel = UILabel()
    private let symbolLabel = UILabel()
    private let payableLabel = UILabel()
    private let cartButton = UIButton(type: .system)
    private let orderButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func setPayableText(_ text: String) {
        // 分离 "¥" 和数字
        let cleaned = text.replacingOccurrences(of: "¥", with: "").trimmingCharacters(in: .whitespaces)
        payableLabel.text = cleaned
    }

    func configure(renewalMode: Bool) {
        tipLabel.text = renewalMode ? "续费金额" : "应付"
        cartButton.setTitle(renewalMode ? "取消" : "加入购物车", for: .normal)
        orderButton.setTitle(renewalMode ? "立即续费" : "立即下单", for: .normal)
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
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        let topBorder = UIView()
        topBorder.backgroundColor = UIColor(hexString: "#F0F2F5")
        addSubview(topBorder)
        topBorder.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        tipLabel.font = .fdFont(ofSize: 16, weight: .regular)
        tipLabel.textColor = .fdText
        tipLabel.text = "应付"

        symbolLabel.font = .fdFont(ofSize: 16, weight: .medium)
        symbolLabel.textColor = UIColor(hexString: "#F93838")
        symbolLabel.text = "¥"

        payableLabel.font = .fdMonoFont(ofSize: 20, weight: .bold)
        payableLabel.textColor = UIColor(hexString: "#F93838")

        let priceRow = UIStackView(arrangedSubviews: [symbolLabel, payableLabel])
        priceRow.axis = .horizontal
        priceRow.spacing = 2
        priceRow.alignment = .lastBaseline

        let priceStack = UIStackView(arrangedSubviews: [tipLabel, priceRow])
        priceStack.axis = .vertical
        priceStack.spacing = 2
        priceStack.alignment = .leading

        let brandOrange = UIColor(hexString: "#FF7A50")

        cartButton.setTitle("加入购物车", for: .normal)
        cartButton.setTitleColor(brandOrange, for: .normal)
        cartButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        cartButton.backgroundColor = .white
        cartButton.layer.cornerRadius = 20
        cartButton.layer.borderWidth = 1
        cartButton.layer.borderColor = brandOrange.cgColor
        cartButton.addTarget(self, action: #selector(tapCart), for: .touchUpInside)

        orderButton.setTitle("立即下单", for: .normal)
        orderButton.setTitleColor(.white, for: .normal)
        orderButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        orderButton.backgroundColor = brandOrange
        orderButton.layer.cornerRadius = 20
        orderButton.addTarget(self, action: #selector(tapOrder), for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [cartButton, orderButton])
        actions.axis = .horizontal
        actions.spacing = 8
        actions.distribution = .fillEqually
        cartButton.snp.makeConstraints {
            $0.width.equalTo(112)
            $0.height.equalTo(40)
        }
        orderButton.snp.makeConstraints {
            $0.width.equalTo(112)
            $0.height.equalTo(40)
        }

        addSubview(priceStack)
        addSubview(actions)

        priceStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(actions)
        }
        actions.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-8)
            $0.leading.greaterThanOrEqualTo(priceStack.snp.trailing).offset(8)
        }
    }

    @objc private func tapCart() { onAddToCart?() }
    @objc private func tapOrder() { onOrder?() }
}


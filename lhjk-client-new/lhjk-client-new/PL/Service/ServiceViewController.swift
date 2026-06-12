import UIKit
import SnapKit

/// 服务模块入口 — 支付等服务入口
final class ServiceViewController: BaseViewController {
    override func setupUI() {
        title = "服务"

        let label = UILabel()
        label.text = "服务"
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        view.addSubview(label)

        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-30)
        }

        let paymentButton = UIButton(type: .system)
        paymentButton.setTitle("测试支付 ¥0.01", for: .normal)
        paymentButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        paymentButton.addAction(UIAction { [weak self] _ in
            let vc = PaymentViewController(
                productId: "test_product_001",
                productName: "测试商品",
                amount: 1
            )
            self?.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)
        view.addSubview(paymentButton)

        paymentButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(label.snp.bottom).offset(30)
        }
    }
}

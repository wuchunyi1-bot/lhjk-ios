import UIKit
import SnapKit

/// 健康模块入口 — 蓝牙设备列表
final class HealthViewController: BaseViewController {
    override func setupUI() {
        title = "健康"

        let label = UILabel()
        label.text = "健康"
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        view.addSubview(label)

        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

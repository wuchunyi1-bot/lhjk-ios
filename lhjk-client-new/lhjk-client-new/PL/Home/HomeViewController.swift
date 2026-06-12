import UIKit
import SnapKit

/// 首页模块入口
final class HomeViewController: BaseViewController {
    override func setupUI() {
        title = "首页"

        let label = UILabel()
        label.text = "首页"
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        view.addSubview(label)

        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

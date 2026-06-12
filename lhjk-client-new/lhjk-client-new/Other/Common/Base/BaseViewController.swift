import UIKit

/// 基础视图控制器 — 提供通用 UI 配置入口
class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        bindViewModel()
    }

    /// 子类重写以配置 UI 外观
    func setupUI() {}

    /// 子类重写以绑定 ViewModel 数据
    func bindViewModel() {}
}

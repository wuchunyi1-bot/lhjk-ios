import UIKit

/// Presentation Layer 基础协议
protocol PLProtocol: AnyObject {
    associatedtype ViewModel

    /// BLL 层提供的 ViewModel
    var viewModel: ViewModel? { get set }

    /// 绑定 ViewModel 数据到 UI
    func bindViewModel()

    /// 配置 UI 外观
    func setupUI()
}

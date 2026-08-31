import UIKit

/// 基础导航控制器 — 统一配置导航栏外观，自动处理 TabBar 显隐
class BaseNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        // 当导航栈深度 >= 1 时（即 push 的是二级及以上页面），自动隐藏 TabBar
        if viewControllers.count >= 1 {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }

    private func configureAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .fdBg
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.fdText,
            .font: UIFont.fdFont(ofSize: 20, weight: .medium)
        ]

        // 全局返回箭头：使用选择套餐页 Figma 返回图标，并隐藏系统返回文案
        let backImage = UIImage.fdNavBack
        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        backButtonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.backButtonAppearance = backButtonAppearance

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = .fdText
        navigationBar.isTranslucent = false
    }
}

extension UIImage {
    /// Figma 导航栏返回箭头（全局统一）
    static var fdNavBack: UIImage? {
        UIImage(named: "nav_back")?.withRenderingMode(.alwaysTemplate)
    }

    /// Figma 导航栏搜索图标
    static var fdNavSearch: UIImage? {
        UIImage(named: "nav_search")?.withRenderingMode(.alwaysTemplate)
    }

    /// Figma 导航栏购物车图标
    static var fdNavCart: UIImage? {
        UIImage(named: "nav_cart")?.withRenderingMode(.alwaysTemplate)
    }

    /// 聊天详情右上角查看群成员（Figma 4497:4551）
    static var fdNavGroupMembers: UIImage? {
        UIImage(named: "chat_nav_group_members")?.withRenderingMode(.alwaysOriginal)
    }

    /// 服务首页顶栏购物车（彩色切图 `serice_cart`）
    static var fdServiceHubCart: UIImage? {
        fdServiceHubCart(pointSize: 32)
    }

    /// 按展示尺寸缩放 `serice_cart`（切图留白较多，需略大于线框导航图标）
    static func fdServiceHubCart(pointSize: CGFloat) -> UIImage? {
        guard let image = UIImage(named: "serice_cart") else { return nil }
        let size = CGSize(width: pointSize, height: pointSize)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

import UIKit

/// 基础视图控制器 — 提供通用 UI 配置入口 + 老年模式自动刷新
class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        bindViewModel()

        // 监听老年模式变更通知，收到后即时刷新，避免每次 viewWillAppear 都触发
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSeniorModeChanged),
            name: UIFont.seniorModeDidChangeNotification,
            object: nil
        )
    }

    /// 子类重写以配置 UI 外观
    func setupUI() {}

    /// 子类重写以绑定 ViewModel 数据
    func bindViewModel() {}

    @objc private func onSeniorModeChanged() {
        guard isViewLoaded else { return }
        refreshForSeniorMode()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// 老年模式变更时的刷新方法。
    /// 已显示的文字按字体上记下的设计字号，对照本地 `isSeniorMode` 重算，不根据当前点值猜。
    /// 子类可重写，并调用 super。
    func refreshForSeniorMode() {
        view.refreshAllLabelFonts()
        navigationController?.navigationBar.refreshAllLabelFonts()
        tabBarController?.tabBar.refreshAllLabelFonts()
        view.invalidateTableAndCollectionLayouts()
    }
}

// MARK: - Senior Mode Helpers

extension UIView {

    /// 递归失效所有 UITableView / UICollectionView 布局（不重建 cell，只重算行高）
    func invalidateTableAndCollectionLayouts() {
        for subview in subviews {
            subview.invalidateTableAndCollectionLayouts()
        }
        if let tv = self as? UITableView {
            tv.beginUpdates()
            tv.endUpdates()
        }
        if let cv = self as? UICollectionView {
            cv.collectionViewLayout.invalidateLayout()
        }
    }

    /// 按字体上记下的设计字号，用本地长辈模式重算。没有记录的系统字不动。
    func refreshAllLabelFonts() {
        if let label = self as? UILabel {
            label.fd_refreshSeniorFont()
        } else if let button = self as? UIButton {
            button.fd_refreshSeniorChrome()
        } else if let field = self as? UITextField {
            field.fd_refreshSeniorFont()
        } else if let textView = self as? UITextView {
            textView.fd_refreshSeniorFont()
        }

        for subview in subviews {
            subview.refreshAllLabelFonts()
        }
    }
}

extension UILabel {
    func fd_refreshSeniorFont() {
        guard fd_beginSeniorRefresh(on: self) else { return }
        defer { fd_endSeniorRefresh(on: self) }
        let next = fd_fontForSeniorRefresh()
        if next !== font {
            font = next
        }
        guard let attributed = attributedText, attributed.length > 0 else { return }
        let updated = attributed.fdRefreshingSeniorFonts()
        if updated !== attributed {
            attributedText = updated
        }
    }
}

extension UITextField {
    func fd_refreshSeniorFont() {
        guard fd_beginSeniorRefresh(on: self) else { return }
        defer { fd_endSeniorRefresh(on: self) }
        if let next = fd_fontForSeniorRefresh(), next !== font {
            font = next
        }
        if let attributed = attributedText, attributed.length > 0 {
            let updated = attributed.fdRefreshingSeniorFonts()
            if updated !== attributed {
                attributedText = updated
            }
        }
        if let placeholder = attributedPlaceholder, placeholder.length > 0 {
            let updated = placeholder.fdRefreshingSeniorFonts()
            if updated !== placeholder {
                attributedPlaceholder = updated
            }
        }
    }
}

extension UITextView {
    func fd_refreshSeniorFont() {
        guard fd_beginSeniorRefresh(on: self) else { return }
        defer { fd_endSeniorRefresh(on: self) }
        if let next = fd_fontForSeniorRefresh(), next !== font {
            font = next
        }
        guard let attributed = attributedText, attributed.length > 0 else { return }
        let updated = attributed.fdRefreshingSeniorFonts()
        if updated !== attributed {
            attributedText = updated
        }
    }
}

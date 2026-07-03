import UIKit

/// 基础视图控制器 — 提供通用 UI 配置入口 + 老年模式自动刷新
class BaseViewController: UIViewController {

    /// 记录上次渲染时的 seniorModeVersion，初始 -1 保证首次 viewWillAppear 一定触发检查
    private var lastSeniorVersion: Int = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // 老年模式变更（含冷启动恢复）→ 自动刷新当前页字体
        guard UIFont.seniorModeVersion != lastSeniorVersion else { return }
        lastSeniorVersion = UIFont.seniorModeVersion

        // 在转场动画中操作 tableView beginUpdates/endUpdates 会 crash，
        // 延迟到转场完成后再刷新
        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                self.refreshForSeniorMode()
            }
        } else {
            refreshForSeniorMode()
        }
    }

    /// 子类重写以配置 UI 外观
    func setupUI() {}

    /// 子类重写以绑定 ViewModel 数据
    func bindViewModel() {}

    /// 老年模式变更时的刷新方法
    /// 策略：不在 cell 层面做 destroy/recreate（开销大、浪费）
    ///   1. 递归遍历所有 UILabel / UIButton / UITextField，按字号映射表原地替换字体（O(n)，不销毁视图）
    ///   2. 失效 table/collection view 布局，触发行高重算（不重建 cell，只调 heightForRow）
    /// 子类可重写以添加自定义刷新逻辑（如重建 table header）
    func refreshForSeniorMode() {
        // 先失效布局让 cell 重建（token 字体自动拿正确值），再映射非 token 字号
        view.invalidateTableAndCollectionLayouts()
        view.refreshAllLabelFonts()
    }
}

// MARK: - Senior Mode Helpers

/// 标准 ↔ 老年 字号映射表（双向）
private let seniorFontSizeMap: [(standard: CGFloat, senior: CGFloat)] = [
    (10, 13),  // 未使用 token 的硬编码小字号（roleTag / timeLabel / badge 等）
    (11, 14),  // fdMicro
    (12, 15),  // 未使用 token 的硬编码字号（previewLabel 等）
    (13, 16),  // fdCaption
    (14, 18),  // 介于 caption~body 的 monospaced 数字
    (15, 19),  // fdBody
    (16, 20),  // 商品价格 monospaced 数字
    (18, 22),  // fdH3
    (22, 26),  // fdH2
    (28, 34),  // fdH1
    (36, 44),  // fdNumL
    (56, 64),  // fdNumXL
]

/// 根据当前 senior 模式，将字号映射为目标字号
private func mapFontSize(_ size: CGFloat, toSenior: Bool) -> CGFloat {
    for pair in seniorFontSizeMap {
        if toSenior && abs(size - pair.standard) < 0.5 {
            return pair.senior
        }
        if !toSenior && abs(size - pair.senior) < 0.5 {
            return pair.standard
        }
    }
    return size // 不在映射表中的字号不变（如特殊装饰尺寸）
}

/// 从 UIFont 提取 weight
private func fontWeight(from font: UIFont) -> UIFont.Weight {
    let traits = font.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
    let raw = (traits?[.weight] as? NSNumber)?.floatValue ?? 0
    return UIFont.Weight(rawValue: CGFloat(raw))
}

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

    /// 递归遍历所有 UILabel / UIButton / UITextField，按字号映射表替换字体
    /// 保留原字体的 weight 和 monospaced trait
    func refreshAllLabelFonts() {
        let toSenior = UIFont.isSeniorMode

        func applyMappedFont(to label: UILabel) {
            guard let oldFont = label.font else { return }
            let oldSize = oldFont.pointSize
            let newSize = mapFontSize(oldSize, toSenior: toSenior)
            guard (newSize - oldSize).magnitude > 0.5 else { return }

            let weight = fontWeight(from: oldFont)
            let isMono = oldFont.fontDescriptor.symbolicTraits.contains(.traitMonoSpace)
            label.font = isMono
                ? UIFont.fdMonoFont(ofSize: newSize, weight: weight)
                : UIFont.fdFont(ofSize: newSize, weight: weight)
        }

        if let label = self as? UILabel {
            applyMappedFont(to: label)

        } else if let btn = self as? UIButton {
            if let oldFont = btn.titleLabel?.font {
                let oldSize = oldFont.pointSize
                let newSize = mapFontSize(oldSize, toSenior: toSenior)
                if (newSize - oldSize).magnitude > 0.5 {
                    let weight = fontWeight(from: oldFont)
                    let isMono = oldFont.fontDescriptor.symbolicTraits.contains(.traitMonoSpace)
                    btn.titleLabel?.font = isMono
                        ? UIFont.fdMonoFont(ofSize: newSize, weight: weight)
                        : UIFont.fdFont(ofSize: newSize, weight: weight)
                }
            }

        } else if let tf = self as? UITextField {
            if let oldFont = tf.font {
                let oldSize = oldFont.pointSize
                let newSize = mapFontSize(oldSize, toSenior: toSenior)
                if (newSize - oldSize).magnitude > 0.5 {
                    let weight = fontWeight(from: oldFont)
                    let isMono = oldFont.fontDescriptor.symbolicTraits.contains(.traitMonoSpace)
                    tf.font = isMono
                        ? UIFont.fdMonoFont(ofSize: newSize, weight: weight)
                        : UIFont.fdFont(ofSize: newSize, weight: weight)
                }
            }
        }

        // 递归子视图
        for subview in subviews {
            subview.refreshAllLabelFonts()
        }
    }
}

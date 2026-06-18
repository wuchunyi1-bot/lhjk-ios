import UIKit

/// funde-client Design Token 字体映射
/// 来源: funde-client prototype/src/styles/tokens.css + docs/design/design-system.md
/// 规则: 禁止直接写 systemFont(ofSize:)，所有字号通过 Token 引用
extension UIFont {

    // MARK: - Font Family Stack

    /// 主字体栈 — PingFang SC (iOS 中文系统默认)
    /// CSS: "PingFang SC", -apple-system, "Helvetica Neue", "Segoe UI", "Microsoft YaHei", sans-serif
    /// iOS 上 systemFont 默认即为 PingFang SC（中文），等价于 CSS 中的 --fd-font
    static func fdFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        return .systemFont(ofSize: size, weight: weight)
    }

    /// 等宽数字字体 — SF Mono
    /// CSS: "SF Mono", "DIN Alternate", "PingFang SC", monospace
    /// 用于健康指标数值、统计数字展示，确保数字等宽对齐
    static func fdMonoFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let base = UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
        let desc = base.fontDescriptor.withDesign(.monospaced) ?? base.fontDescriptor
        return UIFont(descriptor: desc, size: size)
    }

    // MARK: - Senior Mode

    /// 老年模式存储键
    private static let seniorModeKey = "fd_senior_mode"

    /// 老年模式存储（兼容 Swift 5.0，避免 concurrency 限制）
    private struct SeniorMode {
        static var enabled: Bool = UserDefaults.standard.bool(forKey: UIFont.seniorModeKey)
    }

    /// 老年模式变更通知
    static let seniorModeDidChangeNotification = Notification.Name("UIFontSeniorModeDidChange")

    /// 老年模式版本号，每次变更 +1，VC 在 viewWillAppear 中对比判断是否需要刷新
    static private(set) var seniorModeVersion: Int = 0

    /// 老年模式开关，对齐 funde-client `<div data-senior="true">`
    /// 开启后所有 fd* Token 字号自动放大
    /// 状态持久化到 UserDefaults，变更时发送通知，递增版本号
    static var isSeniorMode: Bool {
        get { SeniorMode.enabled }
        set {
            guard SeniorMode.enabled != newValue else { return }
            SeniorMode.enabled = newValue
            seniorModeVersion += 1
            UserDefaults.standard.set(newValue, forKey: seniorModeKey)
            NotificationCenter.default.post(name: seniorModeDidChangeNotification, object: nil)
        }
    }

    /// 是否在老年模式下（取全局开关）
    private static var senior: Bool { isSeniorMode }

    // MARK: - Type Scale: Headings

    /// 页面大标题 — 标准 28pt / 老年 34pt，`.bold`
    /// CSS: --fd-h1
    static var fdH1: UIFont {
        .fdFont(ofSize: senior ? 34 : 28, weight: .bold)
    }

    /// 区块标题 / Topbar 标题 — 标准 22pt / 老年 26pt，`.bold`
    /// CSS: --fd-h2
    static var fdH2: UIFont {
        .fdFont(ofSize: senior ? 26 : 22, weight: .bold)
    }

    /// 小节标题 / 卡片标题 — 标准 18pt / 老年 22pt，`.semibold`
    /// CSS: --fd-h3
    static var fdH3: UIFont {
        .fdFont(ofSize: senior ? 22 : 18, weight: .semibold)
    }
    /// 小节标题 Regular 变体
    static var fdH3Regular: UIFont {
        .fdFont(ofSize: senior ? 22 : 18, weight: .regular)
    }

    // MARK: - Type Scale: Body

    /// 正文 / 列表项 — 标准 15pt / 老年 19pt，`.regular`
    /// CSS: --fd-body
    static var fdBody: UIFont {
        .fdFont(ofSize: senior ? 19 : 15, weight: .regular)
    }

    /// 正文 Semibold 变体 — 按钮文字、列表行主标签
    static var fdBodySemibold: UIFont {
        .fdFont(ofSize: senior ? 19 : 15, weight: .semibold)
    }

    /// 正文 Bold 变体 — 强调正文
    static var fdBodyBold: UIFont {
        .fdFont(ofSize: senior ? 19 : 15, weight: .bold)
    }

    // MARK: - Type Scale: Caption

    /// 说明文字 / 辅助标签 — 标准 13pt / 老年 16pt，`.regular`
    /// CSS: --fd-caption
    static var fdCaption: UIFont {
        .fdFont(ofSize: senior ? 16 : 13, weight: .regular)
    }

    /// 说明文字 Semibold 变体 — 卡片内小标题、功能标签
    static var fdCaptionSemibold: UIFont {
        .fdFont(ofSize: senior ? 16 : 13, weight: .semibold)
    }

    // MARK: - Type Scale: Micro

    /// 最小级别 — 标准 11pt / 老年 14pt，`.regular`
    /// CSS: --fd-micro — badge 文字、角标、元信息
    static var fdMicro: UIFont {
        .fdFont(ofSize: senior ? 14 : 11, weight: .regular)
    }

    /// 最小级别 Semibold 变体 — 小标签、设备名
    static var fdMicroSemibold: UIFont {
        .fdFont(ofSize: senior ? 14 : 11, weight: .semibold)
    }

    /// 最小级别 Bold 变体 — badge 内数字
    static var fdMicroBold: UIFont {
        .fdFont(ofSize: senior ? 14 : 11, weight: .bold)
    }

    // MARK: - Type Scale: Numbers (Mono)

    /// 超大数字 — 标准 56pt / 老年 64pt，`.bold`，等宽
    /// CSS: --fd-num-xl — 健康评分
    static var fdNumXL: UIFont {
        .fdMonoFont(ofSize: senior ? 64 : 56, weight: .bold)
    }

    /// 大数字 — 标准 36pt / 老年 44pt，`.bold`，等宽
    /// CSS: --fd-num-l — 关键指标读数
    static var fdNumL: UIFont {
        .fdMonoFont(ofSize: senior ? 44 : 36, weight: .bold)
    }

    /// 中数字 — 标准 22pt / 老年 26pt，`.bold`，等宽
    /// CSS: --fd-num-m — 统计数值、趋势值
    static var fdNumM: UIFont {
        .fdMonoFont(ofSize: senior ? 26 : 22, weight: .bold)
    }
}

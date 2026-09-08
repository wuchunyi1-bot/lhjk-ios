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

    /// 等宽数字字体 — SF Mono。仅表格/列表竖向对齐时使用，指标读数请用 `fdFont` / `fdNum*`。
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
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: seniorModeDidChangeNotification, object: nil)
            }
        }
    }

    /// 是否在老年模式下（取全局开关）
    private static var senior: Bool { isSeniorMode }

    // MARK: - Type Scale: Headings

    /// 页面大标题 — 标准 30pt / 老年 36pt，`.bold`
    /// CSS: --fd-h1
    static var fdH1: UIFont {
        .fdFont(ofSize: senior ? 36 : 30, weight: .bold)
    }

    /// 区块标题 / Topbar 标题 — 标准 24pt / 老年 28pt，`.bold`
    /// CSS: --fd-h2
    static var fdH2: UIFont {
        .fdFont(ofSize: senior ? 28 : 24, weight: .bold)
    }

    /// 小节标题 / 卡片标题 — 标准 20pt / 老年 24pt，`.semibold`
    /// CSS: --fd-h3
    static var fdH3: UIFont {
        .fdFont(ofSize: senior ? 24 : 20, weight: .semibold)
    }
    /// 小节标题 Regular 变体
    static var fdH3Regular: UIFont {
        .fdFont(ofSize: senior ? 24 : 20, weight: .regular)
    }

    // MARK: - Login Figma

    /// Figma 登录页品牌标题；工程未内置 DingTalk JinBuTi 时回退系统粗体。
    static var fdLoginTitle: UIFont {
        UIFont(name: "DingTalk JinBuTi", size: senior ? 40 : 34)
            ?? .fdFont(ofSize: senior ? 40 : 34, weight: .bold)
    }

    /// Figma 登录页输入与标签（16pt）。
    static var fdLoginInput: UIFont {
        .fdFont(ofSize: senior ? 19 : 16, weight: .regular)
    }

    /// Figma 登录页主按钮（18pt Medium）。
    static var fdLoginButton: UIFont {
        .fdFont(ofSize: senior ? 22 : 18, weight: .medium)
    }

    /// Figma 登录页辅助文案（14pt）。
    static var fdLoginMeta: UIFont {
        .fdFont(ofSize: senior ? 17 : 14, weight: .regular)
    }

    // MARK: - My Module (+2pt)

    /// 设置 / 个人信息等「我的」子页正文（标准 17pt / 老年 21pt）。
    static var fdMyBody: UIFont {
        .fdFont(ofSize: senior ? 21 : 17, weight: .regular)
    }

    static var fdMyBodySemibold: UIFont {
        .fdFont(ofSize: senior ? 21 : 17, weight: .semibold)
    }

    static var fdMyBodyBold: UIFont {
        .fdFont(ofSize: senior ? 21 : 17, weight: .bold)
    }

    static var fdMyCaption: UIFont {
        .fdFont(ofSize: senior ? 18 : 15, weight: .regular)
    }

    static var fdMyCaptionSemibold: UIFont {
        .fdFont(ofSize: senior ? 18 : 15, weight: .semibold)
    }

    static var fdMyMicro: UIFont {
        .fdFont(ofSize: senior ? 16 : 13, weight: .regular)
    }

    static var fdMyH2: UIFont {
        .fdFont(ofSize: senior ? 28 : 24, weight: .bold)
    }

    static var fdMyH3: UIFont {
        .fdFont(ofSize: senior ? 24 : 20, weight: .semibold)
    }

    // MARK: - Type Scale: Body

    /// 正文 / 列表项 — 标准 17pt / 老年 21pt，`.regular`
    /// CSS: --fd-body
    static var fdBody: UIFont {
        .fdFont(ofSize: senior ? 21 : 17, weight: .regular)
    }

    /// 正文 Semibold 变体 — 按钮文字、列表行主标签
    static var fdBodySemibold: UIFont {
        .fdFont(ofSize: senior ? 21 : 17, weight: .semibold)
    }

    /// 正文 Bold 变体 — 强调正文
    static var fdBodyBold: UIFont {
        .fdFont(ofSize: senior ? 21 : 17, weight: .bold)
    }

    // MARK: - Type Scale: Caption

    /// 说明文字 / 辅助标签 — 标准 15pt / 老年 18pt，`.regular`
    /// CSS: --fd-caption
    static var fdCaption: UIFont {
        .fdFont(ofSize: senior ? 18 : 15, weight: .regular)
    }

    /// 说明文字 Semibold 变体 — 卡片内小标题、功能标签
    static var fdCaptionSemibold: UIFont {
        .fdFont(ofSize: senior ? 18 : 15, weight: .semibold)
    }

    // MARK: - Type Scale: Micro

    /// 最小级别 — 标准 13pt / 老年 16pt，`.regular`
    /// CSS: --fd-micro — badge 文字、角标、元信息
    static var fdMicro: UIFont {
        .fdFont(ofSize: senior ? 16 : 13, weight: .regular)
    }

    /// 最小级别 Semibold 变体 — 小标签、设备名
    static var fdMicroSemibold: UIFont {
        .fdFont(ofSize: senior ? 16 : 13, weight: .semibold)
    }

    /// 最小级别 Bold 变体 — badge 内数字
    static var fdMicroBold: UIFont {
        .fdFont(ofSize: senior ? 16 : 13, weight: .bold)
    }

    // MARK: - Type Scale: Numbers（与正文同族 PingFang SC，不用 SF Mono）

    /// 超大数字 — 标准 58pt / 老年 66pt，`.bold`
    /// CSS: --fd-num-xl — 健康评分
    static var fdNumXL: UIFont {
        .fdFont(ofSize: senior ? 66 : 58, weight: .bold)
    }

    /// 大数字 — 标准 38pt / 老年 46pt，`.bold`
    /// CSS: --fd-num-l — 关键指标读数
    static var fdNumL: UIFont {
        .fdFont(ofSize: senior ? 46 : 38, weight: .bold)
    }

    /// 中数字 — 标准 24pt / 老年 28pt，`.bold`
    /// CSS: --fd-num-m — 统计数值、趋势值
    static var fdNumM: UIFont {
        .fdFont(ofSize: senior ? 28 : 24, weight: .bold)
    }
}

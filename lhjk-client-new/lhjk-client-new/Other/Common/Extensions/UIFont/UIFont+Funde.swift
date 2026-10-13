import ObjectiveC
import UIKit

/// funde-client Design Token 字体映射
/// 来源: funde-client prototype/src/styles/tokens.css + docs/design/design-system.md
/// 规则: 禁止直接写 systemFont(ofSize:)，所有字号通过 Token 引用
extension UIFont {

    // MARK: - Font Family Stack

    /// 主字体栈 — PingFang SC (iOS 中文系统默认)
    /// CSS: "PingFang SC", -apple-system, "Helvetica Neue", "Segoe UI", "Microsoft YaHei", sans-serif
    /// iOS 上 systemFont 默认即为 PingFang SC（中文），等价于 CSS 中的 --fd-font
    /// 设计字号。长辈模式字号走对照表；创建时就按本地开关取当前字号，并记下这一对，刷新时不再猜点值。
    static func fdFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        fdFont(designSize: size, seniorSize: seniorSize(forDesign: size), weight: weight)
    }

    /// 设计字号 → 当前字号。未列入对照表的字号，长辈模式下仍用设计字号。
    static func fdFont(designSize: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        fdFont(ofSize: designSize, weight: weight)
    }

    /// Token 专用：设计字号和大字号都由调用方给定，不走对照表，避免 17/21 这类被表里的另一档盖掉。
    static func fdFont(designSize: CGFloat, seniorSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        let applied = isSeniorMode ? seniorSize : designSize
        let base = UIFont.systemFont(ofSize: applied, weight: weight)
        return base.fdStamped(design: designSize, senior: seniorSize, weight: weight, mono: false)
    }

    /// 对照表里的大字号。没有对应档时保持设计字号。
    static func seniorSize(forDesign designSize: CGFloat) -> CGFloat {
        for pair in seniorSizePairs where abs(pair.standard - designSize) < 0.5 {
            return pair.senior
        }
        return designSize
    }

    /// 按本地 `isSeniorMode` 用字体上记下的设计字号 / 大字号重算。没有记录的字体原样返回。
    func fdResolvedForSeniorMode() -> UIFont {
        fdResolvedForSeniorMode(rememberedBy: nil)
    }

    /// 与 `BaseViewController` 的就地刷新共用。标准字号在左，长辈模式字号在右。
    private static let seniorSizePairs: [(standard: CGFloat, senior: CGFloat)] = [
        (10, 13),
        (11, 14),
        (12, 15),
        (13, 16),
        (14, 18),
        (15, 19),
        (16, 20),
        (18, 22),
        (20, 24),
        (22, 26),
        (28, 34),
        (36, 44),
        (56, 64),
    ]

    /// 等宽数字字体 — SF Mono。仅表格/列表竖向对齐时使用，指标读数请用 `fdFont` / `fdNum*`。
    static func fdMonoFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        fdMonoFont(designSize: size, seniorSize: seniorSize(forDesign: size), weight: weight)
    }

    static func fdMonoFont(designSize: CGFloat, seniorSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        let applied = isSeniorMode ? seniorSize : designSize
        let base = UIFont.monospacedDigitSystemFont(ofSize: applied, weight: weight)
        let desc = base.fontDescriptor.withDesign(.monospaced) ?? base.fontDescriptor
        let font = UIFont(descriptor: desc, size: applied)
        return font.fdStamped(design: designSize, senior: seniorSize, weight: weight, mono: true)
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

    // MARK: - Type Scale: Headings

    /// 页面大标题 — 标准 30pt / 老年 36pt，`.bold`
    static var fdH1: UIFont { .fdFont(designSize: 30, seniorSize: 36, weight: .bold) }

    /// 区块标题 / Topbar 标题 — 标准 24pt / 老年 28pt，`.bold`
    static var fdH2: UIFont { .fdFont(designSize: 24, seniorSize: 28, weight: .bold) }

    /// 小节标题 / 卡片标题 — 标准 20pt / 老年 24pt，`.semibold`
    static var fdH3: UIFont { .fdFont(designSize: 20, seniorSize: 24, weight: .semibold) }

    static var fdH3Regular: UIFont { .fdFont(designSize: 20, seniorSize: 24, weight: .regular) }

    // MARK: - Login Figma

    /// Figma 登录页品牌标题；工程未内置 DingTalk JinBuTi 时回退系统粗体。
    static var fdLoginTitle: UIFont {
        let applied: CGFloat = isSeniorMode ? 40 : 34
        let base = UIFont(name: "DingTalk JinBuTi", size: applied)
            ?? .systemFont(ofSize: applied, weight: .bold)
        return base.fdStamped(design: 34, senior: 40, weight: .bold, mono: false)
    }

    /// Figma 登录页输入与标签（16pt / 老年 19pt）。
    static var fdLoginInput: UIFont { .fdFont(designSize: 16, seniorSize: 19, weight: .regular) }

    /// Figma 登录页主按钮（18pt / 老年 22pt Medium）。
    static var fdLoginButton: UIFont { .fdFont(designSize: 18, seniorSize: 22, weight: .medium) }

    /// Figma 登录页辅助文案（14pt / 老年 17pt）。
    static var fdLoginMeta: UIFont { .fdFont(designSize: 14, seniorSize: 17, weight: .regular) }

    // MARK: - My Module (+2pt)

    /// 设置 / 个人信息等「我的」子页正文（标准 17pt / 老年 21pt）。
    static var fdMyBody: UIFont { .fdFont(designSize: 17, seniorSize: 21, weight: .regular) }
    static var fdMyBodySemibold: UIFont { .fdFont(designSize: 17, seniorSize: 21, weight: .semibold) }
    static var fdMyBodyBold: UIFont { .fdFont(designSize: 17, seniorSize: 21, weight: .bold) }
    static var fdMyCaption: UIFont { .fdFont(designSize: 15, seniorSize: 18, weight: .regular) }
    static var fdMyCaptionSemibold: UIFont { .fdFont(designSize: 15, seniorSize: 18, weight: .semibold) }
    static var fdMyMicro: UIFont { .fdFont(designSize: 13, seniorSize: 16, weight: .regular) }
    static var fdMyH2: UIFont { .fdFont(designSize: 24, seniorSize: 28, weight: .bold) }
    static var fdMyH3: UIFont { .fdFont(designSize: 20, seniorSize: 24, weight: .semibold) }

    // MARK: - Type Scale: Body

    /// 正文 / 列表项 — 标准 17pt / 老年 21pt，`.regular`
    static var fdBody: UIFont { .fdFont(designSize: 17, seniorSize: 21, weight: .regular) }
    static var fdBodySemibold: UIFont { .fdFont(designSize: 17, seniorSize: 21, weight: .semibold) }
    static var fdBodyBold: UIFont { .fdFont(designSize: 17, seniorSize: 21, weight: .bold) }

    // MARK: - Type Scale: Caption

    /// 说明文字 / 辅助标签 — 标准 15pt / 老年 18pt，`.regular`
    static var fdCaption: UIFont { .fdFont(designSize: 15, seniorSize: 18, weight: .regular) }
    static var fdCaptionSemibold: UIFont { .fdFont(designSize: 15, seniorSize: 18, weight: .semibold) }

    // MARK: - Type Scale: Micro

    /// 最小级别 — 标准 13pt / 老年 16pt，`.regular`
    static var fdMicro: UIFont { .fdFont(designSize: 13, seniorSize: 16, weight: .regular) }
    static var fdMicroSemibold: UIFont { .fdFont(designSize: 13, seniorSize: 16, weight: .semibold) }
    static var fdMicroBold: UIFont { .fdFont(designSize: 13, seniorSize: 16, weight: .bold) }

    // MARK: - Type Scale: Numbers（与正文同族 PingFang SC，不用 SF Mono）

    /// 超大数字 — 标准 58pt / 老年 66pt，`.bold`
    static var fdNumXL: UIFont { .fdFont(designSize: 58, seniorSize: 66, weight: .bold) }
    /// 大数字 — 标准 38pt / 老年 46pt，`.bold`
    static var fdNumL: UIFont { .fdFont(designSize: 38, seniorSize: 46, weight: .bold) }
    /// 中数字 — 标准 24pt / 老年 28pt，`.bold`
    static var fdNumM: UIFont { .fdFont(designSize: 24, seniorSize: 28, weight: .bold) }
}

// MARK: - 设计字号记录

struct FDFontMetrics {
    let design: CGFloat
    let senior: CGFloat
    let weight: UIFont.Weight
    let mono: Bool

    func makeFont() -> UIFont {
        if mono {
            return UIFont.fdMonoFont(designSize: design, seniorSize: senior, weight: weight)
        }
        return UIFont.fdFont(designSize: design, seniorSize: senior, weight: weight)
    }
}

private final class FDFontMetricsBox: NSObject {
    let metrics: FDFontMetrics
    init(_ metrics: FDFontMetrics) { self.metrics = metrics }
}

private var fdFontMetricsKey: UInt8 = 0
private var fdViewMetricsKey: UInt8 = 0
private var fdRefreshingKey: UInt8 = 0

func fd_beginSeniorRefresh(on object: AnyObject) -> Bool {
    if objc_getAssociatedObject(object, &fdRefreshingKey) != nil { return false }
    objc_setAssociatedObject(object, &fdRefreshingKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return true
}

func fd_endSeniorRefresh(on object: AnyObject) {
    objc_setAssociatedObject(object, &fdRefreshingKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}
private let fdStampLock = NSLock()
private var fdStampSerial: CGFloat = 0

enum FDSeniorFontMemory {
    static func remember(_ metrics: FDFontMetrics?, on object: AnyObject) {
        if let metrics {
            objc_setAssociatedObject(object, &fdViewMetricsKey, FDFontMetricsBox(metrics), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } else {
            objc_setAssociatedObject(object, &fdViewMetricsKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    static func metrics(on object: AnyObject) -> FDFontMetrics? {
        (objc_getAssociatedObject(object, &fdViewMetricsKey) as? FDFontMetricsBox)?.metrics
    }
}

extension UIFont {

    var fdMetrics: FDFontMetrics? {
        (objc_getAssociatedObject(self, &fdFontMetricsKey) as? FDFontMetricsBox)?.metrics
    }

    /// `systemFont` 按字号缓存，同一个实例上的关联对象会串号。
    /// 描述里的自定义字段会被系统丢掉，所以用一个不影响排版的唯一矩阵把实例拆开，再把设计字号记在实例上。
    fileprivate func fdStamped(design: CGFloat, senior: CGFloat, weight: UIFont.Weight, mono: Bool) -> UIFont {
        fdStampLock.lock()
        fdStampSerial += 1
        let serial = fdStampSerial
        fdStampLock.unlock()
        let shift = NSValue(cgAffineTransform: CGAffineTransform(translationX: serial * 0.000_000_1, y: 0))
        let descriptor = fontDescriptor.addingAttributes([.matrix: shift])
        let font = UIFont(descriptor: descriptor, size: pointSize)
        let metrics = FDFontMetrics(design: design, senior: senior, weight: weight, mono: mono)
        objc_setAssociatedObject(font, &fdFontMetricsKey, FDFontMetricsBox(metrics), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return font
    }

    /// 控件上记下的一对优先；没有时再读字体自己的记录。字号已经对上就原样返回。
    func fdResolvedForSeniorMode(rememberedBy object: AnyObject?) -> UIFont {
        let metrics = (object.flatMap { FDSeniorFontMemory.metrics(on: $0) }) ?? fdMetrics
        guard let metrics else { return self }
        let applied = UIFont.isSeniorMode ? metrics.senior : metrics.design
        if abs(pointSize - applied) < 0.5, fdMetrics != nil { return self }
        return metrics.makeFont()
    }
}

enum FDSeniorFontHooks {
    private static var installed = false

    static func install() {
        guard !installed else { return }
        installed = true
        fd_swizzle(UILabel.self, #selector(setter: UILabel.font), #selector(UILabel.fd_setSeniorTrackedFont(_:)))
        fd_swizzle(UILabel.self, #selector(UILabel.didMoveToWindow), #selector(UILabel.fd_seniorDidMoveToWindow))
        fd_swizzle(UITextField.self, #selector(setter: UITextField.font), #selector(UITextField.fd_setSeniorTrackedFont(_:)))
        fd_swizzle(UITextField.self, #selector(UITextField.didMoveToWindow), #selector(UITextField.fd_seniorDidMoveToWindow))
        fd_swizzle(UITextView.self, #selector(setter: UITextView.font), #selector(UITextView.fd_setSeniorTrackedFont(_:)))
        fd_swizzle(UITextView.self, #selector(UITextView.didMoveToWindow), #selector(UITextView.fd_seniorDidMoveToWindow))
        fd_swizzle(UIButton.self, #selector(UIButton.didMoveToWindow), #selector(UIButton.fd_seniorDidMoveToWindow))
    }
}

private func fd_swizzle(_ cls: AnyClass, _ original: Selector, _ swizzled: Selector) {
    guard let swizzledMethod = class_getInstanceMethod(cls, swizzled) else { return }
    if let originalMethod = class_getInstanceMethod(cls, original) {
        let didAdd = class_addMethod(
            cls,
            original,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )
        if didAdd {
            class_replaceMethod(
                cls,
                swizzled,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

extension UILabel {
    @objc func fd_setSeniorTrackedFont(_ font: UIFont) {
        let metrics = font.fdMetrics
        fd_setSeniorTrackedFont(font)
        if let metrics {
            FDSeniorFontMemory.remember(metrics, on: self)
        }
    }

    @objc func fd_seniorDidMoveToWindow() {
        fd_seniorDidMoveToWindow()
        guard window != nil else { return }
        fd_refreshSeniorFont()
    }

    func fd_fontForSeniorRefresh() -> UIFont {
        font.fdResolvedForSeniorMode(rememberedBy: self)
    }
}

extension UITextField {
    @objc func fd_setSeniorTrackedFont(_ font: UIFont?) {
        let metrics = font?.fdMetrics
        fd_setSeniorTrackedFont(font)
        if let metrics {
            FDSeniorFontMemory.remember(metrics, on: self)
        }
    }

    @objc func fd_seniorDidMoveToWindow() {
        fd_seniorDidMoveToWindow()
        guard window != nil else { return }
        fd_refreshSeniorFont()
    }

    func fd_fontForSeniorRefresh() -> UIFont? {
        font?.fdResolvedForSeniorMode(rememberedBy: self)
    }
}

extension UITextView {
    @objc func fd_setSeniorTrackedFont(_ font: UIFont?) {
        let metrics = font?.fdMetrics
        fd_setSeniorTrackedFont(font)
        if let metrics {
            FDSeniorFontMemory.remember(metrics, on: self)
        }
    }

    @objc func fd_seniorDidMoveToWindow() {
        fd_seniorDidMoveToWindow()
        guard window != nil else { return }
        fd_refreshSeniorFont()
    }

    func fd_fontForSeniorRefresh() -> UIFont? {
        font?.fdResolvedForSeniorMode(rememberedBy: self)
    }
}

extension UIButton {
    @objc func fd_seniorDidMoveToWindow() {
        fd_seniorDidMoveToWindow()
        guard window != nil else { return }
        fd_refreshSeniorChrome()
    }

    func fd_refreshSeniorChrome() {
        titleLabel?.fd_refreshSeniorFont()
        for state: UIControl.State in [.normal, .highlighted, .selected, .disabled] {
            guard let title = attributedTitle(for: state) else { continue }
            let updated = title.fdRefreshingSeniorFonts()
            if updated !== title {
                setAttributedTitle(updated, for: state)
            }
        }
    }
}

extension NSAttributedString {

    /// 把富文本里带设计字号记录的字体，按当前长辈模式重算。没有记录的字体不动。
    func fdRefreshingSeniorFonts() -> NSAttributedString {
        guard length > 0 else { return self }
        let mutable = NSMutableAttributedString(attributedString: self)
        var changed = false
        mutable.enumerateAttribute(.font, in: NSRange(location: 0, length: length)) { value, range, _ in
            guard let font = value as? UIFont else { return }
            let next = font.fdResolvedForSeniorMode()
            guard next !== font else { return }
            mutable.addAttribute(.font, value: next, range: range)
            changed = true
        }
        return changed ? mutable : self
    }
}

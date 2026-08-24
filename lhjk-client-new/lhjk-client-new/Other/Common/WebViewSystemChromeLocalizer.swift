import UIKit

/// 将系统控件（WKWebView 日期选择器、UIImagePicker 相机等）英文文案替换为中文。
enum WebViewSystemChromeLocalizer {

    private static let titleMap: [String: String] = [
        "Reset": "重置",
        "Done": "完成",
        "Clear": "清除",
        "Cancel": "取消",
        "PHOTO": "照片",
        "Photo": "照片",
        "VIDEO": "视频",
        "Video": "视频",
        "Retake": "重拍",
        "Use Photo": "使用照片",
        "Choose": "选取",
        "Take Picture": "拍照",
        "Choose Photo": "选取照片",
        "Camera Roll": "相机胶卷",
        "Photos": "照片",
        "Library": "图库",
    ]

    static func localizeVisibleChrome() {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where !window.isHidden {
                localize(in: window)
            }
        }
    }

    /// 在指定视图树内替换英文按钮/标签（用于刚 present 的 UIImagePickerController）。
    static func localizeVisibleChrome(in root: UIView) {
        localize(in: root)
    }

    /// Present 系统图片/相机选择器后调用，多次延迟以覆盖异步加载的控件。
    static func scheduleLocalizationAfterPresentingPicker() {
        localizeVisibleChrome()
        DispatchQueue.main.async {
            localizeVisibleChrome()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            localizeVisibleChrome()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            localizeVisibleChrome()
        }
    }

    private static func localize(in view: UIView) {
        if let button = view as? UIButton {
            for state: UIControl.State in [.normal, .highlighted, .selected, .disabled] {
                if let title = button.title(for: state), let localized = localizedTitle(for: title) {
                    button.setTitle(localized, for: state)
                }
                if let attributed = button.attributedTitle(for: state)?.string,
                   let localized = localizedTitle(for: attributed) {
                    button.setTitle(localized, for: state)
                }
            }
        }

        if let label = view as? UILabel, let text = label.text, let localized = localizedTitle(for: text) {
            label.text = localized
        }

        view.subviews.forEach { localize(in: $0) }
    }

    private static func localizedTitle(for raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let direct = titleMap[trimmed] { return direct }
        return titleMap.first { $0.key.caseInsensitiveCompare(trimmed) == .orderedSame }?.value
    }
}

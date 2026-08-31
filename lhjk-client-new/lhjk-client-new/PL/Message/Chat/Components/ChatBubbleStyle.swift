import UIKit
import Kingfisher

// MARK: - Figma 3876:35332 聊天气泡规范

enum ChatBubbleTail {
  /// 左侧消息（对方）：左上角小圆角
  case left
  /// 右侧消息（自己）：右上角小圆角
  case right
}

enum ChatBubbleStyle {
  /// Figma：头像 38×38（@3x 切图 114px）
  static let avatarSize: CGFloat = 38
  static let avatarRadius: CGFloat = avatarSize / 2
  /// 屏幕左右边距
  static let horizontalInset: CGFloat = 16
  /// 头像与气泡间距
  static let avatarToContentGap: CGFloat = 8
  static let bubbleInset: CGFloat = 12
  static let bubbleInsetStaff: CGFloat = 11
  /// 正文与气泡上下边距（上略小，避免行高撑开后视觉上偏下）
  static let bubbleTextInsetTop: CGFloat = 10
  static let bubbleTextInsetBottom: CGFloat = 12
  static let nameToBubbleGap: CGFloat = 4
  /// 对侧留白（普通气泡最大宽度计算）
  static let oppositeReserve: CGFloat = 56

  static let cornerLarge: CGFloat = 16
  static let cornerSmall: CGFloat = 4

  static let defaultAvatarImage = UIImage(named: "chat_im_avatar")

  /// 气泡起点：16 + 38 + 8 = 62
  static var contentStartOffset: CGFloat {
    horizontalInset + avatarSize + avatarToContentGap
  }

  /// 自定义卡片固定满宽 = 屏宽 − 左右（边距 + 头像 + 间距）
  static func cardBubbleWidth(for screenWidth: CGFloat = UIScreen.main.bounds.width) -> CGFloat {
    screenWidth - contentStartOffset * 2
  }

  /// 普通气泡（文本/语音/图片/文件）最大宽度，随内容收缩
  static func maxContentBubbleWidth(for screenWidth: CGFloat = UIScreen.main.bounds.width) -> CGFloat {
    screenWidth - contentStartOffset - oppositeReserve
  }

  static func textPreferredMaxWidth(for screenWidth: CGFloat = UIScreen.main.bounds.width) -> CGFloat {
    screenWidth - 141
  }

  static let metaFont: UIFont = .fdFont(ofSize: 14, weight: .regular)
  static let metaColor = UIColor(hexString: "#8591AB")

  /// 普通聊天气泡正文
  static let textFont: UIFont = .fdBody
  static let textMediumFont: UIFont = .fdBodySemibold

  static let primaryText = UIColor(hexString: "#1F2942")
  static let secondaryText = UIColor(hexString: "#8591AB")
  static let userFill = UIColor(hexString: "#FF7A50")

  /// 将字节数或纯数字字符串格式化为带单位的文件大小（B / KB / MB）
  static func displayFileSize(_ raw: String?) -> String {
    guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
      return ""
    }

    let lower = trimmed.lowercased()
    if lower.hasSuffix("kb") || lower.hasSuffix("mb") || lower.hasSuffix("gb") {
      return trimmed
    }

    if let bytes = Int(trimmed) {
      return formatFileSize(bytes: bytes)
    }

    if let bytes = Double(trimmed).map { Int($0) } {
      return formatFileSize(bytes: bytes)
    }

    if lower.hasSuffix("b"), let bytes = Int(trimmed.dropLast()) {
      return formatFileSize(bytes: bytes)
    }

    return trimmed
  }

  static func formatFileSize(bytes: Int) -> String {
    let value = Double(bytes)
    if value < 1024 { return "\(bytes)B" }
    if value < 1024 * 1024 { return String(format: "%.1fKB", value / 1024) }
    return String(format: "%.1fMB", value / (1024 * 1024))
  }
  static let staffGradientTop = UIColor(hexString: "#FFFAF7")
  static let staffGradientBottom = UIColor.white
  static let dividerColor = UIColor(hexString: "#EEEEEE")
  static let iconCircleFill = UIColor(hexString: "#FFF2E6")
  static let actionFill = UIColor(hexString: "#FDF6F3")
  static let actionText = UIColor(hexString: "#FF7950")

  static var textParagraphStyle: NSParagraphStyle {
    let style = NSMutableParagraphStyle()
    let lineHeight = ceil(textFont.lineHeight * 1.5)
    style.minimumLineHeight = lineHeight
    style.maximumLineHeight = lineHeight
    return style
  }

  /// 聊天气泡正文（固定行高 + baseline 微调，避免 UILabel 内文字偏下）
  static func attributedBubbleText(_ text: String, color: UIColor) -> NSAttributedString {
    let font = textFont
    let lineHeight = ceil(font.lineHeight * 1.5)
    let baselineOffset = (lineHeight - font.lineHeight) / 2
    return NSAttributedString(
      string: text,
      attributes: [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: textParagraphStyle,
        .baselineOffset: baselineOffset,
      ]
    )
  }

  static var cardParagraphStyle: NSParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.lineHeightMultiple = 1.5
    return style
  }

  // MARK: - 自定义卡片（Figma 3876:35332）

  enum Card {
    static let padding: CGFloat = 12
    static let titleToBodyGap: CGFloat = 10
    static let bodyToDividerGap: CGFloat = 12
    static let dividerToRowsGap: CGFloat = 4
    static let rowSpacing: CGFloat = 8
    static let rowVerticalInset: CGFloat = 6
    static let actionTopGap: CGFloat = 12
    static let actionHeight: CGFloat = 34
    /// SysNotify 表格行：列内水平边距（小于 card padding，列间距更紧凑）
    static let tableColumnHorizontalInset: CGFloat = 6
    static let tableHeaderVerticalInset: CGFloat = 6
    static let tableCellVerticalInset: CGFloat = 8
    /// rows 区（含表格）相对卡片左右边距，略小于 padding 以加宽展示区
    static let rowsContentInset: CGFloat = 8
    static let iconSize: CGFloat = 22
    static let iconGlyphSize: CGFloat = 14

    static let titleFont: UIFont = .fdFont(ofSize: 16, weight: .medium)
    static let bodyFont: UIFont = .fdFont(ofSize: 14, weight: .regular)
    static let rowLabelFont: UIFont = .fdFont(ofSize: 14, weight: .regular)
    static let rowValueFont: UIFont = .fdFont(ofSize: 14, weight: .medium)
    static let tagFont: UIFont = .fdFont(ofSize: 12, weight: .regular)
    static let actionFont: UIFont = .fdFont(ofSize: 14, weight: .medium)
    static let statusFont: UIFont = .fdFont(ofSize: 14, weight: .medium)
  }

  static func staffMetaText(name: String?) -> String? {
    guard let name, !name.isEmpty else { return nil }
    return name
  }

  static func configureAvatar(_ label: UILabel, imageView: UIImageView) {
    label.layer.cornerRadius = avatarRadius
    imageView.layer.cornerRadius = avatarRadius
    imageView.clipsToBounds = true
    imageView.contentMode = .scaleAspectFill
  }

  /// 加载头像；无网络图时使用 `chat_im_avatar`
  static func applyAvatar(
    portraitUrl: String?,
    label: UILabel,
    imageView: UIImageView
  ) {
    label.isHidden = true
    imageView.isHidden = false
    imageView.image = defaultAvatarImage

    guard let urlStr = portraitUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
          !urlStr.isEmpty,
          let url = URL(string: urlStr) else { return }

    imageView.kf.setImage(
      with: url,
      placeholder: defaultAvatarImage,
      options: [.transition(.fade(0.2))]
    )
  }
}

// MARK: - Asymmetric bubble path

extension UIBezierPath {
  static func chatBubble(
    in rect: CGRect,
    tail: ChatBubbleTail,
    large: CGFloat = ChatBubbleStyle.cornerLarge,
    small: CGFloat = ChatBubbleStyle.cornerSmall
  ) -> UIBezierPath {
    let topLeft = tail == .left ? small : large
    let topRight = tail == .left ? large : small
    return roundedRect(
      rect,
      topLeft: topLeft,
      topRight: topRight,
      bottomLeft: large,
      bottomRight: large
    )
  }

  static func roundedRect(
    _ rect: CGRect,
    topLeft: CGFloat,
    topRight: CGFloat,
    bottomLeft: CGFloat,
    bottomRight: CGFloat
  ) -> UIBezierPath {
    let path = UIBezierPath()
    let minX = rect.minX
    let maxX = rect.maxX
    let minY = rect.minY
    let maxY = rect.maxY

    path.move(to: CGPoint(x: minX + topLeft, y: minY))
    path.addLine(to: CGPoint(x: maxX - topRight, y: minY))
    path.addArc(
      withCenter: CGPoint(x: maxX - topRight, y: minY + topRight),
      radius: topRight,
      startAngle: -.pi / 2,
      endAngle: 0,
      clockwise: true
    )
    path.addLine(to: CGPoint(x: maxX, y: maxY - bottomRight))
    path.addArc(
      withCenter: CGPoint(x: maxX - bottomRight, y: maxY - bottomRight),
      radius: bottomRight,
      startAngle: 0,
      endAngle: .pi / 2,
      clockwise: true
    )
    path.addLine(to: CGPoint(x: minX + bottomLeft, y: maxY))
    path.addArc(
      withCenter: CGPoint(x: minX + bottomLeft, y: maxY - bottomLeft),
      radius: bottomLeft,
      startAngle: .pi / 2,
      endAngle: .pi,
      clockwise: true
    )
    path.addLine(to: CGPoint(x: minX, y: minY + topLeft))
    path.addArc(
      withCenter: CGPoint(x: minX + topLeft, y: minY + topLeft),
      radius: topLeft,
      startAngle: .pi,
      endAngle: -.pi / 2,
      clockwise: true
    )
    path.close()
    return path
  }
}

// MARK: - Bubble background (gradient / solid + tail corners)

final class ChatBubbleBackgroundView: UIView {
  enum Fill {
    case staffGradient
    case userSolid
  }

  var tail: ChatBubbleTail = .left { didSet { setNeedsLayout() } }
  var fill: Fill = .staffGradient { didSet { setNeedsLayout() } }

  private let gradientLayer = CAGradientLayer()
  private let borderLayer = CAShapeLayer()
  private let maskLayer = CAShapeLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    layer.addSublayer(gradientLayer)
    layer.addSublayer(borderLayer)
    backgroundColor = .clear
  }

  required init?(coder: NSCoder) { fatalError() }

  override func layoutSubviews() {
    super.layoutSubviews()
    let path = UIBezierPath.chatBubble(in: bounds, tail: tail)
    maskLayer.path = path.cgPath
    layer.mask = maskLayer

    switch fill {
    case .staffGradient:
      backgroundColor = .clear
      gradientLayer.isHidden = false
      gradientLayer.frame = bounds
      gradientLayer.colors = [
        ChatBubbleStyle.staffGradientTop.cgColor,
        ChatBubbleStyle.staffGradientBottom.cgColor,
      ]
      gradientLayer.locations = [0, 0.22]
      gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
      gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
      borderLayer.isHidden = false
      borderLayer.path = path.cgPath
      borderLayer.fillColor = UIColor.clear.cgColor
      borderLayer.strokeColor = UIColor.white.cgColor
      borderLayer.lineWidth = 1
    case .userSolid:
      backgroundColor = ChatBubbleStyle.userFill
      gradientLayer.isHidden = true
      borderLayer.isHidden = true
    }
  }
}

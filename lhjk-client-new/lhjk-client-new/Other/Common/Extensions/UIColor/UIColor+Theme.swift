import UIKit

/// funde-client Design Token 颜色映射
/// 来源: funde-client prototype/src/styles/tokens.css
/// 规则: 禁止直接写 hex 值，所有颜色通过 Token 引用
extension UIColor {

    // MARK: - Brand Palette

    /// 主品牌色 · 暖橙  #FF7A50
    static let fdPrimary = UIColor(hexString: "#FF7A50")
    /// 按下 / hover 态  #E55A2E
    static let fdPrimaryDeep = UIColor(hexString: "#E55A2E")
    /// 浅橙背景（chip、badge bg）  #FFF3EE
    static let fdPrimarySoft = UIColor(hexString: "#FFF3EE")
    /// 主色描边 / 分割线  #FFD9C7
    static let fdPrimaryEdge = UIColor(hexString: "#FFD9C7")

    // MARK: - Semantic

    /// 正常 / 绿色  #2DB983
    static let fdSuccess = UIColor(hexString: "#2DB983")
    /// 绿色浅背景  #E6F7EF
    static let fdSuccessSoft = UIColor(hexString: "#E6F7EF")
    /// 需关注 / 黄色  #F5A524
    static let fdWarning = UIColor(hexString: "#F5A524")
    /// 黄色浅背景  #FFF3DC
    static let fdWarningSoft = UIColor(hexString: "#FFF3DC")
    /// 危险 / 红橙  #E5564B
    static let fdDanger = UIColor(hexString: "#E5564B")
    /// 红色浅背景  #FCE9E6
    static let fdDangerSoft = UIColor(hexString: "#FCE9E6")
    /// 信息 / 蓝色  #5C8DC9
    static let fdInfo = UIColor(hexString: "#5C8DC9")
    /// 蓝色浅背景  #EBF1FA
    static let fdInfoSoft = UIColor(hexString: "#EBF1FA")

    // MARK: - Neutrals

    /// 主文字（标题、正文）  #1F2430
    static let fdText = UIColor(hexString: "#1F2430")
    /// 次主文字（副标题）  #3D4555
    static let fdText2 = UIColor(hexString: "#3D4555")
    /// 辅助说明、标签  #6B7280
    static let fdSubtext = UIColor(hexString: "#6B7280")
    /// 最弱文字、元信息  #9AA0AC
    static let fdMuted = UIColor(hexString: "#9AA0AC")
    /// 常规描边（暖色调）  #ECE4DD
    static let fdBorder = UIColor(hexString: "#ECE4DD")
    /// 强调描边  #D9D0C7
    static let fdBorderStrong = UIColor(hexString: "#D9D0C7")
    /// 卡片面  #FFFFFF
    static let fdSurface = UIColor.white
    /// 嵌套卡片面  #FAF4EF
    static let fdSurface2 = UIColor(hexString: "#FAF4EF")
    /// 全局暖米底色  #FDF6F3
    static let fdBg = UIColor(hexString: "#FDF6F3")
    /// 次级背景（segment 底色等）  #F6ECE4
    static let fdBg2 = UIColor(hexString: "#F6ECE4")

    // MARK: - Third-Party Brand

    /// 微信品牌绿  #07C160
    static let fdWechatGreen = UIColor(hexString: "#07C160")
}

import UIKit
import SnapKit

/// 分类文案 — 对齐 `MallProductDetailView.vue` → `categoryCopy`
struct MallProductCategoryCopy {
    let label: String
    let scenario: String
    let highlights: [String]
    let audience: [String]
    let detail: String

    static func forCategory(_ category: String) -> MallProductCategoryCopy {
        switch category {
        case "健康器械":
            return MallProductCategoryCopy(
                label: "家庭监测设备",
                scenario: "适合居家自测、连续追踪和健管师远程随访使用。",
                highlights: ["设备质检筛选", "使用指导", "数据记录建议", "售后保障"],
                audience: ["居家监测用户", "慢病管理人群", "家庭照护者"],
                detail: "富德优选健康器械优先选择操作简单、读数清晰、适合家庭场景的产品。用户可在健管师指导下建立固定监测习惯，异常数据可作为后续咨询和方案调整参考。"
            )
        case "功能食品":
            return MallProductCategoryCopy(
                label: "日常营养管理",
                scenario: "适合配合饮食方案、体重管理和消化代谢改善使用。",
                highlights: ["营养师建议", "配方筛选", "食用周期提示", "搭配禁忌提醒"],
                audience: ["饮食控制人群", "体重管理用户", "消化代谢关注者"],
                detail: "富德优选功能食品以日常管理为定位，不替代药品和医疗治疗。商品详情强调食用方法、适用场景和注意事项，方便用户结合自身健康档案理性选择。"
            )
        default:
            return MallProductCategoryCopy(
                label: "营养补充优选",
                scenario: "适合结合体检指标、饮食结构和健管目标进行补充。",
                highlights: ["德好健康监制", "适用人群说明", "营养补充建议", "正品保障"],
                audience: ["营养摄入不足人群", "慢病管理用户", "中老年家庭用户"],
                detail: "富德优选营养补充类商品以健康管理场景为核心，重点说明适用人群、建议周期和注意事项，避免用户把保健食品误解为治疗手段。"
            )
        }
    }

    static func usageSteps(productName: String) -> [(title: String, desc: String)] {
        [
            ("查看适用说明", "确认是否符合\(productName)的适用人群。"),
            ("结合档案选择", "如有慢病、用药或过敏史，建议先咨询健管师。"),
            ("按周期使用", "根据商品说明持续记录身体反馈和关键指标。"),
        ]
    }
}

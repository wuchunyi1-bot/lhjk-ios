import UIKit

// MARK: - Risk Item

/// 风险等级信息（高/中/低）
struct RiskItem {
    let label: String       // "高风险" / "中风险" / "低风险"
    let count: Int          // 数量
    let color: UIColor      // 显示颜色
}

// MARK: - Metric Status Type

/// 体征指标状态
enum MetricStatusType {
    case normal   // 正常 → 绿色 badge
    case warning  // 偏高/偏低 → 黄色 badge
}

// MARK: - Metric Row Item

/// 体征监测数据行
struct MetricRowItem {
    let label: String       // "血压" / "血糖" / ...
    let value: String       // "138/88" / "5.8"
    let unit: String        // "mmHg" / "mmol/L"
    let status: String      // "偏高" / "正常"
    let statusType: MetricStatusType
    let time: String        // "今天 07:32" / "昨天 08:10"
}

// MARK: - Lifestyle Item

/// 生活习惯
struct LifestyleItem {
    let label: String       // "饮食习惯" / "运动习惯"
    let icon: String        // SF Symbol 名
    let summary: String     // "低盐低脂，少食多餐"
}

// MARK: - Health History Item

/// 健康史条目
struct HealthHistoryItem {
    let label: String       // "过敏史" / "既往史" / "家族史" / "用药史"
    let summary: String     // "暂无过敏史" / "高血压（2019 年确诊）"
    let status: HistoryItemStatus
}

/// 健康史条目状态
enum HistoryItemStatus {
    case filled    // 有数据 → 正常文字色
    case empty     // 暂无 → muted 色
}

// MARK: - Mock Data Provider

/// 健康档案 Mock 数据（来源: funde-client health.json + me.json）
enum HealthRecordMockData {

    static let userName: String = "张大伟"
    static let userAvatar: String = "张"
    static let archiveProgress: Int = 72
    static let riskScore: Int = 62
    static let riskLevel: String = "中风险"

    static let riskItems: [RiskItem] = [
        RiskItem(label: "高风险", count: 0, color: UIColor(hexString: "#E53935")),
        RiskItem(label: "中风险", count: 1, color: UIColor(hexString: "#F57C00")),
        RiskItem(label: "低风险", count: 2, color: UIColor(hexString: "#43A047")),
    ]

    static let latestMetrics: [MetricRowItem] = [
        MetricRowItem(label: "血压", value: "138/88", unit: "mmHg",  status: "偏高", statusType: .warning, time: "今天 07:32"),
        MetricRowItem(label: "血糖", value: "5.8",    unit: "mmol/L", status: "正常", statusType: .normal,  time: "昨天 08:10"),
        MetricRowItem(label: "体重", value: "68.5",   unit: "kg",     status: "正常", statusType: .normal,  time: "3 天前"),
        MetricRowItem(label: "心率", value: "76",     unit: "bpm",    status: "正常", statusType: .normal,  time: "今天 07:32"),
        MetricRowItem(label: "血氧", value: "98",     unit: "%",      status: "正常", statusType: .normal,  time: "今天 07:32"),
        MetricRowItem(label: "睡眠", value: "7.2",    unit: "小时",   status: "良好", statusType: .normal,  time: "昨晚"),
    ]

    static let lifestyleItems: [LifestyleItem] = [
        LifestyleItem(label: "饮食习惯", icon: "fork.knife", summary: "饮食规律，低盐低脂，少食多餐"),
        LifestyleItem(label: "运动习惯", icon: "figure.run", summary: "走路，每周 3～4 次，30～60 分钟"),
    ]

    static let healthHistoryItems: [HealthHistoryItem] = [
        HealthHistoryItem(label: "过敏史", summary: "暂无过敏史", status: .empty),
        HealthHistoryItem(label: "既往史", summary: "高血压（2019 年确诊）", status: .filled),
        HealthHistoryItem(label: "家族史", summary: "父亲：高血压", status: .filled),
        HealthHistoryItem(label: "用药史", summary: "苯磺酸氨氯地平，每日 1 次", status: .filled),
    ]
}

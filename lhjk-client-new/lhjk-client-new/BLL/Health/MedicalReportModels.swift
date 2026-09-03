import Foundation

/// `GET /v1/medicalReport/getMedicalReportStatistics` 响应 `data`
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495657297e0.md
struct MedicalReportStatisticsVO: Decodable, Equatable {
    /// 上传报告数
    let reportNum: Int?
    /// 异常报告数
    let abnormalReportNum: Int?
    /// 待解读份数
    let pendingInterpretNum: Int?
    /// 最近上传体检日期（月-日）
    let reportTime: String?
    /// 最近上传体检机构
    let medicalInstitutions: String?

    /// 「我的」健康管理 — 体检报告单行右侧文案
    var hubDetailText: String? {
        let uploaded = max(0, reportNum ?? 0)
        if uploaded > 0 {
            return "\(uploaded)份已上传"
        }
        let pending = max(0, pendingInterpretNum ?? 0)
        if pending > 0 {
            return "\(pending)份待解读"
        }
        return nil
    }
}

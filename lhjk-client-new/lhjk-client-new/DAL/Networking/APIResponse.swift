import Foundation

/// 通用 API 响应包装器
///
/// funde-api 所有接口统一返回格式：
/// ```json
/// { "code": "0", "data": {...}, "msg": "ok", "total": 0, "success": true, "failed": false }
/// ```
///
/// - `T`: `data` 字段的具体类型
struct APIResponse<T: Decodable>: Decodable {
    /// 业务状态码，"0"、"200" 表示成功
    let code: String
    /// 响应数据体（可为 null）
    let data: T?
    /// 提示信息
    let msg: String?
    /// 分页总条数（非分页接口为 0）
    let total: Int?
    /// 是否成功（部分接口无此字段）
    let success: Bool?
    /// 是否失败（部分接口无此字段）
    let failed: Bool?

    /// 判断请求是否成功
    var isSuccess: Bool {
        success == true || code == "200" || code == "0"
    }
}

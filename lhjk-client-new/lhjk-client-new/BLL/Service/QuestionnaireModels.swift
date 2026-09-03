import Foundation

/// `GET /v1/questionnaire/getSchoolExamUserListCount` 响应 `data[]`
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/500500978e0.md
struct ExamUserListCountVO: Decodable, Equatable {
    /// 数量
    let count: Int?
    /// 状态值：0 待完成 / 1 待审核 / 2 已通过 / 3 未通过
    let value: Int?
    /// 名称
    let name: String?

    private enum CodingKeys: String, CodingKey {
        case count, value, name
    }

    init(count: Int?, value: Int?, name: String?) {
        self.count = count
        self.value = value
        self.name = name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        count = Self.decodeInt(container, key: .count)
        value = Self.decodeInt(container, key: .value)
    }

    private static func decodeInt(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Int? {
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let text = try? container.decodeIfPresent(String.self, forKey: key),
           let value = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return value
        }
        return nil
    }
}

extension Array where Element == ExamUserListCountVO {
    /// 「我的」健康管理 — 健康测评行右侧文案（待完成 `value == 0`）
    var hubHealthEvaluationDetail: String? {
        let pending = first(where: { $0.value == 0 })?.count ?? 0
        guard pending > 0 else { return nil }
        return "\(pending)项待完成"
    }
}

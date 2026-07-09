import UIKit

struct PtsBadge {
    let id: String
    let name: String
    let icon: String
    let color: UIColor
    let status: String
    let earnedAt: String?
    let progress: Int?
    let target: Int?
}

struct PtsRecord {
    let title: String
    let date: String
    let points: String
    let isAdd: Bool
}

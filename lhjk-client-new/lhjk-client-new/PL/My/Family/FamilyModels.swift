import UIKit

struct FamMember {
    let id: String
    let name: String
    let relation: String
    let avatar: String
    let plan: String
    let planWeek: Int
    let planTotal: Int
    let phase: String
    let checkInDone: Int
    let checkInTotal: Int
    let alerts: [String]
    let keyMetrics: [(label: String, value: String, unit: String, status: String)]
}

let famPhaseColors: [String: UIColor] = [
    "适应期": UIColor(hexString: "#8B8B8B"),
    "见效期": .fdPrimary,
    "巩固期": UIColor(hexString: "#1F9A6B"),
    "习惯养成": UIColor(hexString: "#7B5E9F"),
]

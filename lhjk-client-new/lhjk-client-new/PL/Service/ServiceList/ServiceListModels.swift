import UIKit

struct SvcPkg {
    let id: String
    let productCode: String
    let name: String
    let subtitle: String
    let price: String
    let priceUnit: String
    let tag: String
    let benefits: [String]
    let audience: [String]
    let detail: String
}

struct SvcMatrix {
    let code: String
    let name: String
    let desc: String
    let tier: String
    let accent: UIColor
    let current: Bool
}

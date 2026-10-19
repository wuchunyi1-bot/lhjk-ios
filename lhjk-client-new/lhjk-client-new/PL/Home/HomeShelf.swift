import Foundation

/// 首页内部页签。底栏不再放「服务」，健康服务 / 富德优选 / 健康知识都从这里进。
enum HomeShelf: String, CaseIterable {
    case home
    case service
    case mall
    case articles

    var title: String {
        switch self {
        case .home: return "首页"
        case .service: return "健康服务"
        case .mall: return "富德优选"
        case .articles: return "健康知识"
        }
    }
}

enum HomeShelfStore {
    static let storageKey = "fd_home_shelf"
    static let didRequestNotification = Notification.Name("lhjk.home.shelfDidRequest")

    /// 外部切页签时先记下，首页尚未出现也能接住。
    static var pending: HomeShelf?

    static func saved() -> HomeShelf {
        guard let raw = UserDefaults.standard.string(forKey: storageKey),
              let shelf = HomeShelf(rawValue: raw) else {
            return .home
        }
        return shelf
    }

    static func save(_ shelf: HomeShelf) {
        UserDefaults.standard.set(shelf.rawValue, forKey: storageKey)
    }
}

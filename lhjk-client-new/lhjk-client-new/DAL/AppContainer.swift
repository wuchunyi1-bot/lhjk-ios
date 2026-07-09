import Foundation

/// 应用级依赖容器 — 所有 Service/Manager 的集中访问入口
///
/// ## 使用方式
///
/// ```swift
/// // ViewModel 中：通过 init 注入（默认值走 Container）
/// final class HomeViewModel: ObservableObject {
///     init(userManager: UserManager = AppContainer.shared.userManager) { ... }
/// }
///
/// // 测试时：直接传 mock，绕过 Container
/// let vm = HomeViewModel(userManager: MockUserManager())
/// ```
///
/// ## 注册顺序
///
/// 按初始化依赖分组：基础设施 → 网络层 → SDK 封装 → 业务服务。
/// 当前所有 lazy var 指向 `.shared`（向后兼容），后续可改为构造器注入。
final class AppContainer {

    // MARK: - Singleton

    static let shared = AppContainer()

    private init() {}

    // MARK: - 基础设施（无依赖）

    private(set) lazy var router: Router = .shared
    private(set) lazy var databaseManager: DatabaseManager = .shared
    private(set) lazy var networkMonitor: NetworkMonitor = .shared

    // MARK: - 网络层

    private(set) lazy var apiManager: APIManager = .shared

    // MARK: - SDK 封装

    private(set) lazy var rongCloudManager: RongCloudManager = .shared
    private(set) lazy var rongCloudMessageDelegate: RongCloudMessageDelegate = .shared
    private(set) lazy var bluetoothManager: BluetoothManager = .shared

    // MARK: - 业务服务

    private(set) lazy var userManager: UserManager = .shared
    private(set) lazy var loginService: LoginService = .shared
    private(set) lazy var userService: UserService = .shared
    private(set) lazy var imService: IMService = .shared
    private(set) lazy var addressService: AddressService = .shared
    private(set) lazy var voucherService: VoucherService = .shared
    private(set) lazy var serviceCatalogService: ServiceCatalogService = .shared
    private(set) lazy var columnContentService: ColumnContentService = .shared
    private(set) lazy var dictionaryService: DictionaryService = .shared
    private(set) lazy var hospitalPackageService: HospitalPackageService = .shared
    private(set) lazy var orderService: OrderService = .shared
    private(set) lazy var paymentService: PaymentService = .shared
    // MARK: - 存储

    private(set) lazy var userDefaultsManager: UserDefaultsManager = .shared
}

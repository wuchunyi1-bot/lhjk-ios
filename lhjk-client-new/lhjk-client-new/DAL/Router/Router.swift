import UIKit

// MARK: - Route Target Protocol

/// 每个 BLL 模块的 Target 类需遵循此协议
///
/// Target 类命名规范：`Target_{ModuleName}`
/// Action 方法命名规范：`Action_{actionName}:`
protocol RouteTarget: AnyObject {
    /// 返回此 Target 对应的模块名（用于自动注册）
    static var moduleName: String { get }
}

// MARK: - Route Middleware Protocol

/// 路由中间件 — 在页面跳转前执行拦截逻辑
protocol RouteMiddleware {
    /// 中间件名称（用于日志和调试）
    var name: String { get }

    /// 处理路由请求
    /// - Parameters:
    ///   - context: 路由上下文
    ///   - next: 调用此闭包继续传递给下一个中间件或执行跳转
    func process(_ context: RouteContext, next: @escaping (RouteContext) -> Void)
}

// MARK: - Route Context

/// 路由上下文 — 封装一次跳转的完整信息
struct RouteContext {
    /// 路由路径（如 "/home/detail"）
    let path: String
    /// URL 查询参数
    let queryParameters: [String: String]
    /// 额外传递的参数
    let extraParameters: [String: Any]
    /// 来源 ViewController
    weak var fromViewController: UIViewController?
    /// 跳转方式
    let transition: RouteTransition
    /// 完成回调
    let completion: (([String: Any]?) -> Void)?

    init(
        path: String,
        queryParameters: [String: String] = [:],
        extraParameters: [String: Any] = [:],
        from fromViewController: UIViewController? = nil,
        transition: RouteTransition = .push,
        completion: (([String: Any]?) -> Void)? = nil
    ) {
        self.path = path
        self.queryParameters = queryParameters
        self.extraParameters = extraParameters
        self.fromViewController = fromViewController
        self.transition = transition
        self.completion = completion
    }
}

// MARK: - Route Transition

enum RouteTransition {
    case push
    case present
    case rootWindow
}

// MARK: - Route Entry

/// 单条路由注册信息
private struct RouteEntry {
    let path: String
    let moduleName: String
    let actionName: String
    let requiresAuth: Bool
}

// MARK: - Router (DAL)

/// CTMediator 风格的路由管理器
///
/// 负责 URL-based 导航、Target-Action 注册、中间件链执行。
/// 位于 DAL 层，不依赖任何业务模块。
///
/// ## 使用方式
///
/// ### 1. 注册路由（在 BLL 模块的 `load()` 中调用）
/// ```
/// Router.shared.register(
///     path: "/health/detail",
///     moduleName: "Health",
///     actionName: "showDetail",
///     requiresAuth: true
/// )
/// ```
///
/// ### 2. 页面跳转
/// ```
/// // 内部跳转
/// Router.shared.push("/health/detail", params: ["recordId": "123"])
///
/// // URL 跳转
/// Router.shared.openURL("lhjk://health/detail?recordId=123")
/// ```
final class Router {

    // MARK: - Singleton

    static let shared = Router()

    // MARK: - Properties

    /// 路由注册表
    private var routes: [String: RouteEntry] = [:]

    /// 中间件链
    private var middlewares: [RouteMiddleware] = []

    /// 全局完成回调（用于 Deep Link 等待登录等场景）
    private var pendingContext: RouteContext?

    // MARK: - Initialization

    private init() {
        // 默认中间件：日志
        #if DEBUG
        registerMiddleware(LogMiddleware())
        #endif
    }

    // MARK: - Route Registration

    /// 注册路由
    /// - Parameters:
    ///   - path: URL 路径（如 "/health/detail"）
    ///   - moduleName: 目标模块名（对应 Target_{moduleName} 类）
    ///   - actionName: Action 方法名（不含 "Action_" 前缀和 ":" 后缀）
    ///   - requiresAuth: 是否需要登录
    func register(
        path: String,
        moduleName: String,
        actionName: String,
        requiresAuth: Bool = false
    ) {
        let entry = RouteEntry(
            path: path,
            moduleName: moduleName,
            actionName: actionName,
            requiresAuth: requiresAuth
        )

        if routes[path] != nil {
            #if DEBUG
            print("[Router] ⚠️ Duplicate route registered for '\(path)', overwriting.")
            #endif
        }

        routes[path] = entry
    }

    // MARK: - Middleware Registration

    /// 注册中间件
    func registerMiddleware(_ middleware: RouteMiddleware) {
        middlewares.append(middleware)
    }

    // MARK: - Navigation Methods

    /// Push 跳转
    func push(
        _ path: String,
        params: [String: Any] = [:],
        from viewController: UIViewController? = nil,
        completion: (([String: Any]?) -> Void)? = nil
    ) {
        let context = RouteContext(
            path: path,
            extraParameters: params,
            from: viewController,
            transition: .push,
            completion: completion
        )
        execute(context: context)
    }

    /// Present 跳转
    func present(
        _ path: String,
        params: [String: Any] = [:],
        from viewController: UIViewController? = nil,
        completion: (([String: Any]?) -> Void)? = nil
    ) {
        let context = RouteContext(
            path: path,
            extraParameters: params,
            from: viewController,
            transition: .present,
            completion: completion
        )
        execute(context: context)
    }

    /// 设置为根视图控制器
    func setRoot(
        _ path: String,
        params: [String: Any] = [:],
        completion: (([String: Any]?) -> Void)? = nil
    ) {
        let context = RouteContext(
            path: path,
            extraParameters: params,
            transition: .rootWindow,
            completion: completion
        )
        execute(context: context)
    }

    /// 通过 URL 打开（Deep Link / URL Scheme / 推送通知）
    func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            #if DEBUG
            print("[Router] ⚠️ Invalid URL: \(urlString)")
            #endif
            return
        }

        let path = url.path
        var queryParams: [String: String] = [:]

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            for item in components.queryItems ?? [] {
                queryParams[item.name] = item.value
            }
        }

        let context = RouteContext(
            path: path,
            queryParameters: queryParams,
            transition: .push
        )
        execute(context: context)
    }

    // MARK: - Route Execution

    /// 执行路由：中间件链 → 目标 Action
    private func execute(context: RouteContext) {
        // 查找路由注册信息
        guard let entry = routes[context.path] else {
            #if DEBUG
            print("[Router] ⚠️ No route registered for '\(context.path)' — falling back to home")
            #endif
            fallbackToHome(context: context)
            return
        }

        // 构建中间件链
        let chain = buildMiddlewareChain(for: context, entry: entry, index: 0)

        // 在中间件链末尾执行实际跳转
        chain(context)
    }

    /// 递归构建中间件链
    private func buildMiddlewareChain(
        for context: RouteContext,
        entry: RouteEntry,
        index: Int
    ) -> (RouteContext) -> Void {
        if index < middlewares.count {
            let middleware = middlewares[index]
            let next = buildMiddlewareChain(for: context, entry: entry, index: index + 1)
            return { ctx in
                middleware.process(ctx) { processedCtx in
                    next(processedCtx)
                }
            }
        } else {
            // 中间件链结束 → 执行 Target-Action
            return { ctx in
                self.performAction(entry: entry, context: ctx)
            }
        }
    }

    /// 执行 Target-Action
    private func performAction(entry: RouteEntry, context: RouteContext) {
        let targetClassName = "lhjk_client.Target_\(entry.moduleName)"
        let actionSelector = NSSelectorFromString("Action_\(entry.actionName):")

        guard let targetClass = NSClassFromString(targetClassName) as? NSObject.Type else {
            #if DEBUG
            print("[Router] ⚠️ Target class '\(targetClassName)' not found")
            #endif
            return
        }

        let target = targetClass.init()

        guard target.responds(to: actionSelector) else {
            #if DEBUG
            print("[Router] ⚠️ Target '\(targetClassName)' doesn't respond to 'Action_\(entry.actionName):'")
            #endif
            return
        }

        // 合并参数
        var mergedParams: [String: Any] = context.queryParameters.reduce(into: [:]) {
            $0[$1.key] = $1.value
        }
        for (key, value) in context.extraParameters {
            mergedParams[key] = value
        }

        // 包装参数传递给 Action
        let wrappedParams: [String: Any] = [
            "params": mergedParams,
            "from": context.fromViewController as Any,
            "transition": context.transition,
        ]

        // 通过 performSelector 调用 Action 方法（消除警告）
        let selector = actionSelector
        if target.responds(to: selector) {
            typealias ActionFunction = @convention(c) (NSObject, Selector, NSDictionary) -> UIViewController?
            let imp = target.method(for: selector)
            let function = unsafeBitCast(imp, to: ActionFunction.self)
            let viewController = function(target, selector, wrappedParams as NSDictionary)

            if let vc = viewController {
                navigate(to: vc, transition: context.transition, from: context.fromViewController)
            }

            context.completion?([:])
        }
    }

    /// 实际执行 UI 跳转
    private func navigate(
        to viewController: UIViewController,
        transition: RouteTransition,
        from sourceViewController: UIViewController?
    ) {
        DispatchQueue.main.async {
            switch transition {
            case .push:
                let source = sourceViewController ?? UIApplication.shared.topViewController()
                source?.navigationController?.pushViewController(viewController, animated: true)

            case .present:
                let source = sourceViewController ?? UIApplication.shared.topViewController()
                source?.present(viewController, animated: true)

            case .rootWindow:
                guard let window = UIApplication.shared.currentWindow else { return }
                window.rootViewController = viewController
                window.makeKeyAndVisible()
            }
        }
    }

    /// 降级到首页
    private func fallbackToHome(context: RouteContext) {
        if let homeEntry = routes["/home"] {
            performAction(entry: homeEntry, context: context)
        }
    }
}

// MARK: - Built-in Middleware: Log

/// 默认日志中间件（DEBUG 模式下输出路由日志）
private final class LogMiddleware: RouteMiddleware {
    let name = "Log"

    func process(_ context: RouteContext, next: @escaping (RouteContext) -> Void) {
        #if DEBUG
        print("[Router] → \(context.path) | params: \(context.extraParameters) | transition: \(context.transition)")
        #endif
        next(context)
    }
}

// MARK: - UIApplication Extensions

private extension UIApplication {
    /// 获取当前最顶层的 ViewController
    func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? currentWindow?.rootViewController
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }

    /// 获取当前活跃的 UIWindow
    var currentWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

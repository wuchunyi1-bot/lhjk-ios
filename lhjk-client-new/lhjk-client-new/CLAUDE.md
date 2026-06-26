# lhjk-client-new 项目约定

## 线程安全：UI 必须在主线程

**规则**：所有 UIKit / SwiftUI 操作必须在主线程执行。

### NotificationCenter 通知 → UI 刷新

```
❌ 错误:
NotificationCenter.default.post(name: .xxx, object: nil)

✅ 正确:
await MainActor.run {
    NotificationCenter.default.post(name: .xxx, object: nil)
}
// 或
DispatchQueue.main.async {
    NotificationCenter.default.post(name: .xxx, object: nil)
}
```

**原因**：`NotificationCenter` 在 post 的线程**同步**投递回调。如果 post 在后台线程（如 `UserManager.refreshUserInfo()` 的 `Task` 上下文），所有 observer 的回调也在后台线程执行，此时调 UIKit → 崩溃。

### async/await 中的 UI 操作

```swift
Task {
    let result = try await someAsyncAPI()
    // ← 这里可能在任意线程
    await MainActor.run {
        // ✅ UI 操作放这里
        self.label.text = result.name
        self.tableView.reloadData()
    }
}
```

### Timer

```
❌ Timer.scheduledTimer(...)  // 默认 RunLoop mode，滚动时暂停

✅ RunLoop.main.add(timer, forMode: .common)  // 滚动不暂停，确保主线程
```

### 新增/修改代码检查清单

- [ ] `NotificationCenter.post` 是否包了 `MainActor.run` / `DispatchQueue.main.async`？
- [ ] `Task { }` 内的 UI 操作是否在 `await MainActor.run { }` 内？
- [ ] `Timer` 是否用了 `RunLoop.main.add(_:forMode:.common)`？
- [ ] observer 回调是否需要 `queue: .main`？

## 布局：避免 _UITemporaryLayoutWidth 约束冲突

**规则**：水平方向的 `equalToSuperview().inset()` 约束优先级不应为 `.required(1000)`，应降为 `750`。

```swift
// ❌ 可能在 _UITemporaryLayoutWidth == 0 时冲突
make.leading.trailing.equalToSuperview().inset(16)

// ✅ 静默容忍临时零宽测量
make.leading.trailing.equalToSuperview().inset(16).priority(750)
```

适用场景：
- 自定义 UIView 子类（直接 add 到 VC 的 view）
- `tableHeaderView` 的子视图
- 任何在 `systemLayoutSizeFitting` 中被测量的视图

## 用户数据：全局单例缓存

- `UserManager.shared.currentUser` — 读用户信息，不要在各页面重复调 API
- `UserManager.shared.fetchUserInfo()` — App 启动 / 登录成功后调用一次
- `UserManager.shared.refreshUserInfo()` — 用户修改个人信息后调用，会发 `.userDidUpdate` 通知

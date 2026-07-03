# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Install dependencies
cd lhjk-client-new && pod install

# Open the workspace (NOT the .xcodeproj)
open lhjk-client-new.xcworkspace

# Build: select scheme "lhjk-client-new" → target iOS 15.0+ device/simulator
```

After adding, removing, or moving any `.swift` file, regenerate the Xcode project:

```bash
ruby generate_project.rb
```

This script scans all `.swift` files under `lhjk-client-new/` and rebuilds `project.pbxproj`. Without this step, new files won't appear in Xcode's file navigator or compile.

## Architecture: Three-Layer (PL → BLL → DAL)

```
PL (Presentation Layer)   →  ViewControllers, Cells, UI Components
BLL (Business Logic Layer) →  Services (IMService, UserService, LoginService), Routes
DAL (Data Access Layer)    →  Networking, Bluetooth, IM SDK, Storage, Router
```

**Dependency direction is strict and one-way.** A lower layer must never import or reference a higher layer.

- **PL** (`PL/`): ViewControllers and Cells. Binds `viewModel` from BLL, calls BLL services. No business logic.
- **BLL** (`BLL/`): Service singletons, route registration, models. Owns business logic and state. References DAL for data access.
- **DAL** (`DAL/`): API manager, RongCloud SDK wrapper, Bluetooth, file storage, payment channels, Router. No business logic, no reference to BLL types (e.g., `UserManager`).

If DAL needs user info or other business data, BLL passes it as a method parameter (e.g., `senderUserInfo: RCUserInfo?`).

## Module Structure (5 Tabs)

Each business module has `BLL/{Module}/` (Routes + Service) and `PL/{Module}/` (ViewControllers + Cells):

| Tab | BLL | PL |
|-----|-----|----|
| 首页 (Home) | `BLL/Home/` | `PL/Home/` |
| 健康 (Health) | `BLL/Health/` | `PL/Health/` |
| 服务 (Service) | `BLL/Service/` | `PL/Service/` |
| 消息 (Message) | `BLL/Message/` | `PL/Message/` |
| 我的 (My) | `BLL/My/` | `PL/My/` |

Shared infrastructure lives in `Other/Common/` (base classes, extensions, protocols) and `DAL/` (networking, storage, IM, router).

## Router

CTMediator-style URL-based navigation in `DAL/Router/Router.swift`. All page transitions go through `Router.shared`:

```swift
Router.shared.push("/health/detail", params: ["recordId": "123"])
Router.shared.present("/onboarding")
Router.shared.setRoot("/")                    // RootTabBarController
Router.shared.openURL("lhjk://health/detail?recordId=123")
```

- Routes are registered in `*Routes.swift` enums (e.g., `HomeRoutes.register()`).
- `RouteSetup.registerAll()` is called once in `AppDelegate`.
- The Router supports middleware chains and auth gating.
- Default transition is `.push`; sub-pages auto-hide the tab bar.

## Networking

`APIManager` (singleton, `DAL/Networking/`) wraps Alamofire with:
- **Authenticated session**: Uses Alamofire's `AuthenticationInterceptor` + `OAuthAuthenticator` for automatic token refresh. Use `APIManager.shared.session` / `.get()`, `.post()`, etc.
- **Public session**: For login, captcha, etc. — `APIManager.shared.publicSession`.
- **Combine publishers**: All HTTP methods return `AnyPublisher<T, APIError>`; async wrappers in `APIManager+Async.swift`.
- **Snake case decoding**: `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`.
- Environment: `development` (gateway-dev), `staging`, `production`.

## IM (RongCloud)

- `RongCloudManager` (DAL) wraps `RongIMLibCore` 5.x. Initialized in `AppDelegate` with `appKey`.
- `IMService` (BLL) manages conversations, messages, notifications, and unread counts. Publishes `totalUnreadCountDidChangePublisher` for the tab bar badge.
- All messages use `ConversationType_GROUP` (group chat). Custom message types: `AD:FileMsg`, `AD:VideoMsg`, `AD:SysNotify` in `DAL/IM/CustomMessages/`.
- Token flow: `POST /mobile/v1/account/addRongImAccount` → connect. Cold start restores token from UserDefaults.

### senderUserInfo

When sending: BLL's `IMService.makeSenderUserInfo()` builds `RCUserInfo` from `UserManager.shared.currentUser` and passes it to DAL.

When receiving (`fromRongCloud`): Always extract `rcMessage.content?.senderUserInfo`:
- `.name` → `senderName`
- `.name.prefix(1)` → `avatar` (text avatar, not image URL)
- `.portraitUri` → `portraitUrl` (reserved for future image avatar support)

### Message Cell Dispatch

Custom message types dispatch by `objectName` in `ChatMessage.fromRongCloud()`. Each type has a corresponding cell registered in `ChatViewController`. `MessageType` enum in `DAL/IM/Message.swift` covers all types including `.timeMarker`, `.recall`, `.voice`, `.file`, `.video`, `.sysNotify`.

### Read Receipts

`IMService.loadMessages` sends read receipts for received-direction messages automatically. `ConversationListViewController` subscribes to `messageReceivedPublisher` and `remoteConversationListDidSyncPublisher` for real-time list updates.

## Design Tokens

**Colors**: Never use hex literals directly. Use `UIColor.fd*` tokens from `UIColor+Theme.swift`:
- `fdPrimary` (#FF7A50), `fdPrimaryDeep`, `fdPrimarySoft`, `fdPrimaryEdge`
- `fdSuccess` / `fdWarning` / `fdDanger` / `fdInfo` with `*Soft` variants
- `fdText`, `fdText2`, `fdSubtext`, `fdMuted` (text hierarchy)
- `fdBorder`, `fdBorderStrong`, `fdSurface`, `fdSurface2`, `fdBg`, `fdBg2`

**Fonts**: Never use `systemFont(ofSize:)` directly. Use `UIFont.fd*` tokens from `UIFont+Funde.swift`:
- `fdH1`, `fdH2`, `fdH3` (headings)
- `fdBody`, `fdBodySemibold`, `fdBodyBold` (body text)
- `fdCaption`, `fdCaptionSemibold` (labels)
- `fdMicro`, `fdMicroSemibold`, `fdMicroBold` (badges/meta)
- `fdNumXL`, `fdNumL`, `fdNumM` (monospaced numbers)

All font tokens auto-scale when senior mode (`UIFont.isSeniorMode`) is enabled.

## Thread Safety

All UIKit operations must be on the main thread:

```swift
// In async tasks, wrap UI updates:
await MainActor.run {
    self.label.text = result.name
    self.tableView.reloadData()
}

// NotificationCenter posts that trigger UI must be on main thread:
await MainActor.run {
    NotificationCenter.default.post(name: .xxx, object: nil)
}
```

## Layout: SnapKit Constraint Priority

Horizontal `equalToSuperview().inset()` constraints should use priority `.priority(750)` instead of the default `.required(1000)` to avoid `_UITemporaryLayoutWidth` conflicts during `systemLayoutSizeFitting`:

```swift
make.leading.trailing.equalToSuperview().inset(16).priority(750)
```

## User Data Caching

- `UserManager.shared.currentUser` — single source of truth for user info. Read from memory; do not re-fetch from API in each page.
- `UserManager.shared.fetchUserInfo()` — call once on app launch / login success.
- `UserManager.shared.refreshUserInfo()` — call after user edits profile; posts `.userDidUpdate` notification.
- `UserManager.shared.clear()` — call on logout.

## OpenSpec

Spec-driven development: feature specs live in `openspec/specs/` (one subdirectory per domain), change proposals in `openspec/changes/`. Use the `/openspec:*` slash commands to propose, explore, apply, and archive changes.

## Key Dependencies (Podfile)

| Pod | Usage |
|-----|-------|
| `Alamofire ~> 5.9` | HTTP networking |
| `SnapKit ~> 5.7` | Auto Layout DSL |
| `Kingfisher ~> 7.0` | Image loading/caching |
| `RongCloudIM/IMLib ~> 5.40.0` | IM SDK |
| `FMDB ~> 2.7` | SQLite |
| `DGCharts` | Line charts (health metrics) |

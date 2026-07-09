# lhjk-client iOS — Agent 开发指南

本项目的代码规则与实现逻辑以 **OpenSpec** 为准，规格文档位于 `openspec/` 目录。

## 规格文档结构

```
openspec/
├── specs/          # 已归档的主规格（权威参考）
│   ├── project-architecture/
│   ├── networking/
│   ├── router/
│   ├── design-tokens/
│   ├── data-storage/
│   ├── im/
│   ├── bluetooth/
│   ├── payment/
│   ├── image-loading/
│   ├── oss-upload/
│   ├── ecg/
│   ├── order-list/
│   ├── shipping-address/
│   └── vouchers/
└── changes/        # 进行中的变更提案（proposal / design / tasks / delta specs）
```

## 开发工作流

1. **查 spec**：开发某功能前，先读 `openspec/specs/{module}/spec.md`
2. **遵循架构**：PL → BLL → DAL 单向依赖，详见 `openspec/specs/project-architecture/spec.md`
3. **对齐设计**：UI 使用 Design Token，参考 `openspec/specs/design-tokens/spec.md`
4. **变更提案**：新功能可用 `.claude/skills/openspec-propose` 生成提案，实现用 `openspec-apply-change`

## 核心约定摘要

| 类别 | 规则 |
|------|------|
| UI | UIKit + SnapKit，纯代码 |
| 布局 | SnapKit only |
| 颜色/字体 | `fd*` Token，禁止 hex 硬编码 |
| 网络 | Alamofire + AuthenticationInterceptor |
| 路由 | CTMediator，`Router.push("/path")` |
| ViewModel | PL 层，`ObservableObject` + `@Published` |
| 依赖 | `AppContainer.shared` 收敛单例 |
| 配置 | AI 不修改 Podfile / pbxproj / Info.plist |
| **模块归属** | 服务 Tab = 商城模块（`Service/`）；与健康等模块平级；**不确定归属时必须先问用户** |
| **新增文件** | AI 不修改 `.xcodeproj`；新增/移动 `.swift` 后**必须提示开发者手动加入 Xcode 工程** |
| **网络参数** | **禁止**将 mock/本地假数据传入 API；模块已接真实接口后须删除该模块 mock 数据 |

## Cursor 规则

持久化规则位于 `.cursor/rules/lhjk-openspec.mdc`，每次对话自动加载。

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

## Cursor 规则

持久化规则位于 `.cursor/rules/lhjk-openspec.mdc`，每次对话自动加载。

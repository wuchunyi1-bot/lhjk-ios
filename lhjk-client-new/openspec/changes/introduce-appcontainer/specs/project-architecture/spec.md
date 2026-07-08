# Project Architecture — AppContainer Dependency Management

## Purpose

在 `project-architecture` spec 中新增 `AppContainer` 依赖管理规范，收敛所有单例引用到一个集中式容器。

## Requirements

### Requirement: AppContainer

系统 SHALL 提供 `DAL/AppContainer.swift` 作为应用级依赖容器的**唯一入口**。

#### Scenario: 容器结构
- **WHEN** `AppContainer` 被定义
- **THEN** 它是一个 `final class`，自身有一个 `static let shared` 实例
- **AND** 所有 Service/Manager 通过 `private(set) lazy var` 暴露
- **AND** 按初始化依赖顺序分为：基础设施 → 网络层 → SDK 封装 → 业务服务

#### Scenario: Service 访问
- **WHEN** ViewModel 或其他上层代码需要获取 Service 实例
- **THEN** 通过 `AppContainer.shared.xxxService` 访问，而非 `XxxService.shared`
- **AND** ViewModel 的 `init` 参数默认值使用 `AppContainer.shared.xxxService`

#### Scenario: 测试替换
- **WHEN** 需要在测试中 mock 某个 Service
- **THEN** 直接通过 `init` 参数注入 mock 实例，绕过 Container
- **AND** Container 内部的 `private(set)` 允许在 DEBUG 模式下替换实例

#### Scenario: 新增 Service
- **WHEN** 项目中新增一个 BLL Service 或 DAL Manager
- **THEN** 必须在 `AppContainer` 中注册该实例
- **AND** 上层代码优先通过 Container 访问，而非直接调 `.shared`

### Requirement: 渐进式迁移

本次变更 SHALL NOT 强制所有代码立即迁移到 AppContainer。

#### Scenario: 必须迁移的
- **WHEN** ViewModel 的 `init` 参数有默认值
- **THEN** 默认值从 `.shared` 改为 `AppContainer.shared.xxx`

#### Scenario: 暂不迁移的
- **WHEN** ViewController 内部直接调 `XxxService.shared`
- **THEN** 保持不变（留待后续变更）
- **WHEN** BLL Service 之间互相引用 `.shared`
- **THEN** 保持不变（留待后续变更）

#### Scenario: 最终目标
- **WHEN** 迁移全部完成
- **THEN** 项目中除 `AppContainer.swift` 本身外，不再出现 `.shared` 调用
- **AND** 各 Service 自身的 `static let shared` 可保留（作为 Container 的默认实现）

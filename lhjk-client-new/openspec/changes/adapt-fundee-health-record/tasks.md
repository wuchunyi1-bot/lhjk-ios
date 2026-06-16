# Tasks: adapt-fundee-health-record

## 1. Data Models
- [ ] 创建 `HealthRecordModels.swift` — 定义 `RiskItem`、`MetricRowItem`、`LifestyleItem`、`HealthHistoryItem` 等数据结构

## 2. Custom Views (shared sub-components)
- [ ] 创建 `BodyFigureView.swift` — 自定义 UIView，用 CAShapeLayer 绘制简化人形轮廓
- [ ] 创建 `RiskBarView.swift` — 竖排风险等级显示（3 行 label + 彩色数字）

## 3. TableView Cells
- [ ] 创建 `HealthRecordUserInfoCell.swift` — 用户信息卡片（头像 + 姓名 + tag + 进度条 + 六维评测按钮）
- [ ] 创建 `HealthRecordBodyCardCell.swift` — 身体风险卡片（风险列 + 人形图 + 结论 + 顾问批注）
- [ ] 创建 `HealthRecordMetricRowCell.swift` — 体征监测数据行（内嵌 UIStackView 6 行）
- [ ] 创建 `HealthRecordLifestyleCell.swift` — 生活习惯 2×1 grid
- [ ] 创建 `HealthRecordHistoryCell.swift` — 健康史 2×2 grid

## 4. ViewController
- [ ] 创建 `HealthRecordViewController.swift` — 主页面，UITableView 5 sections，注册所有 Cell

## 5. Route Registration
- [ ] 更新 `BLL/Health/HealthRoutes.swift` — 将 `/health/record` 从 `PlaceholderViewController` 替换为 `HealthRecordViewController`
- [ ] 注册子路由 `/health/record/profile`、`/health/record/history`、`/health/record/lifestyle`、`/health/record/condition`（Placeholder）

## 6. Verification
- [ ] 构建验证：Xcode build 通过
- [ ] 功能验证：从健康 Hub "去补全" 可跳转到健康档案页
- [ ] 视觉验证：5 个 section 完整渲染，布局与 funde 原型对应

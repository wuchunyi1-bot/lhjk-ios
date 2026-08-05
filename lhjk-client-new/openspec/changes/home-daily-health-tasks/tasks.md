## 1. 数据与路由

- [x] 1.1 新增 `DailyHealthTask` 模型与首页/详情共用 mock（对齐监测提醒字段）
- [x] 1.2 `HomeRoutes` 注册 `/home/tasks` → `DailyTasksViewController`

## 2. 二级详情页

- [x] 2.1 实现 `DailyTasksViewModel` + `DailyTasksViewController`（Hero / 任务卡 / 温馨提示）
- [x] 2.2 「去完成」跳转 `actionRoute`；空态处理

## 3. 首页任务区

- [x] 3.1 重做 `HomeTaskCardCell`（进度条 + 任务行 + 查看全部 footer，无积分）
- [x] 3.2 `HomeViewModel` / `HomeViewController` 接入新模型；标题「查看全部 ›」进详情；去完成可点

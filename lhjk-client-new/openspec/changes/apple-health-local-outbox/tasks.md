## 1. 队列表

- [x] 1.1 在 `DatabaseManager` 增加 v2 迁移：`apple_health_sample`、`apple_health_anchor`，以及按账号和状态的索引
- [x] 1.2 版本号只在落后时写入，避免每次启动重复插入

## 2. 队列写入

- [x] 2.1 新增 `AppleHealthOutboxStore`：按页事务覆盖样本、处理删除、提交 anchor
- [x] 2.2 `pending` 的删除直接删行；`uploaded` 或不存在的 `uuid` 写成 `pending_delete`；同一页先新增后删除

## 3. 同步接入

- [x] 3.1 `AppleHealthSyncService` 改为写入队列，anchor 从 SQLite 读取，不再读 UserDefaults 中的 anchor
- [x] 3.2 无账号不读取、不写入；同一类型串行；日志只记条数
- [x] 3.3 设置页成功提示改为已保存到本机

## 4. 批量上传

- [x] 4.1 落库后调用 `POST /v1/monitor/batchSavePlatformHealthData`，上传体温、基础体温、体重、血压、体能训练、血氧、饮水。基础体温与体温同为 `businessId` 6、字段 `temperature`
- [x] 4.2 `beginTime` 与 `recordTime` 使用同一毫秒；饮水升转毫升；运动转成中文名、分钟和已有消耗
- [x] 4.3 新增或重复的行删除本地样本，并记下 `uuid`，回补时不再写入；请求失败不删

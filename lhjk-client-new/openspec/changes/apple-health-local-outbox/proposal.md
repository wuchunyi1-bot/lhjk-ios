## Why

苹果健康样本需要先按账号落在本机，再把体温、体重、血压、运动、血氧、饮水交给后端。进程在「读到样本」和「确认落盘」之间被杀掉时会漏数；换机后再传时，用样本 `uuid` 让服务端认出重复。

## What Changes

- 把已读到的苹果健康样本和删除，按账号写入现有 SQLite 的待上传队列。
- anchor 与同一批样本放在同一个事务里更新；写入失败则整批回滚，下次仍从旧 anchor 读取。
- 样本以健康库 `uuid` 为身份。同一账号重复写入覆盖，不新插一行。
- 落库后调用 `POST /v1/monitor/batchSavePlatformHealthData`。服务端确认新增或重复的行从本地删除，并记住 `uuid`。心率不上传。
- 退出登录、换账号不清队列。另一台手机不拷贝这份库，各自维护自己的队列和 anchor。
- 不使用现有 `health_record` 表，也不把样本放进 UserDefaults。

## Capabilities

### New Capabilities

- `apple-health-sync`: 从苹果健康增量读取血糖、血压、心率、体重、体脂率、身高体重指数、血氧、饮水、体温、体能训练，并按账号落入本机待上传队列。

### Modified Capabilities

## Impact

- `DAL/HealthKit/AppleHealthStore.swift`：读取接口保持不变。
- `DAL/Storage/DatabaseManager.swift`：增加队列与 anchor 表的迁移。
- 新增队列仓储，供 `BLL/Health/AppleHealthSyncService.swift` 写入。
- 设置页连接与前台补拉的入口不变。新增调用 `POST /v1/monitor/batchSavePlatformHealthData`。不改 Apifox。

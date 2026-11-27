## Context

设置页已经能授权苹果健康，并用 `HKAnchoredObjectQuery` 按类型增量读取。anchor 存在 UserDefaults，样本只打印，不落盘，也不上传。`DatabaseManager` 已封装 `lhjk.db`，其中的 `health_record` 只有单个数值，装不下血压、训练，也没有样本 `uuid` 和上传状态。

健康库仍是采集源。本机队列保管已经读到、尚未被 `batchSavePlatformHealthData` 确认的样本。确认新增或重复后删掉样本行，只留下 `uuid`，避免近 30 天回补再次上传。

## Goals / Non-Goals

**Goals:**

- 已读样本和删除按账号写入 SQLite，进程被杀掉后仍在。
- 同一批样本与该类型的新 anchor 同事务提交；失败则下次从旧 anchor 再读。
- 以 `账号 + 样本 uuid` 覆盖写入，重放不产生第二行。
- 沿用设置页开启和前台补拉。不注册健康监听，不打开后台投递。
- 落库后把体温、基础体温、体重、血压、体能训练、血氧、饮水批量上传，并在服务端确认后删除本地样本。

**Non-Goals:**

- 不读取、不授权血糖、心率、步数、体脂率、身高体重指数。
- 不把队列当成图表数据源，不改健康首页。
- 不把队列同步到另一台手机。
- 不读取距离、活动能量。
- 不写入苹果健康。

## Decisions

### 队列放在现有 SQLite

样本用 `lhjk.db` 的新表，不新建库，不用 UserDefaults，不用 JSON 文件。样本要和 anchor 同事务提交。UserDefaults 做不到这点。

`health_record` 保持原样，本流程不读写它。

`apple_health_sample`：主键 `(user_id, uuid)`。字段为类型、起止时间、时区、JSON 载荷、单位、来源名称、来源 bundle、`sync_state`、更新时间。

`apple_health_anchor`：主键 `(user_id, kind)`，值为 `HKQueryAnchor` 归档后的 blob。

`sync_state` 取 `pending`、`uploaded`、`pending_delete`。新样本标为 `pending`，健康库里的删除按下面的规则处理。服务端确认过的 `uuid` 写入 `apple_health_sent`，样本行删除，不再标成 `uploaded`。

载荷按类型：

- 定量：`{"value": number}`
- 血压：`{"systolic": number, "diastolic": number}`，缺侧不写该键
- 体能训练：`{"activity": number, "duration": number, "energyKcal": number}`，没有消耗时省略 `energyKcal`

每次同步体能训练时，先把近 30 天的每一条训练覆盖写入，再走该类型的 anchor。这样进度已经往前拨过、但队列里还没有的训练仍会补进本地库。没有苹果活动消耗时，用 MET 表和训练开始前最近的一次体重估算，结果写入 `energyKcal`，并带 `energyEstimated: true`。已有消耗、已停用类型（舞蹈启发训练、混合代谢有氧）和「其他」不估算。

### 先落库，再视为这批已读完

分页读取。每一页在一个事务里：

1. 把本页新增按 `uuid` 覆盖为 `pending`。
2. 再处理本页删除。已是 `pending` 的行直接删掉（还没上传，服务端也不会有）。已是 `uploaded` 或不存在的 `uuid` 写成 `pending_delete`。
3. 写入本页返回的新 anchor。

同一页里同一个 `uuid` 又出现又删除时，以删除为准。事务失败则不更新内存中的游标，该类型本轮停止。

没有 SQLite anchor 时，第一页用近 30 天的时间谓词。这一轮如果没有任何样本和删除，不写 anchor，下次仍用这 30 天谓词。读权限被系统静默拒绝时查询结果是空的，这样不会把进度拨过已有数据。anchor 一旦写入，之后的查询不再带时间谓词，这样窗口之后才进入健康库的旧时间样本仍能被增量读到。30 天以前、且在首次 anchor 之前就已存在的样本不再补。

UserDefaults 里已有的 anchor 不再读取。没有 SQLite anchor 就按上面的 30 天窗口重读，靠 `uuid` 覆盖。

没有登录账号 id 时不查询、不写入、不拨 anchor。退出登录不删队列。另一个账号只读写自己的 `user_id`。

同一账号、同一类型的同步串行执行，避免两次重叠查询把 anchor 写成更旧的值。

开关「已开启」仍放在 UserDefaults。那是偏好，不是样本。

### 日志

每次拉取前先打出当前账号队列里的已有行：类型、开始时间、载荷、单位、状态、来源、`uuid`。没有记录时打 0 条。每个类型写入结束后另打一行新增数、删除数和是否成功。上传结束后只打新增、重复、跳过、失败的条数。

### 批量上传

同步全部写入本地之后，再按体温、基础体温、体重、血压、体能训练、血氧、饮水的顺序从本地读取并上传。`POST /v1/monitor/batchSavePlatformHealthData`，每批最多 80 条。体温和基础体温的 `businessId` 都是 6，其后为 4、2、8、17、19。基础体温读 `basalBodyTemperature`，上传字段仍是 `temperature`。`collectionType` 为 5，`dataSource` 为 `"5"`，`externalUuid` 用本地 `uuid`。`beginTime` 和 `endTime` 都是毫秒字符串，`monitorData.data.recordTime` 与 `beginTime` 是同一个毫秒数。体温、基础体温、体重、血压、血氧、饮水的 `endTime` 与 `beginTime` 相同；体能训练的 `endTime` 用样本结束时间。

饮水本地是升，上传前乘 1000。体能训练把类型编号换成中文名，秒数换成分钟，已有的 `energyKcal` 放进 `calorie`。体重只传 `weight` 和 `bodyFatScaleMonitor = 0`，不附带体脂、身高体重指数。血压不带心率。

响应里 `INSERTED` 和 `DUPLICATE` 删除样本行，并把 `uuid` 写入 `apple_health_sent`。之后回补或增量再遇到这个 `uuid` 直接跳过。`SKIPPED`、`FAILED` 和整批失败都不删。`updated_at` 已经变过的行不删，留给下一次上传。

## Risks / Trade-offs

- [首次 anchor 会跳过 30 天前的旧样本] → 产品窗口就是近 30 天。窗口之后新进入健康库的样本仍走增量。
- [落库后、上传前样本只在这台手机] → 上传请求带 `externalUuid`。另一台手机会再传同一个 `uuid`，服务端按重复跳过。
- [体能训练每次同步都重写近 30 天] → 已确认的 `uuid` 记在 `apple_health_sent`，回补时跳过，避免删掉后又整批重传。
- [删除了一条已经上传的样本，会留下 `pending_delete`] → 批量保存接口只新增，不删服务端记录。这条墓碑留在本地，不放进上传列表。
- [数据库版本行目前每次启动都再插一条] → 本次改成只在版本落后时写入，并增加 v2 建表。

## Migration Plan

打开 `lhjk.db` 时，若版本小于 2，创建队列表、anchor 表及 `(user_id, sync_state)` 索引。若版本小于 3，创建 `apple_health_sent`。已有 `health_record` 不动。不迁移 UserDefaults 中的旧 anchor。

回滚：停止调用队列写入即可。表可留在库里，不读就不会影响现有页面。

## Open Questions

无。批量保存的请求体、逐条删除和已上传 `uuid` 已在本变更里。`pending_delete` 仍只留在本地，这个接口不删除服务端已有记录。

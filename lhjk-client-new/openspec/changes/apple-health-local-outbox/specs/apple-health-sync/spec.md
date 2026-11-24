## ADDED Requirements

### Requirement: 苹果健康样本进入本机队列

系统 SHALL 在用户开启苹果健康后，把血糖、血压、心率、体重、体脂率、身高体重指数、血氧、饮水、体温、基础体温、体能训练、步数写入 `lhjk.db` 的 `apple_health_sample`。步数按本地日合计写入，其余类型按样本写入。体温读 `bodyTemperature`，基础体温读 `basalBodyTemperature`，两者各自保存 anchor。系统 SHALL NOT 使用 `health_record`，SHALL NOT 把样本写入 UserDefaults。落库成功后，系统按「批量上传平台健康数据」上传体温、基础体温、体重、血压、体能训练、血氧、饮水。

每行以 `(user_id, uuid)` 为主键。`uuid` 为健康库样本标识。定量载荷为 `{"value": number}`；血压为 `{"systolic": number, "diastolic": number}`，缺侧省略该键；体能训练为 `{"activity": number, "duration": number}`，有消耗时再加 `energyKcal`。行内同时保存起止时间、时区（有则存）、单位、来源名称和来源 bundle。新样本的 `sync_state` 为 `pending`。

#### Scenario: 首次同步写入近 30 天

- **WHEN** 当前账号在该类型上没有 SQLite anchor，且健康库中有近 30 天的样本
- **THEN** 系统只读取开始时间落在近 30 天内的样本并写入队列
- **AND** 每一页样本与该页返回的新 anchor 在同一事务中提交
- **AND** 事务成功后，该类型的后续读取不再带这 30 天谓词

#### Scenario: 首次没有读到任何变化

- **WHEN** 当前账号在该类型上没有 SQLite anchor，且本轮查询没有样本也没有删除
- **THEN** 系统不写入 anchor
- **AND** 下次同步仍按近 30 天读取

#### Scenario: 已有 anchor 后只写增量

- **WHEN** 该账号该类型已有 SQLite anchor，之后健康库新增或删掉样本
- **THEN** 系统把 anchor 之后的新增写入队列，并把删除交给删除规则处理
- **AND** 新增样本的测量时间早于首次同步窗口时，只要它是在 anchor 之后才进入健康库，仍然写入

#### Scenario: 同一 uuid 再次写入

- **WHEN** 队列里已有该账号的某个 `uuid`，同步又读到这个 `uuid`
- **THEN** 系统覆盖该行的载荷、时间和来源，并把 `sync_state` 置为 `pending`
- **AND** 该账号下这个 `uuid` 仍然只有一行

#### Scenario: 写入失败则 anchor 不动

- **WHEN** 某一页的事务提交失败
- **THEN** 这一页的样本和 anchor 都不保留
- **AND** 该类型本轮停止
- **AND** 下次从失败前已经提交的 anchor 继续；若从未提交过，则仍按近 30 天读取

#### Scenario: 步数按天覆盖

- **WHEN** 用户同步，且健康库近 30 天内某天有步数
- **THEN** 系统用当天合计步数写入一行，`kind` 为 `stepCount`，`uuid` 为 `day:yyyy-MM-dd`，载荷为 `{"value": 整数}`，单位为「步」
- **AND** 系统不把每一条步数样本相加
- **AND** 同一天再次同步覆盖这一行

#### Scenario: 体能训练逐条补齐

- **WHEN** 用户同步，且近 30 天健康库中有体能训练
- **THEN** 系统把其中每一条写入队列，`uuid` 为该样本的健康库标识
- **AND** 该类型已经有 anchor 时仍然补写这 30 天里的每一条，再按 anchor 处理其后的新增和删除

#### Scenario: 没有消耗时按 MET 估算

- **WHEN** 一条体能训练没有苹果活动消耗，类型在 MET 表中，且健康库里有这次训练开始前的体重
- **THEN** 系统写入 `energyKcal`，并标记 `energyEstimated` 为 true
- **AND** 成人类型按 `3.5 × (MET − 1) × 体重(kg) ÷ 200 × 时长(分钟)` 计算
- **AND** 轮椅配速步行、轮椅配速跑、手摇车按 `MET × 0.992 × 体重(kg) × 时长(小时)` 计算
- **AND** 苹果已有消耗时不估算，原样保存
- **AND** 舞蹈启发训练、混合代谢有氧、其他，或没有可用体重时，不写入估算消耗

#### Scenario: 旧的 UserDefaults anchor 不再生效

- **WHEN** UserDefaults 里存有以往的苹果健康 anchor，但 SQLite 中没有该账号该类型的 anchor
- **THEN** 系统不读取 UserDefaults 中的 anchor，并按近 30 天重新读取

### Requirement: 删除与账号隔离

系统 SHALL 把 `HKAnchoredObjectQuery` 返回的删除应用到当前账号的队列。同一页中某个 `uuid` 同时出现在新增和删除里时，SHALL 以删除为准。

系统 SHALL 只读写当前登录账号的行。退出登录 SHALL NOT 删除队列和 anchor。没有账号 id 时，系统 SHALL NOT 读取健康库，也 SHALL NOT 写入队列或 anchor。

同一账号、同一类型的同步 SHALL 串行执行。

#### Scenario: 尚未上传的样本被删掉

- **WHEN** 删除列表包含一个 `sync_state` 为 `pending` 的 `uuid`
- **THEN** 系统删掉该行，不留下待删除记录

#### Scenario: 已上传或本地没有的样本被删掉

- **WHEN** 删除列表包含一个 `sync_state` 为 `uploaded` 的 `uuid`，或队列中没有这个 `uuid`
- **THEN** 系统将该行写成 `pending_delete`，并保留这个 `uuid`

#### Scenario: 换账号不串数据

- **WHEN** 同一台手机先以账号 A 同步，再以账号 B 同步
- **THEN** 账号 B 的读取和写入只使用 B 的队列与 anchor
- **AND** 账号 A 的行仍留在库里

#### Scenario: 未登录

- **WHEN** 当前没有账号 id，用户打开同步或 App 进入前台
- **THEN** 系统不写入队列，也不更新 anchor

### Requirement: 同步入口保持不变

系统 SHALL 继续由设置页开启同步，并在已开启时于 App 进入前台补拉。系统 SHALL NOT 注册健康类型监听，也 SHALL NOT 打开后台投递。设置页展示的开启状态 SHALL 仍存在 UserDefaults。

每次拉取开始前，系统 SHALL 先打印当前账号队列里已有的每一行，包含类型、开始时间、载荷、单位、状态、来源和 `uuid`。队列为空时 SHALL 打印 0 条。每个类型写入结束后，系统 SHALL 记录新增条数、删除条数和是否写入成功。全部类型落库后、发起批量上传前，系统 SHALL 再打印一次当前队列表。上传成功后已接收的行会从队列表删除。

#### Scenario: 拉取前打印本地队列

- **WHEN** 已登录用户从设置页或前台回到 App 触发一次拉取
- **THEN** 系统先打印该账号本地队列中的已有记录，再读取苹果健康
- **AND** 队列为空时打印 0 条

#### Scenario: 设置页开启

- **WHEN** 已登录用户在设置页开启苹果健康并完成授权
- **THEN** 系统把近 30 天样本写入该账号的队列，并把开启状态记为已开启
- **AND** 体温、基础体温、体重、血压、体能训练、血氧、饮水上传完成时提示已同步
- **AND** 本地已写入、上传未完成时提示已保存到本机，部分未上传

#### Scenario: 前台补拉

- **WHEN** 该账号已开启苹果健康，App 进入前台
- **THEN** 系统按已有 anchor 把新增和删除写入队列
- **AND** 写入完成后上传当前账号尚未交出的体温、基础体温、体重、血压、体能训练、血氧、饮水

### Requirement: 批量上传平台健康数据

本地队列全部写入完成后，系统 SHALL 再从本地读取并调用 `POST /v1/monitor/batchSavePlatformHealthData`。只上传 `sync_state` 为 `pending` 的行，顺序为体温、基础体温、体重、血压、体能训练、血氧、饮水。体温和基础体温的 `businessId` 都是 6，其后为 4、2、8、17、19。前一类传完再传下一类。心率、血糖、步数不上传。每批最多 80 条。`collectionType` 为 5，`externalUuid` 为该行 `uuid`。`beginTime` 与 `endTime` 都是毫秒字符串，`monitorData.data.recordTime` 与 `beginTime` 为同一毫秒数，`dataSource` 为 `"5"`。体温、基础体温、体重、血压、血氧、饮水的 `endTime` 与 `beginTime` 相同；体能训练的 `endTime` 用样本结束时间。

测量字段都四舍五入到 2 位小数。体温和基础体温写 `temperature`；体重 `weight`，并带 `bodyFatScaleMonitor = 0`；血压 `highBloodPressure`、`lowBloodPressure`，不带心率；血氧 `oxygen`，`businessId` 为 17；饮水把升换成毫升后写入 `waterAmount`，不按 2000 毫升截断；体能训练写入中文 `name`、分钟 `quantity`、`type = 1`，有 `energyKcal` 时写入 `calorie`。时间、`businessId`、`type` 保持整数。

与某条体重开始时间相距不超过 2 秒的体脂率、身高体重指数，SHALL 写入该体重记录的 `bodyFat`、`bmi`。没有配对的体脂和指数留在本地。

整批请求失败时，系统 SHALL NOT 删除本地行。响应里 `itemStatus` 为 `INSERTED` 或 `DUPLICATE` 的行 SHALL 删除，并记下 `uuid`，之后同一 `uuid` 不再写回队列。`SKIPPED` 和 `FAILED` SHALL 留在本地。`pending_delete` 不在本接口上传。

#### Scenario: 上传并删除

- **WHEN** 当前账号队列里有待上传的体温、基础体温、体重、血压、体能训练、血氧或饮水
- **THEN** 系统按上面的字段调用批量保存接口
- **AND** 基础体温与体温一样写入 `temperature`，`businessId` 为 6
- **AND** 返回新增或 uuid 重复的行从本地删除
- **AND** 心率、血糖、步数仍留在本地

#### Scenario: 请求失败不删

- **WHEN** 批量保存请求失败，或成功响应里没有逐条结果
- **THEN** 这一页的本地行都不删除
- **AND** 后面的页不再继续

#### Scenario: 单条跳过或失败

- **WHEN** 某一条的 `itemStatus` 为 `SKIPPED` 或 `FAILED`
- **THEN** 该行留在本地
- **AND** 同一响应里新增或重复的其他行仍然删除

#### Scenario: 已上传的训练不再回补

- **WHEN** 一条体能训练已经新增或被判定重复，之后再次同步近 30 天训练
- **THEN** 系统不再把这个 `uuid` 写成待上传

#### Scenario: 饮水换算

- **WHEN** 一条饮水的本地值是升
- **THEN** 上传的 `waterAmount` 为该值乘以 1000 的毫升数

#### Scenario: 运动名称和时长

- **WHEN** 一条体能训练的载荷里有运动类型和秒数
- **THEN** 上传使用对应中文 `name`，`quantity` 为秒数除以 60 后的分钟数
- **AND** 有消耗时 `calorie` 使用该消耗，没有则不传 `calorie`

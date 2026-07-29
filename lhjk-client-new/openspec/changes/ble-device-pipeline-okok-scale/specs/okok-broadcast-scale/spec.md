## ADDED Requirements

### Requirement: OKOK V3 广播解析

系统 SHALL 按 OKOK《单向广播体脂秤 V3》解析厂商自定义广播，产出体重测量事件；本期不做体脂算法。

#### Scenario: 厂商过滤规则（权威）

厂商对接约定：过滤厂商自定义广播内容：

- **WHEN** 自定义数据段**第一个字节为 `0xC0`**
- **AND** 数据长度足够，**第 10–15 字节（1-based，对应 0-based 下标 9…14）为设备 MAC**
- **THEN** 将该广播识别为待对接体脂秤并进入解析
- **WHEN** 首字节非 `0xC0`，或长度不足以覆盖 MAC 字段
- **THEN** 忽略该广播，不连接、不报错

#### Scenario: 帧字段解析

- **WHEN** 通过厂商过滤
- **THEN** `OKOKV3PacketParser` 按 V3 数据域解析：版本、流水号、重量（大端）、电阻（大端）、产品 ID、消息体属性、MAC（6 字节）
- **AND** 若广播外层带 Len=`0x10` + Type=`0xFF`，SHALL 先剥离再按数据域解析；若 `manufacturerData` 前带 2 字节 Company ID，SHALL 在载荷内定位以 `0xC0` 开头的数据域

#### Scenario: 重量与单位

- **WHEN** 解析成功
- **THEN** 按属性位小数位还原重量，并按单位（kg / 斤 / LB）换算为 kg（ST:LB 可延后）
- **AND** 电阻保留原始 UInt16

#### Scenario: 非锁定与锁定

- **WHEN** 属性位锁定位为 0
- **THEN** 发出实时体重更新，不落库
- **WHEN** 锁定位为 1
- **THEN** 发出锁定测量事件（weightKg、resistanceRaw、mac、productId、serial）

#### Scenario: 产品 ID 过滤（可选加固）

- **WHEN** `allowedProductIds` 非空
- **THEN** 额外按产品 ID 过滤
- **WHEN** 为空
- **THEN** 仅依赖厂商 C0 + MAC 规则识别（开发期默认）

### Requirement: 锁定落库

系统 SHALL 在收到锁定测量后将体重记录交由 BLL 落库编排；不含体脂衍生指标计算。

#### Scenario: 去重落库

- **WHEN** 连续锁定包流水号与重量未变
- **THEN** 只落库一次
- **WHEN** 新的有效锁定测量
- **THEN** BLL 至少保留 weightKg、measuredAt、mac；体脂字段本期不传

#### Scenario: 会话生命周期

- **WHEN** 用户进入秤测量会话
- **THEN** 启动 `allowDuplicates` 广播扫描 + OKOK Handler
- **WHEN** 离开或结束
- **THEN** 停止 Handler 与扫描；未锁定实时值不落库

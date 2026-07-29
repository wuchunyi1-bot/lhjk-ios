## ADDED Requirements

### Requirement: 广播测量页入口与布局

系统 SHALL 提供 Health 原生「体脂秤测量」页，居中主按钮控制广播扫描；路由为 `/health/scale/measure`。

#### Scenario: 打开页面

- **WHEN** 用户进入 `/health/scale/measure`
- **THEN** 展示居中主按钮（文案含「开始测量」语义）
- **AND** 进入时不自动启动蓝牙扫描

#### Scenario: 设备页入口

- **WHEN** 用户在「我的设备」点击「添加新设备」（或等价入口）
- **THEN** 导航至 `/health/scale/measure`

### Requirement: 用户主动启停广播会话

系统 SHALL 仅在用户点击主按钮后启动 OKOK 广播扫描会话；再次点击或离开页面时停止。

#### Scenario: 开始测量

- **WHEN** 用户点击「开始测量」且系统蓝牙可用
- **THEN** 调用 `ScaleBleSessionService.startSession()`（allowDuplicates 广播扫描，不 connect）
- **AND** 按钮切换为「停止」语义，状态提示测量中

#### Scenario: 停止测量

- **WHEN** 用户点击「停止」或离开本页（`viewWillDisappear` / deinit 等价时机）
- **THEN** 调用 `stopSession()`，停止 Handler 与扫描

#### Scenario: 蓝牙不可用

- **WHEN** 用户点击开始但蓝牙关闭或未授权
- **THEN** 不进入有效扫描，并向用户提示原因（如请打开蓝牙）

### Requirement: 实时与锁定数据展示

系统 SHALL 订阅会话的 realtime / locked 事件并更新界面；锁定后落库行为沿用既有 BLL，本页不做体脂算法。

#### Scenario: 实时体重

- **WHEN** 会话活跃且收到非锁定广播
- **THEN** 界面更新显示当前体重（kg），不视为最终结果

#### Scenario: 锁定完成

- **WHEN** 收到锁定测量
- **THEN** 展示最终体重
- **AND** 自动停止会话
- **AND** 主按钮恢复为可再次测量

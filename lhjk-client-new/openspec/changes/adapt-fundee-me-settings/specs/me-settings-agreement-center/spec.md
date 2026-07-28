## ADDED Requirements

### Requirement: 协议与说明列表

`/me/settings/agreement-center` SHALL 展示六类协议与规则入口，对齐 `AgreementCenterView.vue`。

#### Scenario: 六条静态入口

- **WHEN** 用户进入协议与说明
- **THEN** 单卡片列表按序展示：用户协议、隐私政策、健康管理服务知情同意书、个人信息收集清单、第三方信息共享清单、权益卡使用规则
- **AND** 每行含标题、短描述与右箭头

#### Scenario: 跳转详情

- **WHEN** 用户点击某一行
- **THEN** 进入对应 `/auth/agreement/{docType}` 只读详情页
- **AND** docType 映射为 user / privacy / consent / personal-info / third-party-sharing / benefit-card

### Requirement: 协议详情只读

协议详情页 SHALL 展示标题、更新日期与分节正文；无编辑或同意操作。

#### Scenario: 未知类型兜底

- **WHEN** docType 无法识别
- **THEN** 展示用户协议内容作为兜底

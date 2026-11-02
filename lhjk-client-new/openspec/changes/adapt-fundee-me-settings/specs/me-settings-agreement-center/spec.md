## ADDED Requirements

### Requirement: 协议与说明列表

`/me/settings/agreement-center` SHALL 展示七类协议与规则入口，对齐 `AgreementCenterView.vue` / PRD `02_用户_我的设置`。

#### Scenario: 七条静态入口

- **WHEN** 用户进入协议与说明
- **THEN** 单卡片列表按序展示：用户协议、隐私政策、健康管理服务知情同意书、个人信息收集清单、第三方信息共享清单、会员服务协议、权益卡使用规则
- **AND** 每行含标题、短描述与右箭头
- **AND** 会员服务协议短描述为「查看会员等级、虚拟币、积分与会员兑换规则」

#### Scenario: 跳转详情

- **WHEN** 用户点击某一行
- **THEN** 进入对应 `/auth/agreement/{docType}` 只读详情页
- **AND** docType 映射为 user / privacy / consent / personal-info / third-party-sharing / member-service / benefit-card

### Requirement: 协议详情只读

协议详情 SHALL 打开当前 H5 环境的静态页 `{base}/agreements/user-app/{file}.html`，不拼接登录 token。无编辑或同意操作。

| docType | 文件 | 标题 |
|---|---|---|
| user | `user.html` | 用户协议 |
| privacy | `privacy.html` | 隐私政策 |
| consent | `consent.html` | 健康管理服务知情同意书 |
| personal-info | `personal-info-collection.html` | 个人信息收集清单 |
| third-party-sharing | `third-party-sharing.html` | 第三方信息共享清单 |
| member-service | `member-service.html` | 会员服务协议 |
| benefit-card | `benefit-card.html` | 权益卡使用规则 |

开发环境 base 为 `https://h5-dev.lianhaojiankang.com`。

#### Scenario: 未知类型兜底

- **WHEN** docType 无法识别
- **THEN** 打开 `user.html` 作为兜底

## ADDED Requirements

### Requirement: 用药 / 营养补剂 / 血氧 H5 URL

系统 SHALL 通过 `H5Config` 构建用药、营养补剂、血氧鉴权 URL，拼接 `token`（若有）与 `platform=ios`。App MUST NOT 使用 mock token。

#### Scenario: 用药 URL

- **WHEN** 请求用药 H5
- **THEN** URL 形态为 `{base}#/medication?token=…&platform=ios`（无 token 时仍带 platform）

#### Scenario: 营养补剂 URL

- **WHEN** 请求营养补剂 H5
- **THEN** URL 形态为 `{base}#/supplement?token=…&platform=ios`

#### Scenario: 血氧 URL

- **WHEN** 请求血氧 H5（`/spo2` 或 `/health/metrics/spo2`）
- **THEN** URL 形态为 `{base}#/spo2?token=…&platform=ios`

### Requirement: 原生路由接入 WebView

系统 SHALL 将以下原生路由指向 `WebViewController` 加载对应 H5；路由归属健康模块。

| 原生路由 | 导航栏标题 | H5 |
|----------|------------|-----|
| `/medication` | 用药 | `#/medication` |
| `/supplement` | 营养补剂 | `#/supplement` |
| `/spo2` | 血氧 | `#/spo2` |

#### Scenario: 打开用药

- **WHEN** 导航至 `/medication`
- **THEN** 打开标题为「用药」的 WebView，加载用药鉴权 H5

#### Scenario: 打开营养补剂

- **WHEN** 导航至 `/supplement`
- **THEN** 打开标题为「营养补剂」的 WebView，加载营养补剂鉴权 H5

#### Scenario: 打开血氧短链

- **WHEN** 导航至 `/spo2`
- **THEN** 打开标题为「血氧」的 WebView，加载与 `/health/metrics/spo2` 相同的血氧 H5

#### Scenario: 体征卡血氧不变

- **WHEN** 用户点击体征监测血氧卡
- **THEN** 仍走 `/health/metrics/spo2`，MUST NOT 改为其它原生页

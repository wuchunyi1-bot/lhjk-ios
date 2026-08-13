## ADDED Requirements

### Requirement: 监测方案与健康评估 H5 URL

系统 SHALL 通过 `H5Config` 构建监测方案与健康评估鉴权 URL，拼接 `token`（若有）与 `platform=ios`。

#### Scenario: 监测方案 URL

- **WHEN** 需要打开监测方案 H5
- **THEN** URL 形态为 `{base}/#/monitoring-plan?token=…&platform=ios`（无 token 时仍带 platform）

#### Scenario: 健康评估 URL

- **WHEN** 需要打开健康评估 H5
- **THEN** URL 形态为 `{base}/#/health-assessment?token=…&platform=ios`（无 token 时仍带 platform）

### Requirement: 「我的」入口打开对应 H5

「我的 → 健康管理」中监测方案、健康评估入口 SHALL 通过 `WebViewController` 加载上述 H5；MUST NOT 再进入原生原型/占位页作为默认承载。

#### Scenario: 监测方案入口

- **WHEN** 导航至 `/me/monitoring-plan`（或别名 `/monitoring-plan`）
- **THEN** 打开 `WebViewController`，标题为「监测方案」，URL 为监测方案鉴权 H5

#### Scenario: 健康评估入口

- **WHEN** 导航至 `/me/health-assessment`（或别名 `/health-assessment`）
- **THEN** 打开 `WebViewController`，标题为「健康评估」，URL 为健康评估鉴权 H5

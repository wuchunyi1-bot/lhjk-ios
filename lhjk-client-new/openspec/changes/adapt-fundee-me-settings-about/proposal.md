## Why

「关于富德联好健康」页仍为旧原型：标题「关于我们」、品牌区重复版本、含协议三入口与卡片式备案，与 PRD-213 / `AboutSettingsView.vue` / `me-settings-about.page.yaml` 不一致；协议入口已迁至「协议与说明」。

## What Changes

- **重写关于页**：品牌 Hero（富字 Logo + 富德联好健康 + slogan）+ 信息卡三行（当前版本 / 去应用市场评分 / 联系我们）+ 页脚版权与备案
- **标题**改为「关于富德联好健康」；**移除**用户服务协议、隐私政策、知情同意书入口（本页不展示协议）
- **交互**：点当前版本 toast「当前已经是最新版本」；点评分 toast「暂无法打开应用市场」；联系我们只读不可点
- **版本展示**：读 `CFBundleShortVersionString`，格式 `v{version}`（对齐线框，不以 mock 写死）

## Capabilities

### New Capabilities

- `me-settings-about`: 关于富德联好健康页布局与交互（PRD-213）

### Modified Capabilities

- （无）

## Impact

- `PL/My/Settings/AboutSettingsViewController.swift`
- 路由已有 `/me/settings/about`，无需改 `MyRoutes`
- 参考：`02_用户_我的设置_v1.0` §5.11、`AboutSettingsView.vue`、`me-settings-about.page.yaml`

# Change: Funde pageUrl 统一解析（FundeH5 / FundeApp）

## Why

`getByCode` 与 `getCmsConfig` 返回的 `pageUrl` 采用统一前缀约定，但首页点击仍为 TODO，健康页则把 `FundeH5:` 硬映射成 `/health/metrics/{key}`。需要抽出公共解析与跳转，避免各模块各自定义。

## What Changes

- 约定：`FundeH5:` 前缀 → 后缀为 H5 路由；`FundeApp:` 前缀 → 后缀为本地 App 路由。
- 新增公共 `FundePageURL`（解析 + 打开）。
- 首页 getByCode 点击、健康 getCmsConfig（体征卡 / 快捷入口）统一走该入口。
- 健康页不再将 `FundeH5:` 转成原生 `/health/metrics/...` 再间接开 H5（有前缀时直接按规则打开）。

## Impact

- Affected: `Other/Common/FundePageURL.swift`（新）、Home、Health PL/BLL、相关 OpenSpec
- 无 Apifox 变更

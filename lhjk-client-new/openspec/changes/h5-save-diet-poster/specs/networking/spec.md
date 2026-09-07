## ADDED Requirements

### Requirement: 已认证二进制 GET

`APIManager` SHALL 支持已认证 GET 并返回原始 `Data`，供海报等非 JSON 下载使用。

#### Scenario: 成功返回图片字节

- **WHEN** BLL 调用 `getDataAsync` 且 HTTP 成功、body 为图片二进制
- **THEN** 返回该 `Data`，不按 `APIResponse` JSON 解码

#### Scenario: 成功 HTTP 但 body 为业务错误 JSON

- **WHEN** 响应可解析为含非成功 `code` 的 JSON（如 `A0230`）
- **THEN** 抛出对应 API 错误，并走既有会话失效检测

## ADDED Requirements

### Requirement: FundeBridge 保存食谱到相册

饮食方案 H5 点击「保存食谱到手机」时，iOS SHALL 经 `FundeBridge` 接收 `action=saveImageToAlbum`，使用 App 登录态请求 `GET /v1/diningScheme/downloadDietPoster`，将响应二进制图片写入系统相册。

#### Scenario: 保存成功

- **WHEN** H5 向 `FundeBridge` postMessage，`action` 为 `saveImageToAlbum`
- **THEN** 从 body（或缺省 `params`）读取 `dateTime`、`schemeId`、`fileName`、`bizType`
- **AND** `fileName` 缺省为「食谱清单.png」，`bizType` 缺省为 `dietPoster`
- **AND** 以当前登录 Token 请求 `GET /v1/diningScheme/downloadDietPoster`，query 仅带非空的 `dateTime`、`schemeId`、`bizType`
- **AND** 将响应按二进制解码为图片并写入相册
- **AND** 宿主提示「已保存到相册」

#### Scenario: 下载或解码失败

- **WHEN** 接口返回业务 JSON 错误、会话失效，或 body 不是可解码图片
- **THEN** 不写入相册
- **AND** 宿主提示失败原因（会话失效走既有登录失效处理）

#### Scenario: 用户拒绝相册权限

- **WHEN** 系统相册添加权限为拒绝或受限
- **THEN** 不写入相册
- **AND** 提示用户可在系统设置中允许访问相册

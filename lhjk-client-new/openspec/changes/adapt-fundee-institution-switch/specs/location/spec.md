## ADDED Requirements

### Requirement: 高德与腾讯经纬度互转

定位模块 SHALL 在不引入第三方地图 SDK 的前提下，提供高德与腾讯地图经纬度互转。

#### Scenario: 转换方向

- **WHEN** 业务需要把设备/高德同系坐标提交给标注为高德、实为腾讯坐标系的后端接口
- **THEN** 调用 `gaodeToTencent`
- **WHEN** 业务需要把接口返回的腾讯坐标转为高德同系以便与本地定位比较
- **THEN** 调用 `tencentToGaode`

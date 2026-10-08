# 商品行「出租」标记

## 数据

Apifox `saleFlag`（int32）：**1 租 / 2 售**。

| 页面 | 接口 | 字段位置 | 现状 |
|------|------|----------|------|
| 套餐详情 | `GET /v1/hospitalPackage/getHospitalPackageDetail` | `packageHospitalDetailList[].saleFlag`（含子行 `children`） | 已解码并映射到 `ServicePackageComboItem.saleFlag` |
| 订单详情 | `GET /v1/order/getAppOrderDetail` | `shoppingCartPackageDetailList[].saleFlag`（[文档](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330739e0.md)） | 明细模型原先未解该字段 |

展示规则：`PackageSaleFlag.showsRentBadge` 仅在值为 `1` 时为真。

## UI

对齐 [Figma 3980:4737](https://www.figma.com/design/JEIKBLlcPpylp8GJ7BVmFd/%F0%9F%8C%9F%E5%BC%80%E5%8F%91%E5%AF%B9%E6%8E%A5-%E9%A1%B9%E7%9B%AE%E6%8F%90%E4%BA%A4?node-id=3980-4737) 与截图：标记贴在商品名右侧，天数/价格列保持右对齐。

- 切图：`Assets.xcassets/订单详情/package_detail_ rent`（imageset 名含空格；@2x 为 80×32，展示 40×16pt）
- 套餐详情：`ComboBenefitRowView`（必选、单选、多选及子行共用）
- 订单详情：`OrderDetailPackageView.makeContentRow`

名称过长时先压缩名称，标记保持可见。

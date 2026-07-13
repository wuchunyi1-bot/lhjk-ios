## 1. 模型与目录

- [x] 1.1 `MallProduct` 增加 `emoji`；`ServiceCatalogService` 提供与 `services.json` 对齐的本地 mall 列表 + `product(id:)`
- [x] 1.2 注册 `/orders/confirm` 占位（params: id）

## 2. 详情页

- [x] 2.1 实现 `MallProductDetailViewController`（Hero / 价格 / 亮点 / 人群 / 详情 / 步骤 / 承诺 / 底栏）
- [x] 2.2 分类 copy 与主题色应用；空态「商品不存在」
- [x] 2.3 `ServiceRoutes` 将 `/mall/detail` 指向详情 VC；咨询 / 购买跳转

## 3. 列表入口

- [x] 3.1 `HealthMallViewController` 点击商品卡进入详情；提示新文件加入 Xcode

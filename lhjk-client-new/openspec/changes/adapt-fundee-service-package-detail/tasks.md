## 1. 列表 id

- [x] 1.1 `HospitalPackagePageVO` 解析 `id`；`HospitalPackageMapper` 写入 `HealthPackageItem.id`

## 2. 详情 API

- [x] 2.1 DTO + Mapper：`getHospitalPackageDetail` → `ServicePackageDetail`
- [x] 2.2 `HospitalPackageService.fetchPackageDetail`；临时 `hospitalId`
- [x] 2.3 ViewModel + VC 异步加载；轮播支持图片 URL

## 3. Spec

- [x] 3.1 更新 `service-package-detail` spec：三段式布局、连续楼层、吸顶 Tab

## 4. 布局修复（对齐 funde HealthPackageDetailView）

- [x] 4.1 TableView 三段式：Banner / 简介卡 / 权益+详情卡
- [x] 4.2 权益与详情连续展示，Tab 仅用于滚动定位与吸顶
- [x] 4.3 组合组隐藏组名与 icon；修复单选默认可选逻辑
- [x] 4.4 应付金额 = 已选商品单价之和；参考价固定不变

## 5. checkType 与子项

- [x] 5.1 Spec：必选锁定 / 单选 radio / 多选 checkbox / 子项缩进
- [x] 5.2 Mapper 保留父行+children，写入 `isChild`
- [x] 5.3 ComboGroupView 按图示渲染控件与子项缩进

## 6. 角标文案与 Tab 定位

- [x] 6.1 分组头强制展示「必选 / 单选 / 可选」
- [x] 6.2 修复 Tab 楼层定位：去掉重复 sticky 扣减，计入 cell inset + 浮动 Tab 高度，动画后二次校正

## 7. 套餐详情 Figma (3449:7764) 样式重构

- [x] 7.1 顶部 Banner：1:1 正方形全宽尺寸，超出截取中间、不够上下留黑，右下角页码角标与悬浮返回按钮
- [x] 7.2 价格与简介卡：橙红渐变价格条、白色圆角带边框标题简介卡片、推荐/热销印章角标
- [x] 7.3 权益分组卡片：`#FFFCF8` 背景与 `#FFEEDC` 边框、顶部渐变带「—— 必选/单选/可选 ——」、单选/多选控件样式
- [x] 7.4 详情长图全量展开：按实际尺寸高度连续加载 `imageDetailsUrl1~3`，不截断
- [x] 7.5 移除吸顶 Tab：删除浮动 Tab 栏及吸顶滚动监听
- [x] 7.6 底部栏与整页对齐：112x40 胶囊加购与立即下单按钮、应付总价展示
- [x] 7.7 修复滑动时权益卡片被挤压遮挡问题：将 TableView 托管 Cell 改为 UIScrollView 原生滚动流布局，修复长图与权益卡片的 AutoLayout 约束冲突
- [x] 7.8 价格兜底优化：详情页未配置或拿不到价格时统一展示为「¥ 0 元起」，严禁展示「面议」
- [x] 7.9 套餐详情 Figma 背景图与切图资源精细化对齐：集成价格卡片暗纹背景 `package_detail_price_bg`、权益礼品盒插图 `package_detail_benefits_illust`、印章角标 `package_detail_stamp_recommend` / `package_detail_stamp_hot`、羽翼装饰 `package_detail_wing_left` / `package_detail_wing_right`、Radio/Checkbox 选中切图以及空态 Banner 占位图 `package_detail_banner_placeholder`
- [x] 7.10 修复价格与简介卡层叠覆盖布局：价格框向上覆盖 Banner 底部 28pt（`customSpacing = -28`，`zPosition = 1`），页码角标上移 40pt 保持在价格条上方 12pt（对齐 Figma 3449:7764）



# 商品行「出租」标记

## Why

套餐与订单里的设备有租、售两种形式。移动端需要在商品名称旁标出「出租」；出售不展示标记，避免和后台「设备形式」列一一对应成两种标签。

## What Changes

- 套餐详情权益行、订单详情套餐内容行：`saleFlag == 1` 时在名称后展示 `package_detail_ rent`（40×16pt）
- `saleFlag == 2`、空值或其它值不展示
- 订单详情解码 `shoppingCartPackageDetailList[].saleFlag`（兼容数字/字符串）
- 确认订单页不在本期范围

## Non-goals

- 不展示「出售」文案或图标
- 不改确认订单、购物车、订单列表

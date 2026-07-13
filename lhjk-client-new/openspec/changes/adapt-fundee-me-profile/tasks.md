## 1. 模型

- [x] 1.1 扩展 `SUsersOnboardingPayload`：email、career、education、idType、idNumber、nationality、ethnic、addressProvince、addressCity、addressArea、address 等
- [x] 1.2 证件类型中文 ↔ Int 映射表

## 2. UI

- [x] 2.1 重写 `ProfileViewController`：居中头像 + 三组字段卡片
- [x] 2.2 实现底部 `ProfileFieldEditorSheet`（text/select/date）
- [x] 2.3 移除昵称、富德 ID、收货地址、缺失 hint
- [x] 2.4 保留头像 OSS 上传

## 3. 校验

- [x] 3.1 对照 Vue 字段顺序与只读规则；新文件提示加入 Xcode

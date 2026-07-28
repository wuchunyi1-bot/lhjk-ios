## ADDED Requirements

### Requirement: 资料行左右对齐

个人信息页每一字段行 SHALL 采用「标题左对齐、取值右对齐」布局，对齐 `ProfileView.vue` `.info-row`。

#### Scenario: 对齐规则

- **WHEN** 渲染任意字段行（含只读与可编辑）
- **THEN** 左侧 label 固定约 88pt、文字左对齐、颜色为次要文案色
- **AND** 中间 value 占满剩余空间、文字右对齐；过长省略
- **AND** 可编辑行最右侧展示 `›`；只读行不展示箭头

#### Scenario: 空值占位

- **WHEN** 可编辑字段无值
- **THEN** value 展示占位文案并以 muted 色右对齐
- **WHEN** 只读字段无值
- **THEN** value 仍右对齐展示占位，无箭头

---

## MODIFIED Requirements

### Requirement: 姓名可编辑

个人基础信息中的「姓名」SHALL 可编辑（与 Vue / page-spec 一致）；手机号仍只读。

#### Scenario: 打开编辑

- **WHEN** 用户点击姓名行
- **THEN** 打开底部编辑弹层（text），标题「编辑姓名」

#### Scenario: 必填校验

- **WHEN** 保存时姓名为空
- **THEN** toast「请填写姓名」，不关闭弹层
- **WHEN** 姓名去空白后长度 &lt; 2
- **THEN** toast「请输入真实姓名」

#### Scenario: 保存成功

- **WHEN** 校验通过
- **THEN** 本地回显 → `updateCurrentProfile` 提交 `chineseName` → 成功 toast「姓名已保存」并刷新用户信息
- **AND** 同步更新头像首字兜底（若无头像图）

#### Scenario: 必填标识

- **WHEN** 渲染姓名行
- **THEN** label 前展示红色 `*`

#### Scenario: 手机号仍只读

- **WHEN** 用户点击手机号行
- **THEN** 不打开编辑器；无箭头；展示脱敏手机号

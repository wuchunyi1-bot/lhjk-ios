# Project Architecture — PL Layer ViewModels

## Purpose

在 PL 层每个 VC 对应的目录中新增 `ViewModels/` 子目录，与 `Cells/`、`Components/` 并列，用于存放该 VC 的 ViewModel。

## Requirements

### Requirement: PL Layer File Organization (VC-Centric + ViewModels)

PL 层的每个业务模块 SHALL 以 **VC 为中心** 组织文件夹结构，并在每个 VC 目录下可选包含 `ViewModels/` 子目录：

**模块级别结构**（以 `My/` 为例）：
```
ModuleName/
├── XxxViewController.swift          ← 主 VC（模块入口页）
├── ViewModels/                      ← 主 VC 的 ViewModel
│   └── XxxViewModel.swift
├── Cells/                           ← 主 VC 用到的 Cell
│   └── XxxCell.swift
├── Components/                      ← 主 VC 用到的自定义控件
│   └── XxxView.swift
├── SubPageA/                        ← 二级页面（子 VC 文件夹）
│   ├── SubPageAViewController.swift
│   ├── ViewModels/                  ← 该子 VC 的 ViewModel
│   │   └── SubPageAViewModel.swift
│   ├── Cells/
│   │   └── XxxCell.swift
│   ├── Components/
│   │   └── XxxView.swift
│   └── SubSubPage/                  ← 三级页面
│       └── ...
└── SubPageB/
    └── ...
```

**核心原则**：

1. **VC 即文件夹中心**：每个 VC 所在文件夹，其 Cell 放入 `Cells/` 子目录，自定义控件（非 Cell 的 View）放入 `Components/` 子目录，ViewModel 放入 `ViewModels/` 子目录
2. **ViewModel 与 VC 一一对应**：一个 VC 对应一个 ViewModel 文件，命名规则 `{Prefix}ViewModel.swift`（如 `HomeViewModel.swift`、`ChatViewModel.swift`）
3. **ViewModels/ 为可选目录**：简单页面（如纯静态展示、无数据逻辑）可以没有 ViewModel
4. **ViewModel 属于 PL 层**：ViewModel 负责 UI 状态管理和数据格式化，调用 BLL Service 获取数据；不包含业务规则（业务规则属于 BLL Service）
5. **二级 VC 必须独立建文件夹**：子页面 VC 不得平铺在上级目录中；文件夹名与模块/页面名称对应
6. **递归适用**：三级、四级页面同样遵循上述规则

#### Scenario: 为已有 VC 新增 ViewModel
- **WHEN** 需要为一个已存在的 ViewController 抽取 ViewModel
- **THEN** 在该 VC 所在文件夹下创建 `ViewModels/` 子目录，将 ViewModel 文件放入其中
- **AND** ViewModel 文件名与 VC 名对应：`HomeViewController.swift` → `HomeViewModel.swift`

#### Scenario: 新建 VC 时同步创建 ViewModel
- **WHEN** 新建一个包含数据逻辑的 ViewController
- **THEN** 在创建 VC 文件夹的同时创建 `ViewModels/` 子目录和对应的 ViewModel 文件
- **AND** ViewController 通过 `bindViewModel()` 方法订阅 ViewModel 的发布者

#### Scenario: 审查目录结构
- **WHEN** 需要检查 PL 层目录是否符合规范
- **THEN** 检查要点：
  - 有数据逻辑的 VC 是否包含对应的 `ViewModels/` 目录（建议但非强制）
  - `ViewModels/` 中的文件是否与 VC 一一对应
  - `Cells/`、`Components/`、`ViewModels/` 的命名是否统一使用首字母大写的英文单词

# QuickNav 开发文档

## 1. 开发目标

QuickNav 是一个 macOS 常驻型快捷导航应用，首阶段以个人本地使用为目标，不上架 App Store，不启用 App Sandbox。实现重点是全局快捷键唤起、鼠标方向选择、圆形浮窗菜单、动作执行和 JSON 配置管理。

开发按 PRD 的版本节奏推进：

- V0.1：验证圆形菜单交互和角度命中逻辑。
- V0.2：接入菜单栏常驻、全局快捷键、URL/app 动作和 JSON 配置。
- V0.3：补齐设置页、权限状态、命令动作和错误提示。
- V1.0：稳定常驻、多显示器适配、完整配置化和本地打包。

## 2. 版本迭代与 Git 流程

QuickNav 采用“主分支保存稳定版本、版本分支承载开发”的节奏：

1. 确认当前版本状态。对照 PRD 和代码完成度判断当前开发版本，例如当前代码已超过 V0.2 但 V0.3 未完成，因此当前开发版本是 V0.3。
2. 从最新 `main` 创建版本分支。版本分支命名为 `release/<version>`，例如当前 V0.3 使用 `release/0.3.0`。
3. 日常开发在版本分支进行。小改动可以直接提交到版本分支；较独立的新能力可以从版本分支切 `feature/<short-name>`，完成后合回版本分支。
4. 如果需要阶段性测试版，从对应版本分支切出 beta 分支。beta 分支命名为 `release/<version>-beta.<n>`，例如 `release/0.3.0-beta.1`、`release/0.3.0-beta.2`。SemVer 预发布版本使用连字符和点分隔标识，因此不要写成 `0.3.0bata`、`0.3.0beta` 或 `0.3.0-beta1`。
5. beta 分支用于打包、验收和修复该轮测试发现的问题。测试版 tag 命名为 `v<version>-beta.<n>`，例如 `v0.3.0-beta.1`。
6. beta 测试通过后，把需要保留的修复合回正式版本分支 `release/<version>`。如果还需要下一轮测试，再从最新版本状态切出下一轮 beta 分支。
7. 缺陷修复使用 `fix/<short-name>`。修复目标属于哪个版本，就从对应版本分支切出并合回对应版本分支。
8. 每次提交使用 Conventional Commits 格式：`<type>[optional scope]: <description>`。示例：`feat(action): add command action support`、`fix(config): handle invalid json gracefully`、`docs: document release workflow`。
9. 版本完成后，在版本分支执行默认验证。当前项目默认运行 `swift build`；如果本次改动涉及核心逻辑或已有测试，补充运行 `swift test`。
10. 验证通过后，把 `release/<version>` 合并回 `main`。
11. 在 `main` 上打正式版本 tag，命名为 `v<version>`，例如 `v0.3.0`。
12. 开启下一个版本时，从最新 `main` 创建新的版本分支，例如 `release/0.4.0` 或 `release/1.0.0`。

分支命名约定：

- 稳定主分支：`main`
- 版本开发分支：`release/0.3.0`、`release/0.4.0`、`release/1.0.0`
- 测试版分支：`release/0.3.0-beta.1`、`release/0.3.0-beta.2`
- 功能分支：`feature/command-action`
- 修复分支：`fix/hotkey-registration`

提交类型约定：

- `feat`: 新功能
- `fix`: 缺陷修复
- `docs`: 文档更新
- `refactor`: 不改变外部行为的代码重构
- `test`: 测试新增或调整
- `chore`: 构建、工具、依赖或仓库维护

## 3. 技术栈

| 层级 | 技术 | 用途 |
|---|---|---|
| 语言 | Swift | macOS 原生开发 |
| UI | SwiftUI | 圆形菜单、设置页、菜单项视图 |
| 系统能力 | AppKit | 应用生命周期、菜单栏、浮动窗口、Dock 策略 |
| 全局快捷键 | Carbon HotKey 或 AppKit 事件监听 | 注册 Control + Space 并识别按下/释放 |
| 鼠标事件 | NSEvent / CGEvent | 获取鼠标位置、移动轨迹和释放事件 |
| 动作执行 | NSWorkspace / Process | 打开 URL、启动 app、执行命令 |
| 配置 | Codable + JSONDecoder / JSONEncoder | 读写本地配置 |
| 测试 | XCTest | 角度计算、配置解析、动作校验 |
| 日志 | os.Logger | 输出配置、权限、动作失败信息 |

## 4. 首版默认决策

PRD 中部分问题在实现前需要固定默认值，后续可在配置或设置页中开放：

| 问题 | V0.1/V0.2 默认值 |
|---|---|
| 默认菜单项数量 | 8 个，配置不足时按实际数量均分 |
| 角度起点 | 屏幕右侧为 0 度 |
| 排列方向 | 顺时针 |
| 默认快捷键 | Control + Space |
| Dock 图标 | V0.2 起默认隐藏 |
| command 动作 | 推迟到 V0.3，V0.2 先完成 url/app |
| 配置位置 | `~/Library/Application Support/QuickNav/config.json` |
| 默认取消半径 | 36px |
| 默认菜单半径 | 140px |

## 5. 目录结构

项目根目录建议如下：

```text
quick-nav-for-mac/
├── prd.md
├── docs/
│   └── development.md
├── quick-nav-for-mac.xcodeproj
├── QuickNav/
│   ├── QuickNav/
│   │   ├── App/
│   │   │   ├── QuickNavApp.swift
│   │   │   └── AppDelegate.swift
│   │   ├── Controllers/
│   │   │   ├── StatusBarController.swift
│   │   │   ├── RadialWindowController.swift
│   │   │   └── SettingsWindowController.swift
│   │   ├── Models/
│   │   │   ├── AppError.swift
│   │   │   ├── HotKeyConfig.swift
│   │   │   ├── MenuState.swift
│   │   │   ├── NavAction.swift
│   │   │   ├── NavConfig.swift
│   │   │   └── RadialMenuItem.swift
│   │   ├── Services/
│   │   │   ├── ActionExecutor.swift
│   │   │   ├── ConfigManager.swift
│   │   │   ├── HotKeyManager.swift
│   │   │   ├── MouseTracker.swift
│   │   │   └── PermissionManager.swift
│   │   ├── State/
│   │   │   └── AppState.swift
│   │   ├── Utils/
│   │   │   ├── AngleCalculator.swift
│   │   │   ├── ScreenResolver.swift
│   │   │   └── QuickNavLogger.swift
│   │   ├── Views/
│   │   │   ├── RadialMenuItemView.swift
│   │   │   ├── RadialMenuView.swift
│   │   │   ├── SettingsView.swift
│   │   │   └── StatusView.swift
│   │   ├── Resources/
│   │   │   └── default-config.json
│   │   ├── Assets.xcassets
│   │   └── Info.plist
├── QuickNavTests/
│   ├── AngleCalculatorTests.swift
│   ├── ConfigManagerTests.swift
│   └── ActionExecutorTests.swift
└── README.md
```

说明：

- `docs/` 保存产品、开发和实现说明，不放 Xcode 生成文件。
- `quick-nav-for-mac.xcodeproj` 是 Xcode project 文件。
- `QuickNav/` 是 app target 源码根目录，保持产品和 Swift module 命名清晰。
- `QuickNavTests/` 是 XCTest target。
- 图片原型或截图后续建议迁移到 `docs/assets/`，避免散落在根目录。

## 6. 模块职责

### 6.1 App

`QuickNavApp.swift`

- SwiftUI app 入口。
- 挂载 `AppDelegate`。
- 初始化共享 `AppState`。
- 不直接包含业务逻辑。

`AppDelegate.swift`

- 配置应用为菜单栏常驻。
- V0.2 起隐藏 Dock 图标。
- 初始化 `StatusBarController`、`ConfigManager`、`HotKeyManager`、`RadialWindowController`。
- 处理应用启动和退出清理。

### 6.2 Controllers

`StatusBarController.swift`

- 创建菜单栏图标和菜单。
- 提供启用/禁用、重新加载配置、打开配置文件、设置、关于、退出。
- 展示快捷键注册失败或权限不足的轻量状态。

`RadialWindowController.swift`

- 创建透明、无边框、置顶的 `NSPanel` 或 `NSWindow`。
- 将 SwiftUI 的 `RadialMenuView` 承载到窗口中。
- 根据鼠标所在屏幕修正窗口位置。
- 控制菜单显示、隐藏和动画入口。

`SettingsWindowController.swift`

- V0.3 引入。
- 负责打开和复用设置窗口。
- 承载 `SettingsView`。

### 6.3 Models

`NavConfig.swift`

- 顶层配置模型。
- 包含 `hotKey` 和 `menu` 两部分。
- 通过 `Codable` 和 JSON 配置互转。

`HotKeyConfig.swift`

- 快捷键配置模型。
- 存储主键和修饰键。
- 负责转换到系统快捷键注册所需的数据结构。

`RadialMenuItem.swift`

- 菜单项配置模型。
- 包含 `id`、`title`、`icon`、`type`、`value`。

`NavAction.swift`

- 动作枚举。
- V0.2 支持 `url`、`app`。
- V0.3 增加 `command`。

`MenuState.swift`

- 当前菜单运行态。
- 包含中心点、是否可见、当前选中项 ID、菜单项列表。

`AppError.swift`

- 统一描述配置、权限、快捷键、动作执行失败。
- 便于日志输出和后续 UI 展示。

### 6.4 Services

`ConfigManager.swift`

- 计算用户配置路径。
- 首次启动时复制 `default-config.json`。
- 加载、解析、校验和重载配置。
- 配置损坏时返回内置默认配置并记录错误。

`HotKeyManager.swift`

- 注册和注销全局快捷键。
- 识别按下和释放事件。
- 向上层发出 `hotKeyDown`、`hotKeyUp` 事件。
- 注册失败时返回明确错误。

`MouseTracker.swift`

- 菜单显示期间监听鼠标移动。
- 未显示菜单时不做高频监听。
- 输出鼠标当前位置给 `MenuState` 更新选中项。

`ActionExecutor.swift`

- 根据 `NavAction` 执行动作。
- `url` 使用 `NSWorkspace.shared.open(_:)`。
- `app` 使用 `NSWorkspace.shared.openApplication(at:configuration:)` 或等效 API。
- `command` V0.3 使用 `Process`，仅面向本地个人配置。
- 所有失败都返回错误，不直接崩溃。

`PermissionManager.swift`

- 检查辅助功能权限。
- 提供跳转系统设置的入口。
- 权限不足时不阻塞菜单栏基础操作。

### 6.5 Utils

`AngleCalculator.swift`

- 根据中心点、鼠标点、取消半径、菜单项数量计算选中索引。
- 纯函数实现，不依赖 AppKit 窗口状态。
- 必须有 XCTest 覆盖 4、6、8 项菜单。

命中规则：

```text
distance < deadZoneRadius -> nil
angle = atan2(deltaY, deltaX)
normalizedAngle = 转换到 0...360，以右侧为 0 度
index = round(normalizedAngle / sectorAngle) % itemCount
```

macOS 坐标系和屏幕坐标可能存在 Y 轴方向差异，`AngleCalculator` 内部必须明确输入坐标约定。建议统一使用屏幕全局坐标，并在测试中固定右、下、左、上四个方向的预期结果。

`ScreenResolver.swift`

- 根据鼠标点找到所在 `NSScreen`。
- 当菜单靠近屏幕边缘时修正窗口 frame。
- 多显示器无法判断时兜底使用主屏幕。

`QuickNavLogger.swift`

- 封装 `os.Logger`。
- 按 `config`、`hotkey`、`permission`、`action`、`ui` 分类输出。

## 7. 核心流程

### 7.1 启动流程

```text
QuickNavApp
  -> AppDelegate.applicationDidFinishLaunching
  -> ConfigManager.loadOrCreateConfig
  -> StatusBarController.setup
  -> PermissionManager.checkAccessibilityPermission
  -> HotKeyManager.register(config.hotKey)
  -> 等待快捷键事件
```

### 7.2 菜单唤起流程

```text
HotKeyManager.hotKeyDown
  -> 读取当前鼠标位置
  -> MenuState 设置中心点和菜单项
  -> RadialWindowController.show(at:)
  -> MouseTracker.start
  -> 鼠标移动时 AngleCalculator 更新 selectedItem
```

### 7.3 菜单释放流程

```text
HotKeyManager.hotKeyUp
  -> MouseTracker.stop
  -> 读取 MenuState.selectedItem
  -> RadialWindowController.hide
  -> selectedItem 为空则取消
  -> selectedItem 非空则 ActionExecutor.execute
  -> 记录成功或失败日志
```

### 7.4 配置重载流程

```text
StatusBarController.reloadConfig
  -> ConfigManager.reload
  -> HotKeyManager.unregister
  -> HotKeyManager.register(newHotKey)
  -> AppState 更新菜单项
  -> 状态栏显示最新状态
```

## 8. 配置文件

默认配置文件放在 app bundle 的 `Resources/default-config.json`：

```json
{
  "hotKey": {
    "key": "space",
    "modifiers": ["control"]
  },
  "menu": {
    "radius": 140,
    "deadZoneRadius": 36,
    "items": [
      {
        "id": "github",
        "title": "GitHub",
        "icon": "globe",
        "type": "url",
        "value": "https://github.com"
      },
      {
        "id": "vscode",
        "title": "VSCode",
        "icon": "app",
        "type": "app",
        "value": "/Applications/Visual Studio Code.app"
      }
    ]
  }
}
```

校验规则：

- `hotKey.key` 不能为空。
- `hotKey.modifiers` 至少包含一个修饰键。
- `menu.radius` 必须大于 `menu.deadZoneRadius`。
- `menu.items` 首版限制为 0 到 8 个。
- `item.id` 在同一配置内必须唯一。
- `url` 类型必须能解析为合法 URL。
- `app` 类型必须是 `.app` 路径。
- `command` 类型 V0.3 前允许出现在配置中，但不执行，并记录未支持日志。

## 9. 版本实施计划

### V0.1 原型

交付内容：

- 创建 macOS SwiftUI app 工程。
- 实现 `RadialMenuView` 和 `RadialMenuItemView`。
- 实现 `RadialWindowController` 的基础展示。
- 使用模拟菜单项。
- 鼠标移动时更新选中项。
- 快捷键释放先用本地调试入口模拟。
- 实现 `AngleCalculator` 和测试。

验收：

- 菜单项均匀分布。
- 中心取消区不选中。
- 右、下、左、上方向命中符合顺时针规则。
- 选中项有明确高亮。

### V0.2 可用版本

交付内容：

- 菜单栏常驻。
- 默认隐藏 Dock 图标。
- 全局快捷键 Control + Space。
- JSON 配置加载和重载。
- URL 和 app 动作执行。
- 基础日志。

验收：

- 应用启动后出现在菜单栏。
- 按住快捷键显示菜单，松开关闭。
- 选择 URL 后打开浏览器。
- 选择 app 后启动应用。
- 配置损坏时应用不崩溃。

### V0.3 优化版本

交付内容：

- 设置窗口。
- 权限状态提示。
- 快捷键展示和修改。
- command 动作。
- 动作失败提示。
- 动画优化。

验收：

- 设置页能打开配置文件和重新加载配置。
- 权限不足有明确入口。
- command 动作按个人本地配置执行。
- 快速按下/释放不会残留菜单。

## 10. 测试策略

### 单元测试

重点覆盖：

- `AngleCalculator`：4、6、8 项，右/下/左/上/边界角度/取消半径。
- `ConfigManager`：默认配置、用户配置、损坏 JSON、缺失字段、重复 ID。
- `ActionExecutor`：URL 参数合法性、app 路径校验、未支持动作。

### 手动测试

每个版本至少执行：

- 快速按下并释放快捷键。
- 鼠标回到中心取消。
- 菜单靠近屏幕四个边缘。
- 修改配置后重载。
- 配置文件损坏后启动。
- 多显示器下在不同屏幕唤起。

### 性能检查

- 未唤起菜单时 CPU 接近 0。
- 菜单唤起延迟目标小于 100ms。
- 鼠标移动时选中态更新无明显卡顿。

## 11. 开发约定

- 业务状态集中在 `AppState` 和 `MenuState`，视图只负责渲染和轻量交互。
- 系统 API 封装在 `Services/` 和 `Controllers/`，不要散落到 SwiftUI View 中。
- 角度命中、配置校验等纯逻辑放到可测试模块。
- 动作执行必须先关闭菜单，再执行外部动作。
- 任何配置、权限、快捷键、动作失败都记录日志。
- V0.2 前不做复杂抽象，只有当新增动作类型或设置页需要复用时再提协议。
- 不启用 App Sandbox，后续如需发布再单独评估权限和安全边界。

## 12. 后续可扩展点

- `NavAction` 增加打开文件/文件夹、macOS Shortcut、AppleScript。
- 支持多套 Profile。
- 支持嵌套菜单。
- 设置页提供菜单项可视化编辑。
- 本地日志文件和错误历史。
- 打包为 `.dmg` 或 `.pkg`。

# QuickNav 项目协作规则

## 版本分支与提交规则

- `main` 只保存已经完成并验证过的稳定版本结果。不要直接在 `main` 上开发功能。
- 每个版本开始开发前，先从最新 `main` 创建版本分支，命名为 `release/<version>`，例如 `release/0.3.0`、`release/0.4.0`、`release/1.0.0`。
- 版本分支代表该版本的集成开发线。当前项目的 V0.3 开发分支是 `release/0.3.0`。
- 如果需要给某个版本创建测试版，从对应版本分支切出预发布验证分支，命名为 `release/<version>-beta.<n>`，例如 `release/0.3.0-beta.1`。不要使用 `0.3.0bata`、`0.3.0beta` 这类非标准写法。
- beta 分支只用于打包、验收和修复该轮测试发现的问题。下一轮测试从最新版本分支或上一轮 beta 修复结果切出 `release/<version>-beta.<n+1>`。
- beta 测试通过后，把需要保留的修复合回正式版本分支 `release/<version>`；正式版本仍在 `release/<version>` 上收口，并最终合并回 `main`。
- 如果一个版本内包含较独立的功能，可以从对应版本分支再切功能分支，命名为 `feature/<short-name>`，例如 `feature/command-action`。功能完成后先合回版本分支。
- 修复分支使用 `fix/<short-name>`，例如 `fix/hotkey-registration`。修复目标是哪个版本，就从哪个版本分支切出并合回哪个版本分支。
- 版本完成后，先确认 `swift build` 通过，再把 `release/<version>` 合并回 `main`，然后在 `main` 上打正式 tag，tag 命名为 `v<version>`，例如 `v0.3.0`。测试版 tag 命名为 `v<version>-beta.<n>`，例如 `v0.3.0-beta.1`。
- 下一个版本必须从合并后的最新 `main` 创建新的 `release/<next-version>` 分支，避免跨版本开发状态互相污染。
- 提交信息使用 Conventional Commits 格式：`<type>[optional scope]: <description>`。
- 常用提交类型：
  - `feat`: 新功能，例如 `feat(action): add command action support`。
  - `fix`: 缺陷修复，例如 `fix(config): handle invalid menu items`。
  - `docs`: 文档更新，例如 `docs: add release branch workflow`。
  - `refactor`: 不改变行为的重构，例如 `refactor(settings): split theme controls`。
  - `test`: 测试新增或调整，例如 `test(config): cover legacy action migration`。
  - `chore`: 构建、工具或维护事项，例如 `chore: update package metadata`。
- 提交描述使用英文祈使句或简短动词短语，首字母小写，不以句号结尾。
- 如果提交包含破坏性变更，在提交正文中写 `BREAKING CHANGE: <description>`。

## 代码注释要求

- 本项目面向 Swift 和 macOS 原生应用开发初学者维护，新增或大幅修改 Swift 代码时，注释需要比常规项目更细致。
- 主要维护者熟悉前端开发和 Python，但不熟悉 Swift/macOS 原生应用；注释应优先用前端/Python 容易理解的语言解释 Swift 和 AppKit 概念。
- 文件级注释需说明该文件在应用架构中的职责、主要能力，以及它和其它核心对象的关系。
- 类型级注释需说明 `class`、`struct`、`enum`、`protocol` 的用途、生命周期或状态归属。
- 方法级注释需说明触发时机、输入输出、关键副作用，以及和系统 API 的关系。
- 关键变量和属性需要变量级注释，尤其是以下场景：
  - 保存 AppKit/SwiftUI 对象生命周期的强引用。
  - 保存跨控制器共享状态的 `@Published`、`@State`、`@Binding`、`@ObservedObject`。
  - 表示 macOS 系统资源的变量，例如 hotkey、event tap、window、status item、file descriptor。
  - 用于坐标转换、窗口定位、鼠标偏移、主题派生、配置迁移的中间变量。
  - 非显而易见的布尔值、阈值、半径、尺寸、颜色 token。
- 注释应解释“为什么需要这个变量/逻辑”，不要只重复变量名或代码字面含义。
- 涉及 macOS 运行机制时，注释要补充背景，例如菜单栏应用、`NSApplicationDelegate`、`NSWindow`/`NSPanel`、`NSStatusItem`、Carbon HotKey、`NSAppearance`、SwiftUI state 更新。
- 可以用前端/Python 类比帮助理解，例如：
  - 把 SwiftUI `View` 类比为 React/Vue 组件。
  - 把 `@State`、`@Binding`、`@Published` 类比为组件 state、props 双向绑定、可观察 store。
  - 把 `NSApplicationDelegate` 类比为应用级生命周期入口。
  - 把 `NSWindow`/`NSPanel` 类比为独立浏览器窗口或浮层容器。
  - 把闭包回调类比为前端事件 handler 或 Python callable。
  - 把 `Codable` 配置读写类比为 Python dataclass/pydantic model 与 JSON 序列化。
- 简单局部变量如果代码语义已经非常明确，可以不强行注释；但一旦变量影响应用状态、系统资源或用户交互，需要补充说明。
- 注释语言使用中文，代码标识符保持英文。

## 样式与系统组件优先级

- 新增 UI 样式、视觉效果或交互控件前，优先调研 SwiftUI / AppKit 是否已有系统原生组件、系统材质或标准控件可用。
- 能使用系统原生能力时，优先使用 SwiftUI / AppKit 提供的实现，例如 `Material`、`NSVisualEffectView`、系统按钮样式、系统颜色、系统控件状态和 macOS 标准交互。
- 只有在系统原生能力无法满足设计目标、兼容性要求或交互需求时，才使用自定义样式。
- 如果选择自定义样式，需要在实现前说明为什么系统原生组件不适用，并尽量保持视觉、动效和行为贴近 macOS 原生体验。
- 对 macOS 半透明、毛玻璃、弹出层、分页指示器、按钮、菜单、列表、输入控件等常见 UI，不要直接手写视觉效果；先检查 SwiftUI / AppKit 是否有对应方案。

## 运行与验证

- 修改代码后默认只运行 `swift build` 验证编译。
- 不要主动启动或重启 QuickNav；运行和调试由用户在 Xcode 中执行。
- 如果需要排查运行中实例，先用 `pgrep -fl QuickNav` 说明当前状态，再等待用户确认是否停止进程。

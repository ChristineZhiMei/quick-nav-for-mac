# QuickNav 项目协作规则

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

## 运行与验证

- 修改代码后默认只运行 `swift build` 验证编译。
- 不要主动启动或重启 QuickNav；运行和调试由用户在 Xcode 中执行。
- 如果需要排查运行中实例，先用 `pgrep -fl QuickNav` 说明当前状态，再等待用户确认是否停止进程。

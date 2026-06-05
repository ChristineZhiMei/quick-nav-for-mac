# QuickNav 设计文档：Raycast 风格方向

## 1. 设计定位

QuickNav 是 macOS 常驻型快捷导航应用，核心体验是全局快捷键唤起后，在鼠标附近出现一个轻量、明确、可快速确认方向的圆形菜单。

视觉风格采用 Raycast inspired 方向，但不照搬 Raycast 的命令面板形态。QuickNav 应保留自己的径向选择模型，把 Raycast 的克制、高对比、键盘效率感和 macOS 原生质感转译到悬浮菜单、菜单栏和后续设置页中。

本设计文档基于本地 `awesome-design-md/design-md/raycast/README.md` 指向的 Raycast Inspired Design System 入口整理。完整 `DESIGN.md` 可通过 `npx getdesign@latest add raycast` 获取；当前环境访问 npm registry 时出现 `ECONNRESET`，因此本文先沉淀可直接用于 QuickNav 的设计规范。

## 2. 设计原则

### 2.1 快速，不打扰

- 菜单只在用户按住快捷键时出现。
- 视觉层级必须清楚，但不能像普通窗口一样抢占注意力。
- 出现、选中、关闭动画要短，避免影响方向选择。

### 2.2 信息密度高

- 优先展示动作图标和短标题。
- 不在菜单上展示说明文案、使用教程或冗余状态。
- 设置页采用紧凑的工具型布局，而不是营销页或大面积卡片。

### 2.3 强反馈，低装饰

- 选中项需要明显，但通过颜色、缩放、阴影和对比实现。
- 背景装饰、渐变光斑、复杂插画不用于核心界面。
- UI 元素服务于识别和执行，不制造额外视觉负担。

### 2.4 macOS 原生感

- 使用半透明、模糊、阴影和系统字体建立原生浮层质感。
- 控件尺寸和动效节奏接近 macOS 工具类应用。
- 菜单栏、权限提示、设置页遵循 macOS 用户预期。

## 3. 视觉语言

### 3.1 色彩

QuickNav 默认使用深色浮层。Raycast 风格的关键不是大面积红色，而是深色基底上的清晰层级和少量强调色。

| 用途 | 建议值 | 说明 |
|---|---:|---|
| 浮层背景 | `#111113` / 92% opacity | 主菜单底色 |
| 浮层描边 | `#FFFFFF` / 10% opacity | 区分桌面背景 |
| 次级分隔 | `#FFFFFF` / 8% opacity | 设置页分隔线 |
| 主文字 | `#F5F5F7` | 标题、选中项文字 |
| 次文字 | `#A1A1AA` | 辅助信息 |
| 弱文字 | `#71717A` | 非关键状态 |
| 选中强调 | `#FF4D4D` | 当前命中项、关键状态 |
| 成功状态 | `#30D158` | 配置加载成功等状态 |
| 警告状态 | `#FFD60A` | 权限或快捷键冲突提醒 |
| 错误状态 | `#FF453A` | 动作失败、配置错误 |

实现建议：

- 浮层背景优先使用 `NSVisualEffectView` 或 SwiftUI `.ultraThinMaterial` / `.regularMaterial`，再叠加深色半透明遮罩。
- 选中强调色只用于当前目标和关键操作，不作为大面积背景色。
- 桌面背景复杂时，描边和阴影必须足够稳定，保证菜单边界可识别。

### 3.2 字体

使用 macOS 系统字体，不引入自定义字体。

| 场景 | 字号 | 字重 |
|---|---:|---|
| 菜单项标题 | 11-12 | Medium |
| 设置页标题 | 16-20 | Semibold |
| 设置项标题 | 13-14 | Medium |
| 设置项说明 | 12-13 | Regular |
| 状态/快捷键信息 | 11-12 | Regular / Medium |

规则：

- 不使用负字距。
- 不用随视口变化的字体大小。
- 菜单项标题最多 1 行，过长时截断。
- 设置页文本以可扫描为目标，避免大标题堆叠。

### 3.3 圆角和形状

| 元素 | 圆角 |
|---|---:|
| 径向菜单整体背景 | 999 / 圆形 |
| 菜单项命中区域 | 14-18 |
| 图标容器 | 12-14 |
| 设置页输入框 | 8 |
| 设置页按钮 | 8 |
| 弹窗/面板 | 12 |

规则：

- 工具型卡片最大圆角不超过 8，除非是浮层、弹窗或菜单项图标容器。
- 不使用过度胶囊化的文字按钮；能用图标表达的操作优先用图标按钮。

### 3.4 阴影

径向菜单需要在任何桌面背景上可见。

```text
主浮层阴影：0 18 60 rgba(0, 0, 0, 0.45)
选中项阴影：0 8 24 rgba(255, 77, 77, 0.28)
图标弱阴影：0 4 12 rgba(0, 0, 0, 0.25)
```

阴影用于浮层分离和选中反馈，不用于制造装饰层。

## 4. 径向菜单设计

### 4.1 默认尺寸

| 参数 | 默认值 | 可配置范围 |
|---|---:|---:|
| 外半径 | 140px | 120-160px |
| 取消半径 | 36px | 28-40px |
| 菜单项尺寸 | 52px | 44-56px |
| 图标尺寸 | 22px | 18-24px |
| 标题与图标间距 | 6px | 4-8px |

菜单窗口建议尺寸：

```text
windowSize = radius * 2 + itemSize + safePadding * 2
safePadding = 24px
```

### 4.2 结构

径向菜单由以下层级组成：

1. 透明置顶窗口。
2. 深色半透明圆形背景。
3. 中心取消区域。
4. 8 个方向菜单项。
5. 当前选中方向的高亮状态。

视觉规则：

- 默认菜单项为低对比状态：深灰图标底、白色图标、弱文字。
- 当前选中项放大 1.08-1.12 倍。
- 当前选中项使用红色强调底或红色描边，两者二选一。
- 中心取消区域保持低调，可显示一个小圆点或 `Esc`/关闭图标，但不要显示解释文案。

### 4.3 选中态

选中态必须同时具备至少 3 种反馈：

- 颜色：accent 红色或亮色描边。
- 尺寸：轻微放大。
- 阴影：强调色柔和外发光。
- 文字：标题从弱文字切换到主文字。

不要只依赖颜色表达选中状态。

### 4.4 取消态

鼠标回到中心取消半径内时：

- 所有菜单项恢复默认状态。
- 中心区域可轻微变亮。
- 松开快捷键只关闭菜单，不执行动作。

取消态不能展示错误或警告感，避免用户误判。

### 4.5 边缘处理

靠近屏幕边缘时：

- 菜单窗口整体向屏幕内偏移。
- 视觉中心仍尽量接近原始鼠标位置。
- 如果无法完全显示，优先保证当前鼠标所在方向和中心区域可见。

## 5. 动效

Raycast 风格的动效应短、干净、响应明确。

| 动作 | 时长 | 曲线 | 说明 |
|---|---:|---|---|
| 菜单出现 | 120-160ms | easeOut | 透明度 0 到 1，缩放 0.94 到 1 |
| 菜单项展开 | 120-180ms | spring / easeOut | 从中心向目标位置移动 |
| 选中切换 | 80-120ms | easeOut | 放大、颜色和阴影变化 |
| 菜单关闭 | 90-130ms | easeIn | 透明度降低，缩放 0.98 到 0.92 |

规则：

- 鼠标移动命中计算必须先于动画表现。
- 快速划过多个方向时，不要排队播放动画。
- 用户松开快捷键后立即关闭菜单，再执行动作。

## 6. 图标

### 6.1 图标来源

首版可使用 SF Symbols，保证 macOS 原生一致性。

推荐映射：

| 动作类型 | 图标 |
|---|---|
| URL | `globe` / `safari` |
| App | `app.dashed` / app bundle icon |
| 文件夹 | `folder` |
| 命令 | `terminal` |
| 设置 | `gearshape` |
| 重载 | `arrow.clockwise` |
| 启用 | `bolt.fill` |
| 禁用 | `pause.fill` |

### 6.2 图标规则

- 菜单项优先显示图标，标题作为辅助。
- 如果能读取 app bundle icon，app 动作优先显示真实应用图标。
- URL 动作后续可支持 favicon，但首版不强依赖网络。
- 图标线条保持一致，不混用多种风格。

## 7. 设置页设计

V0.3 后的设置页采用 Raycast 命令面板式工具布局，而不是系统偏好设置的大表单。

### 7.1 布局

建议尺寸：

```text
窗口宽度：720-840px
窗口高度：480-620px
```

结构：

1. 顶部搜索/快捷入口区。
2. 左侧导航：General、Menu、Actions、Permissions、Advanced。
3. 右侧内容：紧凑表单和动作列表。
4. 底部状态：配置路径、加载状态、版本信息。

### 7.2 控件

- 开关：启用/禁用 QuickNav。
- 快捷键录制控件：修改全局快捷键。
- Stepper 或数字输入：半径、取消半径、菜单项尺寸。
- 列表：快捷项配置。
- 图标按钮：新增、删除、重排、重载。
- 普通按钮：打开配置文件、打开权限设置。

设置页不要使用大面积卡片嵌套。每个设置组可使用分隔线和标题组织。

## 8. 菜单栏设计

菜单栏图标应简洁、单色，适配浅色和深色菜单栏。

菜单项：

- `Enable QuickNav`
- `Reload Config`
- `Open Config File`
- `Settings...`
- `About QuickNav`
- `Quit QuickNav`

状态表达：

- 正常：普通菜单栏图标。
- 禁用：图标透明度降低。
- 错误：菜单内显示简短状态项，如 `Hotkey unavailable`。
- 权限不足：菜单内提供 `Open Accessibility Settings`。

## 9. 文案规范

界面文案使用英文，保持短句，符合 macOS 工具应用习惯。

规则：

- 菜单项标题使用 1-2 个词：`GitHub`、`VS Code`、`Projects`。
- 设置项标题使用名词短语：`Hotkey`、`Menu Radius`。
- 错误信息清楚但不冗长：`Config failed to load`。
- 不在界面里解释使用方式或展示长教程。

## 10. SwiftUI 实现建议

### 10.1 设计令牌

建议建立 `DesignTokens.swift`：

```swift
enum DesignTokens {
    enum Color {
        static let overlayBackground = SwiftUI.Color.black.opacity(0.72)
        static let overlayStroke = SwiftUI.Color.white.opacity(0.10)
        static let textPrimary = SwiftUI.Color(red: 0.96, green: 0.96, blue: 0.97)
        static let textSecondary = SwiftUI.Color(red: 0.63, green: 0.63, blue: 0.67)
        static let accent = SwiftUI.Color(red: 1.0, green: 0.30, blue: 0.30)
    }

    enum Radius {
        static let control: CGFloat = 8
        static let item: CGFloat = 16
        static let panel: CGFloat = 12
    }

    enum Motion {
        static let appear: Double = 0.14
        static let selection: Double = 0.10
        static let dismiss: Double = 0.10
    }
}
```

### 10.2 组件拆分

推荐组件：

- `RadialMenuView`
- `RadialMenuItemView`
- `CancelZoneView`
- `SelectionIndicatorView`
- `SettingsSidebarView`
- `SettingsSectionView`
- `ActionListRow`

组件规则：

- `RadialMenuView` 只负责布局和状态传递。
- 命中计算放在 `AngleCalculator`，不要写进 View。
- 动作执行放在 `ActionExecutor`，不要由 View 直接触发系统调用。

## 11. 验收清单

实现界面后按以下标准检查：

- 菜单在深色、浅色、复杂桌面背景上边界清晰。
- 快速移动鼠标时选中态响应没有明显延迟。
- 取消区域容易回到空选状态。
- 菜单项标题不会溢出或遮挡图标。
- 选中态不只依赖颜色。
- 菜单靠近屏幕边缘时仍可识别。
- 设置页没有嵌套卡片和营销式大标题。
- 菜单栏在浅色/深色模式下都可读。
- 所有错误状态能通过菜单栏或设置页定位。

## 12. 后续补充

当 `npx getdesign@latest add raycast` 可用后，可以把生成的 Raycast `DESIGN.md` 放入临时目录，与本文对照补充：

- 更精确的色彩 token。
- 官方示例组件结构。
- spacing、shadow、motion 的原始建议。
- 可复用截图或参考界面。

补充时应继续以 QuickNav 的产品形态为准，不把命令面板布局强行套到径向菜单上。

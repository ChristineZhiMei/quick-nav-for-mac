/**
 @SkillID QuickNavAppBootstrap
 @Description 启动 SwiftPM 形态的 macOS 菜单栏应用，并把 AppKit 生命周期交给 AppDelegate 管理。
 @Capabilities 创建 NSApplication 单例、挂载应用代理、设置 accessory 模式隐藏 Dock 图标、进入主事件循环。
 @LastUpdatedBy Codex
 */
import AppKit
import QuickNavAppKit

// SwiftPM 可执行程序入口：手动创建 AppKit 应用循环，而不是依赖 SwiftUI @main。
let app = NSApplication.shared

// AppDelegate 持有菜单栏、全局快捷键和导航浮层控制器，必须在 app.run() 期间保持强引用。
let delegate = AppDelegate()

app.delegate = delegate

// accessory 模式让 QuickNav 只出现在菜单栏，不在 Dock 中显示。
app.setActivationPolicy(.accessory)
app.run()

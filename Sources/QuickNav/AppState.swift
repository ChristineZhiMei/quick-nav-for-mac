/**
 @SkillID QuickNavSharedAppState
 @Description 保存菜单栏、设置窗口和径向导航共享的轻量运行状态。
 @Capabilities 控制 QuickNav 启用状态、记录快捷键可用性、暴露菜单几何参数、展示最近动作状态。
 @LastUpdatedBy Codex
 */
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    // 控制全局快捷键是否真的打开导航；状态栏和设置页都读写这个值。
    @Published var isEnabled = true

    // Carbon hotkey 注册结果，用于状态栏和设置页展示错误状态。
    @Published var isHotKeyAvailable = false

    // 当前全局快捷键配置，设置页修改后会触发 Carbon 重新注册。
    @Published var hotKeyConfig = HotKeyConfig.default

    // 全应用主题配置，设置页和径向导航都从这里派生语义色板。
    @Published var themeConfig = ThemeConfig.default

    // 设置页正在录入新快捷键时，全局快捷键事件不应打开导航。
    @Published var isRecordingHotKey = false

    var hotKeyDisplay: String {
        hotKeyConfig.displayText
    }

    // 菜单几何参数先同步设计默认值，后续接 JSON 配置时从 ConfigManager 写入。
    @Published var menuRadius = DesignTokens.Menu.radius

    // 中心缓冲区是导航中心“不选中任何应用”的安全范围，类似前端交互里的 dead area。
    @Published var deadZoneRadius = DesignTokens.Menu.deadZoneRadius

    // 径向菜单项的图标盒子尺寸，命中检测也会用它推导每个应用入口的可选中范围。
    @Published var itemSize = DesignTokens.Menu.itemSize

    // 控制导航背后的主题色扩散是否显示，关闭后只保留中心缓冲区和菜单项。
    @Published var isBackgroundVisible = DesignTokens.Menu.isBackgroundVisible

    // 背景半径控制径向渐变扩散到多远，类似 CSS radial-gradient 的结束半径。
    @Published var backgroundRadius = DesignTokens.Menu.backgroundRadius

    // 背景透明度控制扩散中心的最大 alpha，数值越大主题色越明显。
    @Published var backgroundOpacity = DesignTokens.Menu.backgroundOpacity

    // 状态栏和设置页底部共享的轻量反馈。
    @Published var statusMessage = "就绪"

    func themePalette(for colorScheme: ColorScheme) -> ThemePalette {
        ThemePaletteFactory.palette(for: themeConfig, colorScheme: colorScheme)
    }
}

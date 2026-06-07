/**
 @SkillID QuickNavSharedAppState
 @Description 保存菜单栏、设置窗口和径向导航共享的轻量运行状态。
 @Capabilities 控制 QuickNav 启用状态、记录快捷键可用性、暴露菜单几何参数、展示最近动作状态。
 @LastUpdatedBy Codex
 */
import Foundation

@MainActor
final class AppState: ObservableObject {
    // 控制全局快捷键是否真的打开导航；状态栏和设置页都读写这个值。
    @Published var isEnabled = true

    // Carbon hotkey 注册结果，用于状态栏和设置页展示错误状态。
    @Published var isHotKeyAvailable = false

    // 当前全局快捷键配置，设置页修改后会触发 Carbon 重新注册。
    @Published var hotKeyConfig = HotKeyConfig.default

    // 设置页正在录入新快捷键时，全局快捷键事件不应打开导航。
    @Published var isRecordingHotKey = false

    var hotKeyDisplay: String {
        hotKeyConfig.displayText
    }

    // 菜单几何参数先同步设计默认值，后续接 JSON 配置时从 ConfigManager 写入。
    @Published var menuRadius = DesignTokens.Menu.radius
    @Published var deadZoneRadius = DesignTokens.Menu.deadZoneRadius
    @Published var itemSize = DesignTokens.Menu.itemSize

    // 状态栏和设置页底部共享的轻量反馈。
    @Published var statusMessage = "就绪"
}

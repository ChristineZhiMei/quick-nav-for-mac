/**
 @SkillID QuickNavSettingsSurface
 @Description 管理 QuickNav 设置窗口，承载 Pencil 设计中 Visible settings panel 对应的深色设置界面。
 @Capabilities 创建/复用设置窗口、从状态栏或径向菜单打开设置、保持窗口前置、承载 SwiftUI SettingsView。
 @LastUpdatedBy Codex
 */
import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let appState: AppState
    private let configManager: ConfigManager
    private let applyHotKey: (HotKeyConfig) -> Void

    // 设置窗口保持复用，避免每次打开都创建新的窗口实例。
    private var window: NSWindow?

    init(appState: AppState, configManager: ConfigManager, applyHotKey: @escaping (HotKeyConfig) -> Void) {
        self.appState = appState
        self.configManager = configManager
        self.applyHotKey = applyHotKey
    }

    /**
     @name show
     @description 打开设置窗口。如果窗口已存在则直接前置，保持 macOS 工具面板的单实例体验。
     */
    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingView = NSHostingView(
            rootView: SettingsView(
                appState: appState,
                reloadConfig: { [weak self] in
                    do {
                        try self?.configManager.reload()
                        if let hotKeyConfig = try self?.configManager.loadHotKeyConfig() {
                            self?.applyHotKey(hotKeyConfig)
                        }
                        self?.appState.statusMessage = "已重载配置"
                    } catch {
                        self?.appState.statusMessage = "重载失败：\(error.localizedDescription)"
                    }
                },
                openConfigFile: { [weak self] in
                    guard let self else { return }
                    try? configManager.ensureConfigExists()
                    NSWorkspace.shared.open(configManager.configFileURL)
                },
                openConfigFolder: { [weak self] in
                    guard let self else { return }
                    try? configManager.ensureConfigExists()
                    NSWorkspace.shared.open(configManager.supportDirectoryURL)
                },
                openAccessibilitySettings: {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                },
                applyHotKey: applyHotKey
            )
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 526, height: 590),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "QuickNav 设置"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }
}

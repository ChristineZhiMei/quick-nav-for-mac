/**
 @SkillID QuickNavStatusMenu
 @Description 维护 macOS 右上角状态栏入口，以及 QuickNav 的基础状态菜单。
 @Capabilities 创建 Q 状态栏图标、展示快捷键状态、打开设置窗口、弹出 About、退出应用。
 @LastUpdatedBy Codex
 */
import AppKit

@MainActor
final class StatusBarController: NSObject {
    private let appState: AppState

    // NSStatusItem 是菜单栏入口本体，使用 squareLength 保证右上角稳定显示一个 Q。
    private let statusItem: NSStatusItem

    // 启用状态菜单项需要保存引用，便于点击后刷新勾选状态。
    private let enabledItem = NSMenuItem(title: "启用 QuickNav", action: #selector(toggleEnabled), keyEquivalent: "")

    // 快捷键状态菜单项用于反馈 Carbon 注册是否成功。
    private let hotKeyStatusItem = NSMenuItem(title: "快捷键：Command + Shift + D", action: nil, keyEquivalent: "")

    // 状态栏 Settings 菜单项的回调，由 AppDelegate 接到 SettingsWindowController。
    var onOpenSettings: (() -> Void)?
    var onToggleEnabled: ((Bool) -> Void)?
    var onReloadConfig: (() -> Void)?
    var onOpenConfigFile: (() -> Void)?
    var onOpenConfigFolder: (() -> Void)?
    var onOpenAccessibilitySettings: (() -> Void)?

    init(appState: AppState) {
        self.appState = appState
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
        rebuildMenu()
    }

    /**
     @name setHotKeyAvailable
     @description 根据快捷键注册结果刷新状态菜单文案。
     @link AppDelegate.applicationDidFinishLaunching
     */
    func setHotKeyAvailable(_ isAvailable: Bool) {
        appState.isHotKeyAvailable = isAvailable
        hotKeyStatusItem.title = isAvailable
            ? "快捷键：\(appState.hotKeyDisplay)"
            : "快捷键不可用：\(appState.hotKeyDisplay)"
        hotKeyStatusItem.state = isAvailable ? .on : .off
        rebuildMenu()
    }

    /**
     @name showMenu
     @description 程序化打开菜单栏菜单；保留给状态栏入口自检和后续调试使用。
     */
    func showMenu() {
        statusItem.button?.performClick(nil)
    }

    /**
     @name configureStatusItem
     @description 配置右上角状态栏可见入口。用文字 Q 而不是 SF Symbol，避免 SwiftPM 命令行形态下图标不可见。
     */
    private func configureStatusItem() {
        if let button = statusItem.button {
            button.title = "Q"
            button.font = .systemFont(ofSize: 13, weight: .semibold)
            button.toolTip = "QuickNav"
        }
    }

    /**
     @name rebuildMenu
     @description 构建状态菜单。导航浮层不从这里打开，菜单只提供状态、关于和退出。
     */
    private func rebuildMenu() {
        let menu = NSMenu()

        enabledItem.target = self
        enabledItem.state = appState.isEnabled ? .on : .off
        menu.addItem(enabledItem)

        hotKeyStatusItem.title = appState.isHotKeyAvailable
            ? "快捷键：\(appState.hotKeyDisplay)"
            : "快捷键不可用：\(appState.hotKeyDisplay)"
        hotKeyStatusItem.state = appState.isHotKeyAvailable ? .on : .off
        menu.addItem(hotKeyStatusItem)

        menu.addItem(.separator())

        let reloadItem = NSMenuItem(title: "重载配置", action: #selector(reloadConfig), keyEquivalent: "r")
        reloadItem.target = self
        menu.addItem(reloadItem)

        let openConfigItem = NSMenuItem(title: "打开配置文件", action: #selector(openConfigFile), keyEquivalent: "")
        openConfigItem.target = self
        menu.addItem(openConfigItem)

        let openConfigFolderItem = NSMenuItem(title: "打开配置目录", action: #selector(openConfigFolder), keyEquivalent: "")
        openConfigFolderItem.target = self
        menu.addItem(openConfigFolderItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let accessibilityItem = NSMenuItem(title: "打开辅助功能设置", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        accessibilityItem.target = self
        menu.addItem(accessibilityItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(title: "关于 QuickNav", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出 QuickNav", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    /**
     @name toggleEnabled
     @description 切换 QuickNav 是否响应全局快捷键，菜单状态立即反馈。
     */
    @objc private func toggleEnabled() {
        let nextValue = !appState.isEnabled
        onToggleEnabled?(nextValue)
        enabledItem.state = nextValue ? .on : .off
    }

    @objc private func reloadConfig() {
        onReloadConfig?()
    }

    @objc private func openConfigFile() {
        onOpenConfigFile?()
    }

    @objc private func openConfigFolder() {
        onOpenConfigFolder?()
    }

    @objc private func openAccessibilitySettings() {
        onOpenAccessibilitySettings?()
    }

    /**
     @name showAbout
     @description 展示当前原型阶段说明，便于从菜单栏确认应用状态。
     */
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "QuickNav"
        alert.informativeText = "菜单栏常驻应用，支持 Command+Shift+D 径向导航、设置面板、配置文件入口，以及基础应用、网址和文件夹动作。"
        alert.alertStyle = .informational
        alert.runModal()
    }

    /**
     @name openSettings
     @description 从状态栏菜单打开自定义设置窗口，窗口视觉来自 Pencil 的 Visible settings panel。
     */
    @objc private func openSettings() {
        onOpenSettings?()
    }

    /**
     @name quit
     @description 从状态菜单退出 QuickNav。
     */
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

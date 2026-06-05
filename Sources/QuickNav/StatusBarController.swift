/**
 @SkillID QuickNavStatusMenu
 @Description 维护 macOS 右上角状态栏入口，以及 QuickNav 的基础状态菜单。
 @Capabilities 创建 Q 状态栏图标、展示快捷键状态、弹出 About、退出应用、供导航第一项触发状态菜单。
 @LastUpdatedBy Codex
 */
import AppKit

@MainActor
final class StatusBarController: NSObject {
    // NSStatusItem 是菜单栏入口本体，使用 squareLength 保证右上角稳定显示一个 Q。
    private let statusItem: NSStatusItem

    // 快捷键状态菜单项用于反馈 Carbon 注册是否成功。
    private let hotKeyStatusItem = NSMenuItem(title: "Hotkey: Command + Shift + D", action: nil, keyEquivalent: "")

    override init() {
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
        hotKeyStatusItem.title = isAvailable
            ? "Hotkey: Command + Shift + D"
            : "Hotkey unavailable: Command + Shift + D"
        hotKeyStatusItem.state = isAvailable ? .on : .off
    }

    /**
     @name showMenu
     @description 程序化打开菜单栏菜单；当前由导航第一项 Menu 命中后调用。
     @link RadialWindowController.settleSelectionIfNeeded
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

        let enabledItem = NSMenuItem(title: "Enabled", action: nil, keyEquivalent: "")
        enabledItem.state = .on
        menu.addItem(enabledItem)

        hotKeyStatusItem.state = .on
        menu.addItem(hotKeyStatusItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(title: "About QuickNav", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit QuickNav", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    /**
     @name showAbout
     @description 展示当前原型阶段说明，便于从菜单栏确认应用状态。
     */
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "QuickNav"
        alert.informativeText = "Minimal SwiftPM prototype: menu bar, Command+Shift+D hotkey, and a basic radial navigation surface."
        alert.alertStyle = .informational
        alert.runModal()
    }

    /**
     @name quit
     @description 从状态菜单退出 QuickNav。
     */
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

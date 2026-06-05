/**
 @SkillID QuickNavLifecycleCoordinator
 @Description 负责 QuickNav 启动期对象装配，将菜单栏入口、全局快捷键和导航浮层串联起来。
 @Capabilities 初始化状态栏菜单、初始化径向导航窗口、注册 Command+Shift+D 全局快捷键、退出时释放快捷键资源。
 @LastUpdatedBy Codex
 */
import AppKit
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // 应用级日志，主要用于记录快捷键注册成功或失败。
    private let logger = Logger(subsystem: "QuickNav", category: "App")

    // 菜单栏控制器需要被 AppDelegate 强持有，否则 NSStatusItem 会被释放。
    private var statusBarController: StatusBarController?

    // Carbon 快捷键管理器需要保持生命周期，直到应用退出。
    private var hotKeyManager: HotKeyManager?

    // 导航窗口控制器集中维护浮层窗口、鼠标监听和光标隐藏状态。
    private var radialWindowController: RadialWindowController?

    /**
     @name applicationDidFinishLaunching
     @description 应用启动完成后装配核心控制器，并注册按住式全局快捷键。
     @link StatusBarController / RadialWindowController / HotKeyManager
     */
    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusBarController = StatusBarController()
        self.statusBarController = statusBarController

        let radialWindowController = RadialWindowController(
            onOpenStatusMenu: { [weak statusBarController] in
                statusBarController?.showMenu()
            }
        )
        self.radialWindowController = radialWindowController

        let hotKeyManager = HotKeyManager(
            onPress: { [weak radialWindowController] in
                radialWindowController?.beginNavigation()
            },
            onRelease: { [weak radialWindowController] in
                radialWindowController?.cancelNavigation()
            }
        )
        self.hotKeyManager = hotKeyManager

        do {
            try hotKeyManager.register()
            statusBarController.setHotKeyAvailable(true)
            logger.info("Registered Command+Shift+D hotkey")
        } catch {
            statusBarController.setHotKeyAvailable(false)
            logger.error("Failed to register hotkey: \(error.localizedDescription, privacy: .public)")
        }
    }

    /**
     @name applicationWillTerminate
     @description 应用退出前注销 Carbon hotkey 和事件处理器，避免系统级快捷键资源泄漏。
     @link HotKeyManager.unregister
     */
    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager?.unregister()
    }
}

/**
 @SkillID QuickNavLifecycleCoordinator
 @Description 负责 QuickNav 启动期对象装配，将菜单栏入口、全局快捷键和导航浮层串联起来。
 @Capabilities 初始化状态栏菜单、初始化设置窗口、初始化径向导航窗口、注册用户配置的全局快捷键、退出时释放快捷键资源。
 @LastUpdatedBy Codex
 */
import AppKit
import Darwin
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // 应用级日志，主要用于记录快捷键注册成功或失败。
    private let logger = Logger(subsystem: "QuickNav", category: "App")

    // 菜单栏控制器需要被 AppDelegate 强持有，否则 NSStatusItem 会被释放。
    private var statusBarController: StatusBarController?

    // 跨状态栏、设置页和径向菜单共享的轻量运行状态。
    private let appState = AppState()

    // 当前阶段创建默认 config.json，并提供重载、打开文件/目录入口。
    private let configManager = ConfigManager()

    // Carbon 快捷键管理器需要保持生命周期，直到应用退出。
    private var hotKeyManager: HotKeyManager?

    // 设置窗口控制器需要强持有，径向菜单第一项和状态栏 Settings 会复用同一个窗口。
    private var settingsWindowController: SettingsWindowController?

    // 径向菜单项动作执行器，避免窗口控制器直接调用系统打开逻辑。
    private var actionExecutor: ActionExecutor?

    // 导航窗口控制器集中维护浮层窗口、鼠标监听和光标隐藏状态。
    private var radialWindowController: RadialWindowController?

    // SwiftPM 和 Xcode 都能直接启动 QuickNav。这里用进程级文件锁避免多个实例同时常驻菜单栏。
    private var instanceLockFileDescriptor: CInt = -1

    /**
     @name applicationDidFinishLaunching
     @description 应用启动完成后装配核心控制器，并注册按住式全局快捷键。
     @link StatusBarController / RadialWindowController / HotKeyManager
     */
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard acquireSingleInstanceLock() else {
            logger.info("Another QuickNav instance is already running. Terminating duplicate instance.")
            NSApp.terminate(nil)
            return
        }

        do {
            try configManager.ensureConfigExists()
            appState.hotKeyConfig = try configManager.loadHotKeyConfig()
            appState.themeConfig = try configManager.loadThemeConfig()
        } catch {
            appState.statusMessage = "配置不可用：\(error.localizedDescription)"
            logger.error("Failed to prepare config: \(error.localizedDescription, privacy: .public)")
        }

        let statusBarController = StatusBarController(appState: appState)
        self.statusBarController = statusBarController

        let settingsWindowController = SettingsWindowController(
            appState: appState,
            configManager: configManager,
            applyHotKey: { [weak self] config in
                self?.applyHotKeyConfig(config, shouldSave: true)
            },
            applyTheme: { [weak self] config in
                self?.applyThemeConfig(config, shouldSave: true)
            }
        )
        self.settingsWindowController = settingsWindowController

        let actionExecutor = ActionExecutor(
            appState: appState,
            configManager: configManager,
            openSettings: { [weak settingsWindowController] in
                settingsWindowController?.show()
            }
        )
        self.actionExecutor = actionExecutor

        statusBarController.onOpenSettings = { [weak settingsWindowController] in
            settingsWindowController?.show()
        }
        statusBarController.onToggleEnabled = { [weak appState] isEnabled in
            appState?.isEnabled = isEnabled
            appState?.statusMessage = isEnabled ? "QuickNav 已启用" : "QuickNav 已停用"
        }
        statusBarController.onReloadConfig = { [weak self] in
            do {
                try self?.configManager.reload()
                if let hotKeyConfig = try self?.configManager.loadHotKeyConfig() {
                    self?.applyHotKeyConfig(hotKeyConfig, shouldSave: false)
                }
                if let themeConfig = try self?.configManager.loadThemeConfig() {
                    self?.applyThemeConfig(themeConfig, shouldSave: false)
                }
                self?.appState.statusMessage = "已重载配置"
            } catch {
                self?.appState.statusMessage = "重载失败：\(error.localizedDescription)"
            }
        }
        statusBarController.onOpenConfigFile = { [weak configManager] in
            guard let configManager else { return }
            try? configManager.ensureConfigExists()
            NSWorkspace.shared.open(configManager.configFileURL)
        }
        statusBarController.onOpenConfigFolder = { [weak configManager] in
            guard let configManager else { return }
            try? configManager.ensureConfigExists()
            NSWorkspace.shared.open(configManager.supportDirectoryURL)
        }
        statusBarController.onOpenAccessibilitySettings = {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }

        let radialWindowController = RadialWindowController(
            appState: appState,
            onSelectItem: { [weak actionExecutor] item in
                actionExecutor?.execute(item)
            }
        )
        self.radialWindowController = radialWindowController

        let hotKeyManager = HotKeyManager(
            onPress: { [weak radialWindowController, weak appState] in
                guard appState?.isEnabled == true, appState?.isRecordingHotKey == false else { return }
                radialWindowController?.beginNavigation()
            },
            onRelease: { [weak radialWindowController, weak appState] in
                guard appState?.isRecordingHotKey == false else { return }
                radialWindowController?.cancelNavigation()
            }
        )
        self.hotKeyManager = hotKeyManager

        do {
            try hotKeyManager.register(appState.hotKeyConfig)
            statusBarController.setHotKeyAvailable(true)
            logger.info("Registered hotkey: \(self.appState.hotKeyDisplay, privacy: .public)")
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
        releaseSingleInstanceLock()
    }

    /**
     @name applyHotKeyConfig
     @description 设置页应用新快捷键时，先注销旧快捷键，再注册新快捷键，并按需写回配置文件。
     */
    private func applyHotKeyConfig(_ config: HotKeyConfig, shouldSave: Bool) {
        do {
            let validatedConfig = try config.validated()
            try hotKeyManager?.register(validatedConfig)
            if shouldSave {
                try configManager.saveHotKeyConfig(validatedConfig)
            }
            appState.hotKeyConfig = validatedConfig
            statusBarController?.setHotKeyAvailable(true)
            appState.statusMessage = "快捷键已更新：\(validatedConfig.displayText)"
            logger.info("Updated hotkey: \(validatedConfig.displayText, privacy: .public)")
        } catch {
            statusBarController?.setHotKeyAvailable(false)
            appState.statusMessage = "快捷键更新失败：\(error.localizedDescription)"
            logger.error("Failed to update hotkey: \(error.localizedDescription, privacy: .public)")
        }
    }

    /**
     @name applyThemeConfig
     @description 设置页应用主题时更新共享状态，并按需写回本地配置。
     */
    private func applyThemeConfig(_ config: ThemeConfig, shouldSave: Bool) {
        do {
            if shouldSave {
                try configManager.saveThemeConfig(config)
            }
            appState.themeConfig = config
            appState.statusMessage = "主题已更新"
        } catch {
            appState.statusMessage = "主题保存失败：\(error.localizedDescription)"
            logger.error("Failed to save theme: \(error.localizedDescription, privacy: .public)")
        }
    }

    /**
     @name acquireSingleInstanceLock
     @description 通过 Application Support 下的 flock 文件锁保证同一用户会话中只运行一个 QuickNav 实例。
     @discussion Xcode 调试和 swift run 可能同时启动不同路径的 QuickNav 二进制，单靠 bundle identifier 不稳定。
     */
    private func acquireSingleInstanceLock() -> Bool {
        let fileManager = FileManager.default

        guard let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return true
        }

        let quickNavDirectory = supportDirectory.appendingPathComponent("QuickNav", isDirectory: true)
        try? fileManager.createDirectory(at: quickNavDirectory, withIntermediateDirectories: true)

        let lockURL = quickNavDirectory.appendingPathComponent("quicknav.lock")
        let descriptor = open(lockURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else {
            return true
        }

        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor)
            return false
        }

        instanceLockFileDescriptor = descriptor
        ftruncate(descriptor, 0)

        let pidText = "\(getpid())\n"
        pidText.withCString { pointer in
            _ = write(descriptor, pointer, strlen(pointer))
        }

        return true
    }

    /**
     @name releaseSingleInstanceLock
     @description 应用退出时释放单实例文件锁，避免影响下一次正常启动。
     */
    private func releaseSingleInstanceLock() {
        guard instanceLockFileDescriptor >= 0 else {
            return
        }

        flock(instanceLockFileDescriptor, LOCK_UN)
        close(instanceLockFileDescriptor)
        instanceLockFileDescriptor = -1
    }
}

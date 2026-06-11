/**
 @SkillID QuickNavApplicationCoordinator
 @Description 负责 QuickNav 启动期对象装配，将菜单栏入口、全局快捷键、设置窗口和导航浮层串联起来。
 @Capabilities 初始化共享状态、加载配置、初始化控制器、注册用户配置的全局快捷键、处理配置重载和退出清理。
 @LastUpdatedBy Codex
 */
import AppKit
import QuickNavCore
import os

@MainActor
final class QuickNavApplicationCoordinator {
    // 应用装配日志，主要用于记录快捷键注册、配置加载和主题保存失败。
    private let logger = Logger(subsystem: "QuickNav", category: "Coordinator")

    // 跨状态栏、设置页和径向菜单共享的轻量运行状态，类似前端全局 store。
    private let appState = AppState()

    // ConfigManager 只负责本地 JSON 文件读写，配置 shape 由 QuickNavCore 定义。
    private let configManager = ConfigManager()

    // 菜单栏控制器需要强持有，否则 NSStatusItem 会被释放。
    private var statusBarController: StatusBarController?

    // Carbon 快捷键管理器需要保持生命周期，直到应用退出。
    private var hotKeyManager: HotKeyManager?

    // 设置窗口控制器需要强持有，径向菜单第一项和状态栏 Settings 会复用同一个窗口。
    private var settingsWindowController: SettingsWindowController?

    // 径向菜单项动作执行器，避免窗口控制器直接调用系统打开逻辑。
    private var actionExecutor: ActionExecutor?

    // 导航窗口控制器集中维护浮层窗口、鼠标监听和光标隐藏状态。
    private var radialWindowController: RadialWindowController?

    /**
     @name start
     @description 应用启动时装配核心控制器，并注册按住式全局快捷键。
     */
    func start() {
        prepareInitialConfig()
        buildControllers()
        registerInitialHotKey()
    }

    /**
     @name stop
     @description 应用退出前注销 Carbon hotkey 和事件处理器，避免系统级快捷键资源泄漏。
     */
    func stop() {
        hotKeyManager?.unregister()
    }

    private func prepareInitialConfig() {
        do {
            try configManager.ensureConfigExists()
            appState.hotKeyConfig = try configManager.loadHotKeyConfig()
            appState.themeConfig = try configManager.loadThemeConfig()
            appState.applyMenuConfig(try configManager.loadMenuConfig())
        } catch {
            appState.statusMessage = "配置不可用：\(error.localizedDescription)"
            logger.error("Failed to prepare config: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func buildControllers() {
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

        wireStatusBar(statusBarController)

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
    }

    private func wireStatusBar(_ statusBarController: StatusBarController) {
        statusBarController.onOpenSettings = { [weak self] in
            self?.settingsWindowController?.show()
        }
        statusBarController.onToggleEnabled = { [weak appState] isEnabled in
            appState?.isEnabled = isEnabled
            appState?.statusMessage = isEnabled ? "QuickNav 已启用" : "QuickNav 已停用"
        }
        statusBarController.onReloadConfig = { [weak self] in
            self?.reloadConfig()
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
    }

    private func registerInitialHotKey() {
        do {
            try hotKeyManager?.register(appState.hotKeyConfig)
            statusBarController?.setHotKeyAvailable(true)
            logger.info("Registered hotkey: \(self.appState.hotKeyDisplay, privacy: .public)")
        } catch {
            statusBarController?.setHotKeyAvailable(false)
            logger.error("Failed to register hotkey: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func reloadConfig() {
        do {
            try configManager.reload()
            applyHotKeyConfig(try configManager.loadHotKeyConfig(), shouldSave: false)
            applyThemeConfig(try configManager.loadThemeConfig(), shouldSave: false)
            appState.applyMenuConfig(try configManager.loadMenuConfig())
            appState.statusMessage = "已重载配置"
        } catch {
            appState.statusMessage = "重载失败：\(error.localizedDescription)"
        }
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
}

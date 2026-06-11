/**
 @SkillID QuickNavActionExecutor
 @Description 执行径向菜单项的基础动作，隔离视图和系统调用。
 @Capabilities 打开设置窗口、启动 App、打开 URL、打开文件夹、重载配置、记录动作结果。
 @LastUpdatedBy Codex
 */
import AppKit
import Foundation
import QuickNavCore
import os

@MainActor
final class ActionExecutor {
    private let logger = Logger(subsystem: "QuickNav", category: "Action")
    private let appState: AppState
    private let configManager: ConfigManager
    private let openSettings: @MainActor () -> Void

    init(appState: AppState, configManager: ConfigManager, openSettings: @escaping @MainActor () -> Void) {
        self.appState = appState
        self.configManager = configManager
        self.openSettings = openSettings
    }

    /**
     @name execute
     @description 根据菜单项动作类型分发系统调用；失败只更新状态，不让菜单流程崩溃。
     */
    func execute(_ item: NavigationItem) {
        do {
            switch item.action {
            case .settings:
                openSettings()
                appState.statusMessage = "已打开设置"
            case let .openApp(bundleIdentifier, fallbackPath):
                try openApp(bundleIdentifier: bundleIdentifier, fallbackPath: fallbackPath, title: item.title)
            case let .openFolder(path):
                try openFileURL(URL(fileURLWithPath: NSString(string: path).expandingTildeInPath), title: item.title)
            case let .openURL(rawValue):
                try openWebURL(rawValue, title: item.title)
            case .reloadConfig:
                try configManager.reload()
                appState.statusMessage = "已重载配置"
            }
        } catch {
            appState.statusMessage = "\(item.title)失败：\(error.localizedDescription)"
            logger.error("Action failed for \(item.title, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    private func openApp(bundleIdentifier: String, fallbackPath: String?, title: String) throws {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            try openFileURL(appURL, title: title)
            return
        }

        if let fallbackPath {
            let fallbackURL = URL(fileURLWithPath: NSString(string: fallbackPath).expandingTildeInPath)
            try openFileURL(fallbackURL, title: title)
            return
        }

        throw QuickNavActionError.appNotFound(title)
    }

    private func openFileURL(_ url: URL, title: String) throws {
        guard NSWorkspace.shared.open(url) else {
            throw QuickNavActionError.openFailed(url.path)
        }
        appState.statusMessage = "已打开\(title)"
    }

    private func openWebURL(_ rawValue: String, title: String) throws {
        guard let url = URL(string: rawValue), NSWorkspace.shared.open(url) else {
            throw QuickNavActionError.openFailed(rawValue)
        }
        appState.statusMessage = "已打开\(title)"
    }
}

private enum QuickNavActionError: LocalizedError {
    case appNotFound(String)
    case openFailed(String)

    var errorDescription: String? {
        switch self {
        case let .appNotFound(title):
            return "未安装\(title)"
        case let .openFailed(target):
            return "无法打开 \(target)"
        }
    }
}

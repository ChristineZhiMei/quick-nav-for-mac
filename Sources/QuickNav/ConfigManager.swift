/**
 @SkillID QuickNavConfigManager
 @Description 管理 QuickNav 用户配置文件路径和最小可用默认配置。
 @Capabilities 创建 Application Support 目录、写入默认 config.json、重载配置占位、打开配置文件或目录。
 @LastUpdatedBy Codex
 */
import Foundation

@MainActor
final class ConfigManager {
    private let fileManager = FileManager.default

    var supportDirectoryURL: URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("QuickNav", isDirectory: true)
    }

    var configFileURL: URL {
        supportDirectoryURL.appendingPathComponent("config.json")
    }

    /**
     @name ensureConfigExists
     @description 首次使用时创建用户配置文件。当前菜单项仍以内置配置为准，文件先作为后续编辑入口。
     */
    func ensureConfigExists() throws {
        try fileManager.createDirectory(at: supportDirectoryURL, withIntermediateDirectories: true)

        guard !fileManager.fileExists(atPath: configFileURL.path) else { return }

        let data = try JSONSerialization.data(withJSONObject: defaultConfig, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: configFileURL, options: .atomic)
    }

    /**
     @name reload
     @description 验证配置文件存在并可读取。真实 JSON 驱动菜单会在后续接入。
     */
    func reload() throws {
        try ensureConfigExists()
        _ = try Data(contentsOf: configFileURL)
    }

    /**
     @name loadHotKeyConfig
     @description 从 config.json 读取快捷键配置；缺失或损坏时回退默认值。
     */
    func loadHotKeyConfig() throws -> HotKeyConfig {
        try ensureConfigExists()

        let data = try Data(contentsOf: configFileURL)
        let config = try JSONDecoder().decode(QuickNavUserConfig.self, from: data)
        return try config.hotKey.validated()
    }

    /**
     @name saveHotKeyConfig
     @description 将新的快捷键写回 config.json，同时保留当前菜单几何参数和内置菜单项。
     */
    func saveHotKeyConfig(_ hotKeyConfig: HotKeyConfig) throws {
        let validatedConfig = try hotKeyConfig.validated()
        try ensureConfigExists()

        var config = try? JSONDecoder().decode(QuickNavUserConfig.self, from: Data(contentsOf: configFileURL))
        config = config ?? defaultUserConfig
        config?.hotKey = validatedConfig

        let data = try JSONEncoder.prettyPrinted.encode(config ?? defaultUserConfig)
        try data.write(to: configFileURL, options: .atomic)
    }

    private var defaultConfig: [String: Any] {
        let data = (try? JSONEncoder().encode(defaultUserConfig)) ?? Data()
        let object = try? JSONSerialization.jsonObject(with: data)
        return object as? [String: Any] ?? [:]
    }

    private var defaultUserConfig: QuickNavUserConfig {
        QuickNavUserConfig(
            hotKey: .default,
            menu: QuickNavMenuConfig(
                radius: Int(DesignTokens.Menu.radius),
                deadZoneRadius: Int(DesignTokens.Menu.deadZoneRadius),
                itemSize: Int(DesignTokens.Menu.itemSize),
                items: RadialMenuView.items.map {
                    QuickNavMenuItemConfig(id: $0.id, title: $0.title, systemImage: $0.systemImage)
                }
            )
        )
    }
}

private struct QuickNavUserConfig: Codable {
    var hotKey: HotKeyConfig
    var menu: QuickNavMenuConfig
}

private struct QuickNavMenuConfig: Codable {
    var radius: Int
    var deadZoneRadius: Int
    var itemSize: Int
    var items: [QuickNavMenuItemConfig]
}

private struct QuickNavMenuItemConfig: Codable {
    var id: String
    var title: String
    var systemImage: String
}

private extension JSONEncoder {
    static var prettyPrinted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

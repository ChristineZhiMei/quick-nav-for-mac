/**
 @SkillID QuickNavNavigationModels
 @Description 定义 QuickNav 径向导航的领域模型，避免 SwiftUI 视图成为菜单数据来源。
 @Capabilities 描述菜单项、动作类型、菜单几何配置，以及默认内置菜单目录。
 @LastUpdatedBy Codex
 */
import Foundation

/// 径向菜单的单个入口。它类似前端菜单配置里的 item：视图只负责渲染，执行器根据 action 做系统调用。
public struct NavigationItem: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var systemImage: String
    public var action: NavigationAction

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case systemImage
        case action
    }

    public init(id: String, title: String, systemImage: String, action: NavigationAction) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        systemImage = try container.decode(String.self, forKey: .systemImage)

        // 旧版 config.json 的菜单项没有 action 字段。按 id 回填内置动作，避免架构迁移破坏用户已有配置。
        action = try container.decodeIfPresent(NavigationAction.self, forKey: .action)
            ?? DefaultNavigationCatalog.action(for: id)
            ?? .settings
    }
}

/// 菜单项可执行的动作。这里只描述“要做什么”，具体 NSWorkspace/Process 调用由 AppKit 层执行。
public enum NavigationAction: Codable, Equatable, Sendable {
    case settings
    case openApp(bundleIdentifier: String, fallbackPath: String?)
    case openFolder(String)
    case openURL(String)
    case reloadConfig
}

/// 菜单布局配置。后续 JSON 自定义菜单接入时，这个结构会成为配置文件和运行态之间的桥。
public struct QuickNavMenuConfig: Codable, Equatable, Sendable {
    public var radius: Double
    public var deadZoneRadius: Double
    public var itemSize: Double
    public var isBackgroundVisible: Bool
    public var backgroundRadius: Double
    public var backgroundOpacity: Double
    public var items: [NavigationItem]

    public init(
        radius: Double,
        deadZoneRadius: Double,
        itemSize: Double,
        isBackgroundVisible: Bool,
        backgroundRadius: Double,
        backgroundOpacity: Double,
        items: [NavigationItem]
    ) {
        self.radius = radius
        self.deadZoneRadius = deadZoneRadius
        self.itemSize = itemSize
        self.isBackgroundVisible = isBackgroundVisible
        self.backgroundRadius = backgroundRadius
        self.backgroundOpacity = backgroundOpacity
        self.items = items
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        radius = try container.decodeIfPresent(Double.self, forKey: .radius) ?? DesignTokens.Menu.radius
        deadZoneRadius = try container.decodeIfPresent(Double.self, forKey: .deadZoneRadius) ?? DesignTokens.Menu.deadZoneRadius
        itemSize = try container.decodeIfPresent(Double.self, forKey: .itemSize) ?? DesignTokens.Menu.itemSize
        isBackgroundVisible = try container.decodeIfPresent(Bool.self, forKey: .isBackgroundVisible) ?? DesignTokens.Menu.isBackgroundVisible
        backgroundRadius = try container.decodeIfPresent(Double.self, forKey: .backgroundRadius) ?? DesignTokens.Menu.backgroundRadius
        backgroundOpacity = try container.decodeIfPresent(Double.self, forKey: .backgroundOpacity) ?? DesignTokens.Menu.backgroundOpacity

        let decodedItems = try container.decodeIfPresent([NavigationItem].self, forKey: .items)
        items = decodedItems?.isEmpty == false ? decodedItems ?? DefaultNavigationCatalog.items : DefaultNavigationCatalog.items
    }

    public static let `default` = QuickNavMenuConfig(
        radius: DesignTokens.Menu.radius,
        deadZoneRadius: DesignTokens.Menu.deadZoneRadius,
        itemSize: DesignTokens.Menu.itemSize,
        isBackgroundVisible: DesignTokens.Menu.isBackgroundVisible,
        backgroundRadius: DesignTokens.Menu.backgroundRadius,
        backgroundOpacity: DesignTokens.Menu.backgroundOpacity,
        items: DefaultNavigationCatalog.items
    )
}

/// 顶层用户配置模型。它集中描述 config.json 的 shape，ConfigManager 只负责读写文件。
public struct QuickNavUserConfig: Codable, Equatable, Sendable {
    public var hotKey: HotKeyConfig
    public var theme: ThemeConfig
    public var menu: QuickNavMenuConfig

    public init(hotKey: HotKeyConfig, theme: ThemeConfig, menu: QuickNavMenuConfig) {
        self.hotKey = hotKey
        self.theme = theme
        self.menu = menu
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hotKey = try container.decodeIfPresent(HotKeyConfig.self, forKey: .hotKey) ?? .default
        theme = try container.decodeIfPresent(ThemeConfig.self, forKey: .theme) ?? .default
        menu = try container.decodeIfPresent(QuickNavMenuConfig.self, forKey: .menu) ?? .default
    }

    public static let `default` = QuickNavUserConfig(
        hotKey: .default,
        theme: .default,
        menu: .default
    )
}

/// 内置菜单目录是默认配置的唯一来源，设置页、径向菜单和配置创建都从这里派生。
public enum DefaultNavigationCatalog {
    public static let items: [NavigationItem] = [
        .init(id: "menu", title: "菜单", systemImage: "line.3.horizontal", action: .settings),
        .init(id: "vscode", title: "VS Code", systemImage: "chevron.left.forwardslash.chevron.right", action: .openApp(bundleIdentifier: "com.microsoft.VSCode", fallbackPath: "/Applications/Visual Studio Code.app")),
        .init(id: "terminal", title: "Terminal", systemImage: "terminal", action: .openApp(bundleIdentifier: "com.apple.Terminal", fallbackPath: "/System/Applications/Utilities/Terminal.app")),
        .init(id: "projects", title: "项目", systemImage: "folder", action: .openFolder("~/Documents/code")),
        .init(id: "docs", title: "文档", systemImage: "doc.text", action: .openFolder("~/Documents")),
        .init(id: "figma", title: "Figma", systemImage: "square.grid.2x2", action: .openApp(bundleIdentifier: "com.figma.Desktop", fallbackPath: nil)),
        .init(id: "browser", title: "浏览器", systemImage: "safari", action: .openURL("https://www.google.com")),
        .init(id: "downloads", title: "下载", systemImage: "arrow.down.circle", action: .openFolder("~/Downloads")),
        .init(id: "calendar", title: "日历", systemImage: "calendar", action: .openApp(bundleIdentifier: "com.apple.iCal", fallbackPath: "/System/Applications/Calendar.app")),
        .init(id: "reload", title: "重载", systemImage: "arrow.clockwise", action: .reloadConfig)
    ]

    public static func action(for id: String) -> NavigationAction? {
        items.first { $0.id == id }?.action
    }
}

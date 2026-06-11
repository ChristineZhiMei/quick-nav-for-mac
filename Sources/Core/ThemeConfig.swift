/**
 @SkillID QuickNavThemeConfig
 @Description 定义 QuickNav 主题配置和预设色 ID，不依赖 SwiftUI/AppKit 具体渲染类型。
 @Capabilities 支持跟随系统/明色/暗色模式、明暗预设主题、自定义 accent、旧默认色迁移。
 @LastUpdatedBy Codex
 */
import Foundation

/// 用户选择的外观模式。Core 只保存选择，具体 ColorScheme/NSAppearance 转换由 AppKit 模块完成。
public enum ThemeMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: "跟随系统"
        case .light: "明色"
        case .dark: "暗色"
        }
    }
}

/// 预设主题色 ID。它是配置值，不直接保存 SwiftUI Color，便于 JSON 稳定读写。
public enum ThemePresetID: String, Codable, CaseIterable, Identifiable, Sendable {
    case crimson
    case rose
    case blue
    case violet
    case emerald
    case amber
    case custom

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .crimson: "陶粉"
        case .rose: "Raycast 红"
        case .blue: "雾蓝"
        case .violet: "灰紫"
        case .emerald: "鼠尾草"
        case .amber: "暖沙"
        case .custom: "自定义"
        }
    }
}

/// 主题配置模型，类似 Python dataclass/pydantic model：负责数据 shape，不负责 UI 派生。
public struct ThemeConfig: Codable, Equatable, Sendable {
    public var mode: ThemeMode
    public var lightPreset: ThemePresetID
    public var darkPreset: ThemePresetID
    public var customLightAccent: String
    public var customDarkAccent: String

    public static let `default` = ThemeConfig(
        mode: .system,
        lightPreset: .crimson,
        darkPreset: .crimson,
        customLightAccent: "#B76E79",
        customDarkAccent: "#C9828B"
    )

    public init(
        mode: ThemeMode,
        lightPreset: ThemePresetID,
        darkPreset: ThemePresetID,
        customLightAccent: String,
        customDarkAccent: String
    ) {
        self.mode = mode
        self.lightPreset = lightPreset
        self.darkPreset = darkPreset
        self.customLightAccent = customLightAccent
        self.customDarkAccent = customDarkAccent
    }

    public var migratingLegacyDefaultAccents: ThemeConfig {
        var next = self

        // 旧版本默认自定义色是高饱和红色。这里仅迁移这些旧默认值，不覆盖用户改过的其它自定义色。
        if next.customLightAccent.normalizedHexString == "#E5484D" {
            next.customLightAccent = Self.default.customLightAccent
        }
        if next.customDarkAccent.normalizedHexString == "#FF453A" {
            next.customDarkAccent = Self.default.customDarkAccent
        }

        return next
    }
}

private extension String {
    var normalizedHexString: String {
        let sanitized = trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
        return "#\(sanitized)"
    }
}

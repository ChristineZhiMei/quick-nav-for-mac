/**
 @SkillID QuickNavThemePalette
 @Description 将 Core 主题配置派生为 SwiftUI/AppKit 可以直接渲染的语义色板。
 @Capabilities 解析明暗模式、生成 SwiftUI Color、提供 NSAppearance/ColorScheme 转换、计算 accent 对比文字。
 @LastUpdatedBy Codex
 */
import AppKit
import QuickNavCore
import SwiftUI

/// AppKit 层使用的明暗外观枚举，用于从配置值推导实际渲染色。
enum ThemeAppearance {
    case light
    case dark
}

/// SwiftUI 视图消费的语义色板，类似前端 design token 编译后的 CSS variables。
struct ThemePalette {
    let surface: Color
    let sidebar: Color
    let panel: Color
    let row: Color
    let border: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let accent: Color
    let accentText: Color
    let accentShadow: Color
    let success: Color
    let warning: Color
}

@MainActor
enum ThemePaletteFactory {
    static func palette(for config: ThemeConfig, colorScheme: ColorScheme) -> ThemePalette {
        let appearance = resolvedAppearance(for: config.mode, colorScheme: colorScheme)
        let accentHex = accentHex(for: config, appearance: appearance)
        let accent = Color(hex: accentHex)
        let base = basePalette(for: appearance)

        return ThemePalette(
            surface: base.surface,
            sidebar: base.sidebar,
            panel: base.panel,
            row: base.row,
            border: base.border,
            textPrimary: base.textPrimary,
            textSecondary: base.textSecondary,
            textMuted: base.textMuted,
            accent: accent,
            accentText: contrastText(for: accentHex),
            accentShadow: accent.opacity(0.35),
            success: appearance == .dark ? Color(hex: "#30D158") : Color(hex: "#10B981"),
            warning: appearance == .dark ? Color(hex: "#FFD60A") : Color(hex: "#D97706")
        )
    }

    static func accentPreview(for preset: ThemePresetID, appearance: ThemeAppearance, customHex: String) -> Color {
        if preset == .custom {
            return Color(hex: normalizedHex(customHex, fallback: accentHex(for: .crimson, appearance: appearance)))
        }
        return Color(hex: accentHex(for: preset, appearance: appearance))
    }

    private static func resolvedAppearance(for mode: ThemeMode, colorScheme: ColorScheme) -> ThemeAppearance {
        switch mode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return systemAppearance()
        }
    }

    private static func basePalette(for appearance: ThemeAppearance) -> ThemePalette {
        switch appearance {
        case .light:
            return ThemePalette(
                surface: Color(hex: "#F4F1EC"),
                sidebar: Color(hex: "#ECE8E1"),
                panel: Color(hex: "#FAF8F4"),
                row: Color(hex: "#FAF8F4"),
                border: Color(hex: "#D8D0C5"),
                textPrimary: Color(hex: "#2B2926"),
                textSecondary: Color(hex: "#6F6962"),
                textMuted: Color(hex: "#9A9288"),
                accent: Color(hex: "#B76E79"),
                accentText: .white,
                accentShadow: Color(hex: "#B76E79").opacity(0.35),
                success: Color(hex: "#8FA58E"),
                warning: Color(hex: "#C2A878")
            )
        case .dark:
            return ThemePalette(
                surface: Color(hex: "#171615"),
                sidebar: Color(hex: "#12110F"),
                panel: Color(hex: "#24221F"),
                row: Color(hex: "#24221F"),
                border: Color.white.opacity(0.08),
                textPrimary: Color(hex: "#F3EFE8"),
                textSecondary: Color(hex: "#B6AEA3"),
                textMuted: Color(hex: "#81786F"),
                accent: Color(hex: "#C9828B"),
                accentText: .white,
                accentShadow: Color(hex: "#C9828B").opacity(0.35),
                success: Color(hex: "#9AB09A"),
                warning: Color(hex: "#D0B982")
            )
        }
    }

    private static func accentHex(for config: ThemeConfig, appearance: ThemeAppearance) -> String {
        switch appearance {
        case .light:
            if config.lightPreset == .custom {
                return normalizedHex(config.customLightAccent, fallback: accentHex(for: .crimson, appearance: .light))
            }
            return accentHex(for: config.lightPreset, appearance: .light)
        case .dark:
            if config.darkPreset == .custom {
                return normalizedHex(config.customDarkAccent, fallback: accentHex(for: .crimson, appearance: .dark))
            }
            return accentHex(for: config.darkPreset, appearance: .dark)
        }
    }

    private static func contrastText(for hex: String) -> Color {
        guard let components = rgbComponents(from: hex) else {
            return .white
        }

        func linearized(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }

        let red = linearized(components.red)
        let green = linearized(components.green)
        let blue = linearized(components.blue)
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue

        return luminance > 0.42 ? .black : .white
    }

    private static func accentHex(for preset: ThemePresetID, appearance: ThemeAppearance) -> String {
        switch (preset, appearance) {
        case (.crimson, .light): "#B76E79"
        case (.rose, .light): "#FF6363"
        case (.blue, .light): "#7F95A3"
        case (.violet, .light): "#9A8FAE"
        case (.emerald, .light): "#8FA58E"
        case (.amber, .light): "#C2A878"
        case (.crimson, .dark): "#C9828B"
        case (.rose, .dark): "#FF6363"
        case (.blue, .dark): "#8EA6B4"
        case (.violet, .dark): "#A79AB8"
        case (.emerald, .dark): "#9AB09A"
        case (.amber, .dark): "#D0B982"
        case (.custom, _): "#C9828B"
        }
    }

    private static func systemAppearance() -> ThemeAppearance {
        let match = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        return match == .darkAqua ? .dark : .light
    }

    private static func normalizedHex(_ hex: String, fallback: String) -> String {
        let sanitized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
        guard sanitized.count == 6, UInt64(sanitized, radix: 16) != nil else {
            return fallback
        }
        return "#\(sanitized)"
    }

    private static func rgbComponents(from hex: String) -> (red: Double, green: Double, blue: Double)? {
        let sanitized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
        guard sanitized.count == 6, let value = UInt64(sanitized, radix: 16) else {
            return nil
        }

        return (
            red: Double((value & 0xFF0000) >> 16) / 255.0,
            green: Double((value & 0x00FF00) >> 8) / 255.0,
            blue: Double(value & 0x0000FF) / 255.0
        )
    }
}

extension ThemeMode {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system:
            return nil
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }
}

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red = Double((value & 0xFF0000) >> 16) / 255.0
        let green = Double((value & 0x00FF00) >> 8) / 255.0
        let blue = Double(value & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

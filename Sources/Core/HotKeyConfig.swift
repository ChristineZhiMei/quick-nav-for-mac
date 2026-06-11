/**
 @SkillID QuickNavHotKeyConfig
 @Description 描述可自定义全局快捷键，不直接依赖 Carbon，便于 Core 模块独立测试。
 @Capabilities 支持 Command/Shift/Option/Control 修饰键、A-Z/0-9 主键、展示文案、JSON 编解码。
 @LastUpdatedBy Codex
 */
import Foundation

/// 快捷键配置值对象，类似前端表单里的受控字段或 Python dataclass。
public struct HotKeyConfig: Codable, Equatable, Sendable {
    public var key: String
    public var modifiers: [HotKeyModifier]

    public static let `default` = HotKeyConfig(key: "S", modifiers: [.control])
    public static let supportedKeys = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".map(String.init))

    public init(key: String, modifiers: [HotKeyModifier]) {
        self.key = key
        self.modifiers = modifiers
    }

    public var normalizedKey: String {
        key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    public var displayText: String {
        let modifierText = HotKeyModifier.displayOrder
            .filter { modifiers.contains($0) }
            .map(\.displayText)
            .joined(separator: " + ")

        if modifierText.isEmpty {
            return normalizedKey
        }

        return "\(modifierText) + \(normalizedKey)"
    }

    /// 校验并规范化快捷键。Carbon keyCode 转换留给 QuickNavAppKit，Core 只关心业务规则。
    public func validated() throws -> HotKeyConfig {
        guard !modifiers.isEmpty else {
            throw HotKeyConfigError.missingModifier
        }

        guard normalizedKey.count == 1, Self.supportedKeys.contains(normalizedKey) else {
            throw HotKeyConfigError.unsupportedKey(normalizedKey)
        }

        return HotKeyConfig(
            key: normalizedKey,
            modifiers: HotKeyModifier.displayOrder.filter { modifiers.contains($0) }
        )
    }
}

/// 支持的快捷键修饰键。顺序固定后，展示文案和配置写回都更稳定。
public enum HotKeyModifier: String, Codable, CaseIterable, Identifiable, Sendable {
    case command
    case shift
    case option
    case control

    public static let displayOrder: [HotKeyModifier] = [.command, .shift, .option, .control]

    public var id: String { rawValue }

    public var displayText: String {
        switch self {
        case .command: "Command"
        case .shift: "Shift"
        case .option: "Option"
        case .control: "Control"
        }
    }
}

public enum HotKeyConfigError: LocalizedError, Equatable, Sendable {
    case missingModifier
    case unsupportedKey(String)

    public var errorDescription: String? {
        switch self {
        case .missingModifier:
            "至少选择一个修饰键"
        case let .unsupportedKey(key):
            "不支持的主键：\(key.isEmpty ? "空" : key)"
        }
    }
}

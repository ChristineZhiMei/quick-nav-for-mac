/**
 @SkillID QuickNavHotKeyConfig
 @Description 描述可自定义全局快捷键，并提供 Carbon 注册所需的 keyCode 和 modifier flags。
 @Capabilities 支持 Command/Shift/Option/Control 修饰键、A-Z/0-9 主键、展示文案、JSON 编解码、Carbon 参数转换。
 @LastUpdatedBy Codex
 */
import Carbon
import Foundation

struct HotKeyConfig: Codable, Equatable {
    var key: String
    var modifiers: [HotKeyModifier]

    static let `default` = HotKeyConfig(key: "S", modifiers: [.control])

    var normalizedKey: String {
        key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var displayText: String {
        let modifierText = HotKeyModifier.displayOrder
            .filter { modifiers.contains($0) }
            .map(\.displayText)
            .joined(separator: " + ")

        if modifierText.isEmpty {
            return normalizedKey
        }

        return "\(modifierText) + \(normalizedKey)"
    }

    var carbonModifiers: UInt32 {
        modifiers.reduce(UInt32(0)) { result, modifier in
            result | modifier.carbonFlag
        }
    }

    var carbonKeyCode: UInt32? {
        Self.keyCodeMap[normalizedKey]
    }

    func validated() throws -> HotKeyConfig {
        guard !modifiers.isEmpty else {
            throw HotKeyConfigError.missingModifier
        }

        guard normalizedKey.count == 1, carbonKeyCode != nil else {
            throw HotKeyConfigError.unsupportedKey(normalizedKey)
        }

        return HotKeyConfig(
            key: normalizedKey,
            modifiers: HotKeyModifier.displayOrder.filter { modifiers.contains($0) }
        )
    }

    private static let keyCodeMap: [String: UInt32] = [
        "A": UInt32(kVK_ANSI_A),
        "B": UInt32(kVK_ANSI_B),
        "C": UInt32(kVK_ANSI_C),
        "D": UInt32(kVK_ANSI_D),
        "E": UInt32(kVK_ANSI_E),
        "F": UInt32(kVK_ANSI_F),
        "G": UInt32(kVK_ANSI_G),
        "H": UInt32(kVK_ANSI_H),
        "I": UInt32(kVK_ANSI_I),
        "J": UInt32(kVK_ANSI_J),
        "K": UInt32(kVK_ANSI_K),
        "L": UInt32(kVK_ANSI_L),
        "M": UInt32(kVK_ANSI_M),
        "N": UInt32(kVK_ANSI_N),
        "O": UInt32(kVK_ANSI_O),
        "P": UInt32(kVK_ANSI_P),
        "Q": UInt32(kVK_ANSI_Q),
        "R": UInt32(kVK_ANSI_R),
        "S": UInt32(kVK_ANSI_S),
        "T": UInt32(kVK_ANSI_T),
        "U": UInt32(kVK_ANSI_U),
        "V": UInt32(kVK_ANSI_V),
        "W": UInt32(kVK_ANSI_W),
        "X": UInt32(kVK_ANSI_X),
        "Y": UInt32(kVK_ANSI_Y),
        "Z": UInt32(kVK_ANSI_Z),
        "0": UInt32(kVK_ANSI_0),
        "1": UInt32(kVK_ANSI_1),
        "2": UInt32(kVK_ANSI_2),
        "3": UInt32(kVK_ANSI_3),
        "4": UInt32(kVK_ANSI_4),
        "5": UInt32(kVK_ANSI_5),
        "6": UInt32(kVK_ANSI_6),
        "7": UInt32(kVK_ANSI_7),
        "8": UInt32(kVK_ANSI_8),
        "9": UInt32(kVK_ANSI_9)
    ]
}

enum HotKeyModifier: String, Codable, CaseIterable, Identifiable {
    case command
    case shift
    case option
    case control

    static let displayOrder: [HotKeyModifier] = [.command, .shift, .option, .control]

    var id: String { rawValue }

    var displayText: String {
        switch self {
        case .command: "Command"
        case .shift: "Shift"
        case .option: "Option"
        case .control: "Control"
        }
    }

    var carbonFlag: UInt32 {
        switch self {
        case .command: UInt32(cmdKey)
        case .shift: UInt32(shiftKey)
        case .option: UInt32(optionKey)
        case .control: UInt32(controlKey)
        }
    }
}

enum HotKeyConfigError: LocalizedError {
    case missingModifier
    case unsupportedKey(String)

    var errorDescription: String? {
        switch self {
        case .missingModifier:
            "至少选择一个修饰键"
        case let .unsupportedKey(key):
            "不支持的主键：\(key.isEmpty ? "空" : key)"
        }
    }
}

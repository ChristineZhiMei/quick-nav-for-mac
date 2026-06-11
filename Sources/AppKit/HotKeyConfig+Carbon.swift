/**
 @SkillID QuickNavCarbonHotKeyBridge
 @Description 将 Core 中的快捷键值对象转换为 Carbon 全局快捷键 API 需要的数字参数。
 @Capabilities 提供 keyCode 映射、modifier flag 映射，隔离 Carbon 依赖到 AppKit 模块。
 @LastUpdatedBy Codex
 */
import Carbon
import QuickNavCore

extension HotKeyConfig {
    /// Carbon API 使用键盘扫描码而不是字符；这里相当于把前端表单值转换成系统 SDK 参数。
    var carbonKeyCode: UInt32? {
        Self.keyCodeMap[normalizedKey]
    }

    /// Carbon modifier 是按位组合的 flags，类似把多个布尔开关压成一个整数。
    var carbonModifiers: UInt32 {
        modifiers.reduce(UInt32(0)) { result, modifier in
            result | modifier.carbonFlag
        }
    }

    private static var keyCodeMap: [String: UInt32] {
        [
            "A": UInt32(kVK_ANSI_A), "B": UInt32(kVK_ANSI_B), "C": UInt32(kVK_ANSI_C),
            "D": UInt32(kVK_ANSI_D), "E": UInt32(kVK_ANSI_E), "F": UInt32(kVK_ANSI_F),
            "G": UInt32(kVK_ANSI_G), "H": UInt32(kVK_ANSI_H), "I": UInt32(kVK_ANSI_I),
            "J": UInt32(kVK_ANSI_J), "K": UInt32(kVK_ANSI_K), "L": UInt32(kVK_ANSI_L),
            "M": UInt32(kVK_ANSI_M), "N": UInt32(kVK_ANSI_N), "O": UInt32(kVK_ANSI_O),
            "P": UInt32(kVK_ANSI_P), "Q": UInt32(kVK_ANSI_Q), "R": UInt32(kVK_ANSI_R),
            "S": UInt32(kVK_ANSI_S), "T": UInt32(kVK_ANSI_T), "U": UInt32(kVK_ANSI_U),
            "V": UInt32(kVK_ANSI_V), "W": UInt32(kVK_ANSI_W), "X": UInt32(kVK_ANSI_X),
            "Y": UInt32(kVK_ANSI_Y), "Z": UInt32(kVK_ANSI_Z), "0": UInt32(kVK_ANSI_0),
            "1": UInt32(kVK_ANSI_1), "2": UInt32(kVK_ANSI_2), "3": UInt32(kVK_ANSI_3),
            "4": UInt32(kVK_ANSI_4), "5": UInt32(kVK_ANSI_5), "6": UInt32(kVK_ANSI_6),
            "7": UInt32(kVK_ANSI_7), "8": UInt32(kVK_ANSI_8), "9": UInt32(kVK_ANSI_9)
        ]
    }
}

private extension HotKeyModifier {
    var carbonFlag: UInt32 {
        switch self {
        case .command: UInt32(cmdKey)
        case .shift: UInt32(shiftKey)
        case .option: UInt32(optionKey)
        case .control: UInt32(controlKey)
        }
    }
}

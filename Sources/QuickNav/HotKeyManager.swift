/**
 @SkillID QuickNavGlobalHotKey
 @Description 使用 Carbon 注册用户配置的全局快捷键，并把按下/松开事件转发回主线程驱动导航生命周期。
 @Capabilities 注册 kEventHotKeyPressed/kEventHotKeyReleased、桥接 Carbon 回调与 Swift 闭包、注销系统快捷键资源。
 @LastUpdatedBy Codex
 */
import Carbon
import Foundation

// Carbon 注册或事件处理失败时抛出的轻量错误，供菜单栏展示 hotkey 不可用状态。
enum HotKeyError: LocalizedError {
    case registrationFailed(OSStatus)
    case eventHandlerFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .registrationFailed(let status):
            "RegisterEventHotKey failed with status \(status)"
        case .eventHandlerFailed(let status):
            "InstallEventHandler failed with status \(status)"
        }
    }
}

// Carbon 回调来自 C API，不受 Swift actor 管理；内部只把事件切回 MainActor，因此用 unchecked Sendable 包装。
final class HotKeyManager: @unchecked Sendable {
    // 快捷键按下：显示导航浮层。
    private let onPress: @MainActor @Sendable () -> Void

    // 快捷键松开：关闭导航浮层并恢复光标位置。
    private let onRelease: @MainActor @Sendable () -> Void

    // Carbon 注册返回的快捷键引用，用于应用退出时注销。
    private var hotKeyRef: EventHotKeyRef?

    // Carbon 事件处理器引用，用于应用退出时移除。
    private var eventHandlerRef: EventHandlerRef?

    // 当前已注册快捷键，用于状态展示和调试。
    private(set) var currentConfig: HotKeyConfig?

    init(
        onPress: @escaping @MainActor @Sendable () -> Void,
        onRelease: @escaping @MainActor @Sendable () -> Void
    ) {
        self.onPress = onPress
        self.onRelease = onRelease
    }

    /**
     @name register
     @description 注册指定快捷键，并同时监听 pressed/released 两种事件，支撑“按住显示、松开关闭”的交互。
     @link AppDelegate.applicationDidFinishLaunching
     */
    func register(_ config: HotKeyConfig) throws {
        let validatedConfig = try config.validated()
        unregister()

        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else { return noErr }

                // Carbon C 回调无法直接捕获 Swift 对象，这里通过 userData 取回 HotKeyManager。
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

                // 校验事件确实属于 QuickNav 注册的快捷键，避免误处理其他 Carbon hotkey。
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr, hotKeyID.id == HotKeyManager.hotKeyID.id else {
                    return status
                }

                let eventKind = GetEventKind(event)

                // 所有 UI 行为都回到 MainActor，避免从 Carbon 回调线程直接操作 AppKit/SwiftUI。
                Task { @MainActor in
                    if eventKind == UInt32(kEventHotKeyPressed) {
                        manager.onPress()
                    } else if eventKind == UInt32(kEventHotKeyReleased) {
                        manager.onRelease()
                    }
                }
                return noErr
            },
            eventTypes.count,
            &eventTypes,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard handlerStatus == noErr else {
            throw HotKeyError.eventHandlerFailed(handlerStatus)
        }

        let registerStatus = RegisterEventHotKey(
            validatedConfig.carbonKeyCode ?? UInt32(kVK_ANSI_D),
            validatedConfig.carbonModifiers,
            HotKeyManager.hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registerStatus == noErr else {
            unregister()
            throw HotKeyError.registrationFailed(registerStatus)
        }

        currentConfig = validatedConfig
    }

    /**
     @name unregister
     @description 注销快捷键和事件处理器，保证重复启动或应用退出时不会残留系统资源。
     */
    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }

        currentConfig = nil
    }

    private static let hotKeyID = EventHotKeyID(signature: fourCharCode("QNav"), id: 1)
}

/**
 @name fourCharCode
 @description 将 4 字符字符串转成 Carbon API 需要的 OSType 签名。
 */
private func fourCharCode(_ string: String) -> OSType {
    string.utf8.reduce(0) { result, character in
        (result << 8) + OSType(character)
    }
}

/**
 @SkillID QuickNavSettingsView
 @Description SwiftUI 设置界面，按 Pencil 中 Visible settings panel 的结构实现深色侧边栏和可操作设置项。
 @Capabilities 切换 General/Menu/Actions/Permissions/Advanced 页面、启用禁用 QuickNav、调节菜单几何参数、打开配置文件、重载配置、跳转辅助功能设置。
 @LastUpdatedBy Codex
 */
import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState

    let reloadConfig: () -> Void
    let openConfigFile: () -> Void
    let openConfigFolder: () -> Void
    let openAccessibilitySettings: () -> Void
    let applyHotKey: (HotKeyConfig) -> Void

    @State private var selectedSection: SettingsSection = .general

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            content
        }
        .frame(width: 526, height: 590)
        .background(SettingsTokens.surface)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(SettingsSection.allCases) { section in
                Button {
                    selectedSection = section
                } label: {
                    SettingsNavRow(section: section, isActive: section == selectedSection)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }

            Spacer()
        }
        .padding(.top, 64)
        .padding(.horizontal, 17)
        .padding(.bottom, 22)
        .frame(width: 160)
        .frame(maxHeight: .infinity)
        .background(SettingsTokens.sidebar)
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            switch selectedSection {
            case .general:
                generalSection
            case .menu:
                menuSection
            case .actions:
                actionsSection
            case .permissions:
                permissionsSection
            case .advanced:
                advancedSection
            }

            Spacer()
        }
        .padding(.top, 72)
        .padding(.horizontal, 36)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SettingsTokens.surface)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedSection.title)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(SettingsTokens.textPrimary)

            Text(selectedSection.description)
                .font(.system(size: 13))
                .lineSpacing(3)
                .foregroundStyle(SettingsTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var generalSection: some View {
        VStack(spacing: 14) {
            HotKeyRecorderRow(
                currentText: appState.hotKeyDisplay,
                isRecording: $appState.isRecordingHotKey,
                apply: applyHotKey
            )
            ValueRow(title: "快捷键状态", value: appState.isHotKeyAvailable ? "已注册" : "不可用", systemImage: appState.isHotKeyAvailable ? "checkmark.circle" : "exclamationmark.triangle")

            ButtonRow(title: "重载配置", subtitle: "重新读取本地配置文件。", systemImage: "arrow.clockwise", action: reloadConfig)
        }
    }

    private var menuSection: some View {
        VStack(spacing: 16) {
            SliderRow(title: "菜单半径", value: $appState.menuRadius, range: 112...168, step: 1, suffix: "px")
            SliderRow(title: "中心死区", value: $appState.deadZoneRadius, range: 24...56, step: 1, suffix: "px")
            SliderRow(title: "图标尺寸", value: $appState.itemSize, range: 44...60, step: 1, suffix: "px")

            ButtonRow(title: "恢复默认布局", subtitle: "恢复当前设计稿中的默认几何参数。", systemImage: "arrow.counterclockwise") {
                appState.menuRadius = DesignTokens.Menu.radius
                appState.deadZoneRadius = DesignTokens.Menu.deadZoneRadius
                appState.itemSize = DesignTokens.Menu.itemSize
                appState.statusMessage = "已恢复菜单布局"
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 10) {
            ForEach(RadialMenuView.items) { item in
                ActionItemRow(item: item)
            }
        }
    }

    private var permissionsSection: some View {
        VStack(spacing: 14) {
            ValueRow(title: "全局快捷键", value: appState.isHotKeyAvailable ? "就绪" : "不可用", systemImage: "keyboard.badge.eye")
            ValueRow(title: "指针跟踪", value: "本机会话", systemImage: "cursorarrow.motionlines")
            ButtonRow(title: "打开辅助功能设置", subtitle: "如果全局输入不稳定，可在这里授权。", systemImage: "shield.checkerboard", action: openAccessibilitySettings)
        }
    }

    private var advancedSection: some View {
        VStack(spacing: 14) {
            ButtonRow(title: "打开配置文件", subtitle: "~/Library/Application Support/QuickNav/config.json", systemImage: "doc.text", action: openConfigFile)
            ButtonRow(title: "打开配置目录", subtitle: "Application Support/QuickNav", systemImage: "folder", action: openConfigFolder)
            ButtonRow(title: "重载配置", subtitle: "检查配置文件是否可以正常读取。", systemImage: "arrow.clockwise", action: reloadConfig)
        }
    }

}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case menu
    case actions
    case permissions
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "通用"
        case .menu: "菜单"
        case .actions: "动作"
        case .permissions: "权限"
        case .advanced: "高级"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .menu: "circle.dotted"
        case .actions: "bolt"
        case .permissions: "shield.checkerboard"
        case .advanced: "slider.horizontal.3"
        }
    }

    var description: String {
        switch self {
        case .general: "控制 QuickNav 是否响应全局快捷键，并查看当前启用状态。"
        case .menu: "调整隐藏光标方向选择界面使用的径向菜单参数。"
        case .actions: "查看当前径向菜单项，以及每一项对应的内置动作。"
        case .permissions: "检查系统能力，并在需要输入权限时跳转到 macOS 设置。"
        case .advanced: "打开或重载当前原型使用的本地配置文件。"
        }
    }
}

private struct SettingsNavRow: View {
    let section: SettingsSection
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: section.systemImage)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 18)

            Text(section.title)
                .font(.system(size: 12, weight: isActive ? .medium : .regular))
        }
        .foregroundStyle(isActive ? SettingsTokens.textPrimary : SettingsTokens.textSecondary)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActive ? Color.white.opacity(0.10) : Color.clear)
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ValueRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SettingsTokens.textSecondary)
                .frame(width: 18)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SettingsTokens.textPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(SettingsTokens.textPrimary)
        }
        .settingsRowBackground()
    }
}

private struct HotKeyRecorderRow: View {
    let currentText: String
    @Binding var isRecording: Bool
    let apply: (HotKeyConfig) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("快捷键", systemImage: "keyboard")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SettingsTokens.textPrimary)

                Spacer()

                Text(isRecording ? "正在录入..." : currentText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(isRecording ? SettingsTokens.accent : SettingsTokens.textSecondary)
            }

            Text(isRecording ? "按下新的组合键，或按 Esc 取消。" : "点击此处后，直接按下新的快捷键组合。支持 A-Z、0-9。")
                .font(.system(size: 11))
                .foregroundStyle(SettingsTokens.textMuted)
        }
        .settingsRowBackground(height: 72)
        .overlay(
            HotKeyCaptureView(
                isRecording: $isRecording,
                onCommit: { config in
                    isRecording = false
                    apply(config)
                },
                onCancel: {
                    isRecording = false
                }
            )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            isRecording = true
        }
        .onDisappear {
            isRecording = false
        }
    }
}

private struct HotKeyCaptureView: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onCommit: (HotKeyConfig) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(isRecording: $isRecording, onCommit: onCommit, onCancel: onCancel)
    }

    func makeNSView(context: Context) -> CaptureNSView {
        let view = CaptureNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: CaptureNSView, context: Context) {
        context.coordinator.isRecording = $isRecording
        context.coordinator.onCommit = onCommit
        context.coordinator.onCancel = onCancel
        nsView.coordinator = context.coordinator

        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    final class Coordinator {
        var isRecording: Binding<Bool>
        var onCommit: (HotKeyConfig) -> Void
        var onCancel: () -> Void

        init(isRecording: Binding<Bool>, onCommit: @escaping (HotKeyConfig) -> Void, onCancel: @escaping () -> Void) {
            self.isRecording = isRecording
            self.onCommit = onCommit
            self.onCancel = onCancel
        }

        @MainActor
        func beginRecording(from view: NSView) {
            isRecording.wrappedValue = true
            view.window?.makeFirstResponder(view)
        }

        func handleKeyDown(_ event: NSEvent) {
            if event.keyCode == 53 {
                onCancel()
                return
            }

            guard let key = event.charactersIgnoringModifiers?.uppercased().first.map(String.init) else {
                return
            }

            let modifiers = modifiers(from: event.modifierFlags)
            onCommit(HotKeyConfig(key: key, modifiers: modifiers))
        }

        private func modifiers(from flags: NSEvent.ModifierFlags) -> [HotKeyModifier] {
            var modifiers: [HotKeyModifier] = []
            if flags.contains(.command) {
                modifiers.append(.command)
            }
            if flags.contains(.shift) {
                modifiers.append(.shift)
            }
            if flags.contains(.option) {
                modifiers.append(.option)
            }
            if flags.contains(.control) {
                modifiers.append(.control)
            }
            return HotKeyModifier.displayOrder.filter { modifiers.contains($0) }
        }
    }

    final class CaptureNSView: NSView {
        weak var coordinator: Coordinator?

        override var acceptsFirstResponder: Bool { true }

        override func mouseDown(with event: NSEvent) {
            coordinator?.beginRecording(from: self)
        }

        override func keyDown(with event: NSEvent) {
            coordinator?.handleKeyDown(event)
        }
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let step: CGFloat
    let suffix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SettingsTokens.textPrimary)

                Spacer()

                Text("\(Int(value)) \(suffix)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(SettingsTokens.textSecondary)
            }

            Slider(value: $value, in: range, step: step)
                .tint(SettingsTokens.accent)
        }
        .settingsRowBackground(height: 64)
    }
}

private struct ButtonRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SettingsTokens.textSecondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SettingsTokens.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(SettingsTokens.textMuted)
                        .lineLimit(1)
                }

                Spacer()
            }
            .settingsRowBackground()
        }
        .buttonStyle(.plain)
    }
}

private struct ActionItemRow: View {
    let item: RadialMenuItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.systemImage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SettingsTokens.textSecondary)
                .frame(width: 18)

            Text(item.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SettingsTokens.textPrimary)

            Spacer()

            Text(actionLabel)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(SettingsTokens.textSecondary)
                .lineLimit(1)
        }
        .settingsRowBackground(height: 38)
    }

    private var actionLabel: String {
        switch item.action {
        case .settings:
            "设置"
        case .openApp:
            "应用"
        case .openFolder:
            "目录"
        case .openURL:
            "网址"
        case .reloadConfig:
            "重载"
        }
    }
}

private extension View {
    func settingsRowBackground(height: CGFloat = 44) -> some View {
        self
            .padding(.horizontal, 14)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private enum SettingsTokens {
    static let surface = Color(red: 0.067, green: 0.067, blue: 0.075)
    static let sidebar = Color(red: 0.051, green: 0.051, blue: 0.055)
    static let textPrimary = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let textSecondary = Color(red: 0.63, green: 0.63, blue: 0.67)
    static let textMuted = Color(red: 0.44, green: 0.44, blue: 0.48)
    static let accent = Color(red: 1.0, green: 0.27, blue: 0.24)
    static let success = Color(red: 0.19, green: 0.82, blue: 0.35)
    static let warning = Color(red: 0.95, green: 0.66, blue: 0.20)
}

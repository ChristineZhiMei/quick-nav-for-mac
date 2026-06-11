/**
 @SkillID QuickNavSettingsView
 @Description SwiftUI 设置界面，按 Pencil 中 Visible settings panel 的结构实现深色侧边栏和可操作设置项。
 @Capabilities 切换 General/Menu/Actions/Permissions/Advanced 页面、启用禁用 QuickNav、调节菜单几何参数、打开配置文件、重载配置、跳转辅助功能设置。
 @LastUpdatedBy Codex
 */
import AppKit
import QuickNavCore
import SwiftUI

struct SettingsView: View {
    private enum Layout {
        static let minWindowWidth: CGFloat = 556
        static let minWindowHeight: CGFloat = 590
        static let sidebarWidth: CGFloat = 190
    }

    @ObservedObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    let reloadConfig: () -> Void
    let openConfigFile: () -> Void
    let openConfigFolder: () -> Void
    let openAccessibilitySettings: () -> Void
    let applyHotKey: (HotKeyConfig) -> Void
    let applyTheme: (ThemeConfig) -> Void

    @State private var selectedSection: SettingsSection = .general
    private var palette: ThemePalette { appState.themePalette(for: colorScheme) }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            content
        }
        .frame(
            minWidth: Layout.minWindowWidth,
            maxWidth: .infinity,
            minHeight: Layout.minWindowHeight,
            maxHeight: .infinity
        )
        .background(palette.surface)
        .background(WindowAppearanceSync(mode: appState.themeConfig.mode))
        .preferredColorScheme(appState.themeConfig.mode.preferredColorScheme)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(SettingsSection.allCases) { section in
                SettingsNavRow(section: section, isActive: section == selectedSection, palette: palette)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSection = section
                }
            }

            Spacer()
        }
        .padding(.top, 64)
        .padding(.horizontal, 17)
        .padding(.bottom, 22)
        .frame(width: Layout.sidebarWidth)
        .frame(maxHeight: .infinity)
        .background(palette.sidebar)
    }

    @ViewBuilder
    private var content: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 22) {
                header

                switch selectedSection {
                case .general:
                    generalSection
                case .menu:
                    menuSection
                case .theme:
                    themeSection
                case .actions:
                    actionsSection
                case .advanced:
                    advancedSection
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 72)
            .padding(.horizontal, 36)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(palette.surface)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedSection.title)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(palette.textPrimary)

            Text(selectedSection.description)
                .font(.system(size: 13))
                .lineSpacing(3)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var generalSection: some View {
        VStack(spacing: 14) {
            HotKeyRecorderRow(
                currentText: appState.hotKeyDisplay,
                isRecording: $appState.isRecordingHotKey,
                palette: palette,
                apply: applyHotKey
            )
        }
    }

    private var menuSection: some View {
        VStack(spacing: 16) {
            SliderRow(title: "样式半径", value: $appState.menuRadius, range: 112...168, step: 1, suffix: "px", palette: palette)
            SliderRow(title: "中心缓冲区", value: $appState.deadZoneRadius, range: 24...56, step: 1, suffix: "px", palette: palette)
            SliderRow(title: "图标尺寸", value: $appState.itemSize, range: 44...60, step: 1, suffix: "px", palette: palette)
            ToggleRow(title: "显示背景扩散", subtitle: "控制导航中心主题色扩散背景是否显示。", isOn: $appState.isBackgroundVisible, palette: palette)
            SliderRow(title: "背景半径", value: $appState.backgroundRadius, range: 120...260, step: 1, suffix: "px", palette: palette)
                .disabled(!appState.isBackgroundVisible)
                .opacity(appState.isBackgroundVisible ? 1 : 0.45)
            OpacitySliderRow(title: "背景透明度", value: $appState.backgroundOpacity, range: 0.06...0.36, step: 0.01, palette: palette)
                .disabled(!appState.isBackgroundVisible)
                .opacity(appState.isBackgroundVisible ? 1 : 0.45)

            ButtonRow(title: "恢复默认布局", subtitle: "恢复当前设计稿中的默认几何参数。", systemImage: "arrow.counterclockwise", palette: palette) {
                appState.menuRadius = CGFloat(DesignTokens.Menu.radius)
                appState.deadZoneRadius = CGFloat(DesignTokens.Menu.deadZoneRadius)
                appState.itemSize = CGFloat(DesignTokens.Menu.itemSize)
                appState.isBackgroundVisible = DesignTokens.Menu.isBackgroundVisible
                appState.backgroundRadius = CGFloat(DesignTokens.Menu.backgroundRadius)
                appState.backgroundOpacity = CGFloat(DesignTokens.Menu.backgroundOpacity)
                appState.statusMessage = "已恢复样式布局"
            }
        }
    }

    private var themeSection: some View {
        VStack(spacing: 14) {
            Picker("外观模式", selection: themeBinding(\.mode)) {
                ForEach(ThemeMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(palette.accent)

            PresetPickerGroup(
                title: "明色主题",
                appearance: .light,
                selection: themeBinding(\.lightPreset),
                customAccent: themeBinding(\.customLightAccent),
                palette: palette
            )

            PresetPickerGroup(
                title: "暗色主题",
                appearance: .dark,
                selection: themeBinding(\.darkPreset),
                customAccent: themeBinding(\.customDarkAccent),
                palette: palette
            )

            ThemePreview(palette: palette)
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 10) {
            ForEach(appState.menuConfig.items) { item in
                ActionItemRow(item: item, palette: palette)
            }
        }
    }

    private var advancedSection: some View {
        VStack(spacing: 14) {
            ButtonRow(title: "打开配置文件", subtitle: "~/Library/Application Support/QuickNav/config.json", systemImage: "doc.text", palette: palette, action: openConfigFile)
            ButtonRow(title: "打开配置目录", subtitle: "Application Support/QuickNav", systemImage: "folder", palette: palette, action: openConfigFolder)
            ButtonRow(title: "重载配置", subtitle: "检查配置文件是否可以正常读取。", systemImage: "arrow.clockwise", palette: palette, action: reloadConfig)
            ButtonRow(title: "打开辅助功能设置", subtitle: "如果全局输入不稳定，可在这里授权。", systemImage: "shield.checkerboard", palette: palette, action: openAccessibilitySettings)
        }
    }

    private func themeBinding<Value>(_ keyPath: WritableKeyPath<ThemeConfig, Value>) -> Binding<Value> {
        Binding(
            get: { appState.themeConfig[keyPath: keyPath] },
            set: { newValue in
                var nextConfig = appState.themeConfig
                nextConfig[keyPath: keyPath] = newValue
                applyTheme(nextConfig)
            }
        )
    }

}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case menu
    case theme
    case actions
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "通用"
        case .menu: "样式"
        case .theme: "主题"
        case .actions: "动作"
        case .advanced: "高级"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .menu: "circle.dotted"
        case .theme: "paintpalette"
        case .actions: "bolt"
        case .advanced: "slider.horizontal.3"
        }
    }

    var description: String {
        switch self {
        case .general: "控制 QuickNav 是否响应全局快捷键，并查看当前启用状态。"
        case .menu: "调整隐藏光标方向选择界面使用的样式参数。"
        case .theme: "配置明色、暗色和跟随系统时使用的主题色。"
        case .actions: "查看当前径向菜单项，以及每一项对应的内置动作。"
        case .advanced: "打开或重载当前原型使用的本地配置文件。"
        }
    }
}

private struct SettingsNavRow: View {
    let section: SettingsSection
    let isActive: Bool
    let palette: ThemePalette

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: section.systemImage)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 18)

            Text(section.title)
                .font(.system(size: 12, weight: isActive ? .medium : .regular))
        }
        .foregroundStyle(isActive ? palette.textPrimary : palette.textSecondary)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActive ? palette.accent.opacity(0.16) : Color.clear)
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ValueRow: View {
    let title: String
    let value: String
    let systemImage: String
    let palette: ThemePalette

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(palette.textSecondary)
                .frame(width: 18)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.textPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(palette.textPrimary)
        }
        .settingsRowBackground(palette: palette)
    }
}

private struct HotKeyRecorderRow: View {
    let currentText: String
    @Binding var isRecording: Bool
    let palette: ThemePalette
    let apply: (HotKeyConfig) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("快捷键", systemImage: "keyboard")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.textPrimary)

                Spacer()

                Text(isRecording ? "正在录入..." : currentText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(isRecording ? palette.accent : palette.textSecondary)
            }

            Text(isRecording ? "按下新的组合键，或按 Esc 取消。" : "点击此处后，直接按下新的快捷键组合。支持 A-Z、0-9。")
                .font(.system(size: 11))
                .foregroundStyle(palette.textMuted)
        }
        .settingsRowBackground(height: 72, palette: palette)
        .overlay(
            Group {
                if isRecording {
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
                }
            }
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
            guard isRecording.wrappedValue else { return }

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

private struct PresetPickerGroup: View {
    let title: String
    let appearance: ThemeAppearance
    @Binding var selection: ThemePresetID
    @Binding var customAccent: String
    let palette: ThemePalette

    // SwiftUI 没有 CSS flex-wrap 这个属性；LazyVGrid + adaptive GridItem 是最接近的写法。
    // minimum 类似 flex item 的最小宽度，可用空间变大时系统会自动增加列数，变小时自动换行。
    private let columns = [GridItem(.adaptive(minimum: 58, maximum: 76), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.textPrimary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(ThemePresetID.allCases) { preset in
                    PresetSwatch(
                        preset: preset,
                        appearance: appearance,
                        customAccent: customAccent,
                        isSelected: selection == preset,
                        palette: palette
                    ) {
                        selection = preset
                    }
                }
            }

            if selection == .custom {
                ColorPicker("自定义主题色", selection: customColorBinding)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .settingsRowBackground(height: selection == .custom ? 154 : 124, palette: palette)
    }

    private var customColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: customAccent) },
            set: { customAccent = $0.hexString }
        )
    }
}

private struct PresetSwatch: View {
    let preset: ThemePresetID
    let appearance: ThemeAppearance
    let customAccent: String
    let isSelected: Bool
    let palette: ThemePalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Circle()
                    .fill(ThemePaletteFactory.accentPreview(for: preset, appearance: appearance, customHex: customAccent))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? palette.textPrimary : palette.border, lineWidth: isSelected ? 2 : 1)
                    )

                Text(preset.title)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? palette.textPrimary : palette.textMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

private struct ThemePreview: View {
    let palette: ThemePalette

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("主题预览")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)

                Text("文字、卡片、选中态")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(palette.accent)
                .frame(width: 42, height: 26)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(palette.accentText)
                )

            Circle()
                .fill(palette.accent)
                .shadow(color: palette.accentShadow, radius: 8)
                .frame(width: 16, height: 16)
        }
        .settingsRowBackground(height: 58, palette: palette)
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let step: CGFloat
    let suffix: String
    let palette: ThemePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.textPrimary)

                Spacer()

                Text("\(Int(value)) \(suffix)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(palette.textSecondary)
            }

            Slider(value: $value, in: range, step: step)
                .tint(palette.accent)
        }
        .settingsRowBackground(height: 64, palette: palette)
    }
}

private struct OpacitySliderRow: View {
    let title: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let step: CGFloat
    let palette: ThemePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.textPrimary)

                Spacer()

                Text("\(Int(round(value * 100)))%")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(palette.textSecondary)
            }

            // SwiftUI Slider 类似 HTML range input；这里把 0...1 的透明度显示为百分比，读起来更直观。
            Slider(value: $value, in: range, step: step)
                .tint(palette.accent)
        }
        .settingsRowBackground(height: 64, palette: palette)
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let palette: ThemePalette

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.textPrimary)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(palette.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            // Toggle 使用 macOS 原生 switch 风格；可以理解成前端里的受控 checkbox。
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(palette.accent)
                .labelsHidden()
        }
        .settingsRowBackground(height: 58, palette: palette)
    }
}

private struct ButtonRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let palette: ThemePalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(palette.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(palette.textMuted)
                        .lineLimit(1)
                }

                Spacer()
            }
            .settingsRowBackground(palette: palette)
        }
        .buttonStyle(.plain)
    }
}

private struct ActionItemRow: View {
    let item: NavigationItem
    let palette: ThemePalette

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.systemImage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(palette.textSecondary)
                .frame(width: 18)

            Text(item.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.textPrimary)

            Spacer()

            Text(actionLabel)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(palette.textSecondary)
                .lineLimit(1)
        }
        .settingsRowBackground(height: 38, palette: palette)
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
    func settingsRowBackground(height: CGFloat = 44, palette: ThemePalette) -> some View {
        self
            .padding(.horizontal, 14)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background(palette.row)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct WindowAppearanceSync: NSViewRepresentable {
    let mode: ThemeMode

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.appearance = mode.nsAppearance
        }
    }
}

private extension Color {
    var hexString: String {
        let nsColor = NSColor(self)
        guard let color = nsColor.usingColorSpace(.sRGB) else {
            return "#FF453A"
        }

        let red = Int(round(color.redComponent * 255))
        let green = Int(round(color.greenComponent * 255))
        let blue = Int(round(color.blueComponent * 255))

        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

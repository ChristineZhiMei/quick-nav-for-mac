/**
 @SkillID QuickNavRadialSurface
 @Description SwiftUI 径向导航界面，展示 8 个方向项、中心缓冲区和隐藏光标的红色替代圆点。
 @Capabilities 按状态高亮命中项、提供图标视觉坐标给 AppKit 命中算法、显示中心缓冲区、渲染红点光标。
 @LastUpdatedBy Codex
 */
import SwiftUI

// 径向菜单项模型。每个项都带一个基础动作，执行逻辑交给 ActionExecutor。
struct RadialMenuItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let action: RadialMenuAction
}

enum RadialMenuAction {
    case settings
    case openApp(bundleIdentifier: String, fallbackPath: String?)
    case openFolder(String)
    case openURL(String)
    case reloadConfig
}

struct RadialMenuView: View {
    @Environment(\.colorScheme) private var colorScheme

    static let items: [RadialMenuItem] = [
        .init(id: "menu", title: "菜单", systemImage: "line.3.horizontal", action: .settings),
        .init(id: "vscode", title: "VS Code", systemImage: "chevron.left.forwardslash.chevron.right", action: .openApp(bundleIdentifier: "com.microsoft.VSCode", fallbackPath: "/Applications/Visual Studio Code.app")),
        .init(id: "terminal", title: "Terminal", systemImage: "terminal", action: .openApp(bundleIdentifier: "com.apple.Terminal", fallbackPath: "/System/Applications/Utilities/Terminal.app")),
        .init(id: "projects", title: "项目", systemImage: "folder", action: .openFolder("~/Documents/code")),
        .init(id: "docs", title: "文档", systemImage: "doc.text", action: .openFolder("~/Documents")),
        .init(id: "figma", title: "Figma", systemImage: "square.grid.2x2", action: .openApp(bundleIdentifier: "com.figma.Desktop", fallbackPath: nil)),
        .init(id: "browser", title: "浏览器", systemImage: "safari", action: .openURL("https://www.google.com")),
        .init(id: "reload", title: "重载", systemImage: "arrow.clockwise", action: .reloadConfig)
    ]

    /**
     @name visualPosition
     @description 返回菜单项相对中心的 SwiftUI 坐标。y 轴向下为正，因此这里对 sin 取反。
     @link RadialWindowController.selectedItemID
     */
    static func visualPosition(for index: Int, total: Int = items.count, radius: CGFloat = DesignTokens.Menu.radius) -> CGPoint {
        let degrees = Double(index) * 360 / Double(total)
        let radians = degrees * .pi / 180

        return CGPoint(
            x: cos(radians) * radius,
            y: -sin(radians) * radius
        )
    }

    // 来自 AppKit 控制器的共享状态，决定高亮项和红点位置。
    @ObservedObject var state: RadialMenuState
    @ObservedObject var appState: AppState

    private var palette: ThemePalette {
        appState.themePalette(for: colorScheme)
    }

    var body: some View {
        ZStack {
            if appState.isBackgroundVisible {
                RadialBlurBackground(
                    palette: palette,
                    radius: appState.backgroundRadius,
                    opacity: appState.backgroundOpacity
                )
            }

            CancelZoneView(radius: appState.deadZoneRadius, palette: palette)

            ForEach(Array(Self.items.enumerated()), id: \.element.id) { index, item in
                radialItem(item, index: index)
            }

            HiddenCursorDot(palette: palette)
                .offset(state.cursorOffset)
                .animation(.easeOut(duration: 0.035), value: state.cursorOffset)
        }
        .frame(width: 520, height: 520)
        .background(Color.clear)
    }

    /**
     @name radialItem
     @description 渲染单个方向项。只有红点进入图标命中区时才进入 active 状态并轻微放大。
     */
    private func radialItem(_ item: RadialMenuItem, index: Int) -> some View {
        let position = Self.visualPosition(for: index, radius: appState.menuRadius)
        let isActive = item.id == state.selectedItemID

        return VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.item, style: .continuous)
                    .fill(isActive ? palette.accent : palette.row)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.item, style: .continuous)
                            .stroke(isActive ? palette.accent.opacity(0.35) : palette.border, lineWidth: 1)
                    )
                    .shadow(
                        color: isActive ? palette.accentShadow : .black.opacity(0.25),
                        radius: isActive ? 16 : 8,
                        y: isActive ? 8 : 4
                    )

                Image(systemName: item.systemImage)
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(isActive ? palette.accentText : palette.textPrimary)
            }
            .frame(width: appState.itemSize, height: appState.itemSize)

            Text(item.title)
                .font(.system(size: 11, weight: isActive ? .medium : .regular))
                .foregroundStyle(isActive ? palette.textPrimary : palette.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 78, height: 82)
        .scaleEffect(isActive ? 1.12 : 1)
        .animation(.easeOut(duration: DesignTokens.Motion.selectionDuration), value: state.selectedItemID)
        .offset(x: position.x, y: position.y)
    }
}

private struct RadialBlurBackground: View {
    let palette: ThemePalette
    let radius: CGFloat
    let opacity: CGFloat

    // 这层相当于前端里的 radial-gradient。这里只保留扩散色晕，不使用 Material 实体圆，
    // 避免视觉上出现一块可识别的灰色圆形背景。
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        palette.accent.opacity(opacity),
                        palette.accent.opacity(opacity * 0.50),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 18,
                    endRadius: radius
                )
            )
            .frame(width: radius * 2, height: radius * 2)
            .blur(radius: max(8, radius * 0.09))
        .allowsHitTesting(false)
    }
}

private struct CancelZoneView: View {
    let radius: CGFloat
    let palette: ThemePalette

    // 中心缓冲区用于提示“移动距离太短时不选择任何应用”，不再负责打开状态菜单。
    var body: some View {
        ZStack {
            Circle()
                .fill(palette.panel.opacity(0.70))
                .overlay(Circle().stroke(palette.border, lineWidth: 1))
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .fill(palette.textSecondary.opacity(0.65))
                .frame(width: 7, height: 7)
        }
        .allowsHitTesting(false)
    }
}

private struct HiddenCursorDot: View {
    let palette: ThemePalette

    // 红点是隐藏系统光标的可视替代物，所有事件仍由 AppKit 鼠标监听处理。
    var body: some View {
        Circle()
            .fill(palette.accent)
            .overlay(
                Circle()
                    .stroke(palette.accentText.opacity(0.65), lineWidth: 1)
            )
            .shadow(color: palette.accent.opacity(0.55), radius: 10)
            .frame(width: 14, height: 14)
            .allowsHitTesting(false)
    }
}

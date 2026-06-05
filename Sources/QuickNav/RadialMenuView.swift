/**
 @SkillID QuickNavRadialSurface
 @Description SwiftUI 径向导航界面，展示 8 个方向项、中心死区和隐藏光标的红色替代圆点。
 @Capabilities 按状态高亮命中项、提供图标视觉坐标给 AppKit 命中算法、显示中心死区、渲染红点光标。
 @LastUpdatedBy Codex
 */
import SwiftUI

// 径向菜单项模型。首版只作为占位，不承载真实 URL/app/command 动作。
struct RadialMenuItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
}

struct RadialMenuView: View {
    static let items: [RadialMenuItem] = [
        .init(id: "menu", title: "Menu", systemImage: "line.3.horizontal"),
        .init(id: "vscode", title: "VS Code", systemImage: "chevron.left.forwardslash.chevron.right"),
        .init(id: "terminal", title: "Terminal", systemImage: "terminal"),
        .init(id: "projects", title: "Projects", systemImage: "folder"),
        .init(id: "docs", title: "Docs", systemImage: "doc.text"),
        .init(id: "figma", title: "Figma", systemImage: "square.grid.2x2"),
        .init(id: "browser", title: "Browser", systemImage: "safari"),
        .init(id: "reload", title: "Reload", systemImage: "arrow.clockwise")
    ]

    /**
     @name visualPosition
     @description 返回菜单项相对中心的 SwiftUI 坐标。y 轴向下为正，因此这里对 sin 取反。
     @link RadialWindowController.selectedItemID
     */
    static func visualPosition(for index: Int, total: Int = items.count) -> CGPoint {
        let degrees = Double(index) * 360 / Double(total)
        let radians = degrees * .pi / 180

        return CGPoint(
            x: cos(radians) * DesignTokens.Menu.radius,
            y: -sin(radians) * DesignTokens.Menu.radius
        )
    }

    // 来自 AppKit 控制器的共享状态，决定高亮项和红点位置。
    @ObservedObject var state: RadialMenuState

    var body: some View {
        ZStack {
            CancelZoneView()

            ForEach(Array(Self.items.enumerated()), id: \.element.id) { index, item in
                radialItem(item, index: index)
            }

            HiddenCursorDot()
                .offset(state.cursorOffset)
                .animation(.easeOut(duration: 0.035), value: state.cursorOffset)
        }
        .frame(width: 460, height: 460)
        .background(Color.clear)
    }

    /**
     @name radialItem
     @description 渲染单个方向项。只有红点进入图标命中区时才进入 active 状态并轻微放大。
     */
    private func radialItem(_ item: RadialMenuItem, index: Int) -> some View {
        let position = Self.visualPosition(for: index)
        let isActive = item.id == state.selectedItemID

        return VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.item, style: .continuous)
                    .fill(isActive ? DesignTokens.Color.accent : DesignTokens.Color.itemBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.item, style: .continuous)
                            .stroke(Color.white.opacity(isActive ? 0.24 : 0.08), lineWidth: 1)
                    )
                    .shadow(
                        color: isActive ? DesignTokens.Color.accent.opacity(0.35) : .black.opacity(0.25),
                        radius: isActive ? 16 : 8,
                        y: isActive ? 8 : 4
                    )

                Image(systemName: item.systemImage)
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(DesignTokens.Color.textPrimary)
            }
            .frame(width: DesignTokens.Menu.itemSize, height: DesignTokens.Menu.itemSize)

            Text(item.title)
                .font(.system(size: 11, weight: isActive ? .medium : .regular))
                .foregroundStyle(isActive ? DesignTokens.Color.textPrimary : DesignTokens.Color.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 78, height: 82)
        .scaleEffect(isActive ? 1.12 : 1)
        .animation(.easeOut(duration: DesignTokens.Motion.selectionDuration), value: state.selectedItemID)
        .offset(x: position.x, y: position.y)
    }
}

private struct CancelZoneView: View {
    // 中心区域仅作视觉死区提示，不再负责打开状态菜单。
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.07))
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                .frame(width: DesignTokens.Menu.deadZoneRadius * 2, height: DesignTokens.Menu.deadZoneRadius * 2)

            Circle()
                .fill(DesignTokens.Color.textSecondary.opacity(0.65))
                .frame(width: 7, height: 7)
        }
        .allowsHitTesting(false)
    }
}

private struct HiddenCursorDot: View {
    // 红点是隐藏系统光标的可视替代物，所有事件仍由 AppKit 鼠标监听处理。
    var body: some View {
        Circle()
            .fill(DesignTokens.Color.accent)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.65), lineWidth: 1)
            )
            .shadow(color: DesignTokens.Color.accent.opacity(0.55), radius: 10)
            .frame(width: 14, height: 14)
            .allowsHitTesting(false)
    }
}

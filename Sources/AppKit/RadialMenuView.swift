/**
 @SkillID QuickNavRadialSurface
 @Description SwiftUI 径向导航界面，只负责渲染 Core 提供的菜单项、中心缓冲区和隐藏光标替代红点。
 @Capabilities 按状态高亮命中项、把 Core 几何坐标转换为 SwiftUI offset、显示中心缓冲区、渲染红点光标。
 @LastUpdatedBy Codex
 */
import QuickNavCore
import SwiftUI

struct RadialMenuView: View {
    @Environment(\.colorScheme) private var colorScheme

    // 来自 AppKit 控制器的共享状态，决定高亮项和红点位置。
    @ObservedObject var state: RadialMenuState

    // AppState 类似前端里的全局 store，提供主题、几何参数和当前配置菜单项。
    @ObservedObject var appState: AppState

    private var palette: ThemePalette {
        appState.themePalette(for: colorScheme)
    }

    private var items: [NavigationItem] {
        appState.menuConfig.items
    }

    private let pageSize = 8

    private var currentPageItems: [NavigationItem] {
        let startIndex = state.currentPageIndex * pageSize
        guard items.indices.contains(startIndex) else {
            return []
        }

        let endIndex = min(startIndex + pageSize, items.count)
        return Array(items[startIndex..<endIndex])
    }

    private var pageCount: Int {
        max(1, Int(ceil(Double(items.count) / Double(pageSize))))
    }

    /**
     @name visualPosition
     @description 将 Core 的 Double 坐标转换成 SwiftUI 的 CGPoint；视图不保存几何算法。
     */
    static func visualPosition(for index: Int, total: Int, radius: CGFloat) -> CGPoint {
        let point = RadialMenuGeometry.visualPosition(for: index, total: total, radius: Double(radius))
        return CGPoint(x: point.x, y: point.y)
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

            ForEach(Array(currentPageItems.enumerated()), id: \.element.id) { index, item in
                radialItem(item, index: index)
            }

            PageIndicatorView(
                pageCount: pageCount,
                currentPageIndex: state.currentPageIndex,
                palette: palette
            )
            .offset(y: appState.menuRadius + 86)
            .animation(.easeOut(duration: 0.12), value: state.currentPageIndex)

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
    private func radialItem(_ item: NavigationItem, index: Int) -> some View {
        let position = Self.visualPosition(for: index, total: pageSize, radius: appState.menuRadius)
        let isActive = item.id == state.selectedItemID

        return VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: CGFloat(DesignTokens.Radius.item), style: .continuous)
                    .fill(isActive ? palette.accent : palette.row)
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(DesignTokens.Radius.item), style: .continuous)
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
        .animation(.easeOut(duration: 0.08), value: state.currentPageIndex)
        .offset(x: position.x, y: position.y)
    }
}

private struct PageIndicatorView: View {
    let pageCount: Int
    let currentPageIndex: Int
    let palette: ThemePalette

    // 和 iOS 分页控制器类似：只表达当前页位置，不参与鼠标命中。
    var body: some View {
        if pageCount > 1 {
            HStack(spacing: 7) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Circle()
                        .fill(index == currentPageIndex ? palette.accent : palette.textMuted.opacity(0.45))
                        .frame(width: index == currentPageIndex ? 7 : 6, height: index == currentPageIndex ? 7 : 6)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(palette.border.opacity(0.75), lineWidth: 1)
            )
            .allowsHitTesting(false)
        }
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

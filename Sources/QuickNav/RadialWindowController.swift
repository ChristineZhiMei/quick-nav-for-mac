/**
 @SkillID QuickNavDirectionalNavigator
 @Description 管理按住快捷键后的径向导航窗口、隐藏光标、替代红点、鼠标拖动选择与关闭/重置流程。
 @Capabilities 显示透明浮层、隐藏系统光标、监听鼠标按下/拖动/松开、按图标区域命中菜单项、恢复光标原点、处理多屏坐标转换。
 @LastUpdatedBy Codex
 */
import AppKit
import SwiftUI
import os

// SwiftUI 导航视图的共享状态，由 AppKit 鼠标事件驱动更新。
@MainActor
final class RadialMenuState: ObservableObject {
    // 当前红点真正进入图标命中区的菜单项；nil 表示未选中。
    @Published var selectedItemID: String?

    // 红点相对导航中心的视觉偏移，y 轴使用 SwiftUI 坐标系。
    @Published var cursorOffset: CGSize = .zero
}

@MainActor
final class RadialWindowController {
    private let logger = Logger(subsystem: "QuickNav", category: "RadialWindow")

    // 设置页会更新这些菜单几何参数，窗口控制器负责在命中算法中使用同一份值。
    private let appState: AppState

    // 选中项结算后交给 AppDelegate 统一分发到 ActionExecutor。
    private let onSelectItem: @MainActor (RadialMenuItem) -> Void

    // 透明浮层窗口尺寸需要比图标布局更大一些，给圆形背景模糊扩散预留空间，避免 blur 边缘被裁切。
    private let windowSize = NSSize(width: 520, height: 520)

    // SwiftUI 视图状态，AppKit 事件只更新这里，不直接操作视图层级。
    private let menuState = RadialMenuState()

    // 承载 RadialMenuView 的透明 floating NSPanel。
    private lazy var panel: EscapeKeyPanel = makePanel()

    // 透明全屏窗口，用于给系统设置空光标，增强隐藏光标的稳定性。
    private lazy var cursorCaptureWindow: CursorCaptureWindow = makeCursorCaptureWindow()

    // 导航打开时的 AppKit 屏幕坐标，关闭/取消时真实光标恢复到这里。
    private var originPoint: NSPoint?

    // 用户按下触摸板/鼠标时的起点；只有按下后拖动才移动红点。
    private var dragStartPoint: NSPoint?

    // 本应用窗口内鼠标事件监听 token。
    private var localMouseMonitor: Any?

    // 应用外鼠标事件监听 token；保证菜单栏 accessory 应用也能持续收到拖动事件。
    private var globalMouseMonitor: Any?

    // 记录当前是否已经请求隐藏光标，避免 hide/show 调用不平衡。
    private var isCursorHidden = false

    // 光标所在显示器，用于多屏场景下隐藏/恢复正确 display 的系统光标。
    private var cursorDisplayID = CGMainDisplayID()

    init(appState: AppState, onSelectItem: @escaping @MainActor (RadialMenuItem) -> Void) {
        self.appState = appState
        self.onSelectItem = onSelectItem
    }

    /**
     @name beginNavigation
     @description 快捷键按下时打开导航：记录原点、显示浮层、隐藏系统光标、启动鼠标事件监听。
     @link HotKeyManager.onPress
     */
    func beginNavigation() {
        if panel.isVisible {
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        originPoint = mouseLocation
        cursorDisplayID = displayID(for: mouseLocation)
        dragStartPoint = nil
        menuState.selectedItemID = nil
        menuState.cursorOffset = .zero

        let frame = frameCentered(on: mouseLocation)

        panel.setFrame(frame, display: true)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        showCursorCaptureWindow()
        hideCursorIfNeeded()
        startMouseTracking()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignTokens.Motion.appearDuration
            panel.animator().alphaValue = 1
        }
    }

    /**
     @name finishNavigation
     @description 结算当前选中项并关闭导航。当前只在选中某个应用后松开鼠标/触摸板时调用。
     @link handleMouseEvent
     */
    func finishNavigation() {
        settleSelectionIfNeeded()
        closeNavigation(restoreCursorToOrigin: true)
    }

    /**
     @name cancelNavigation
     @description 快捷键松开或 Escape 时关闭导航，不结算选中项，并恢复真实光标到打开位置。
     @link AppDelegate / EscapeKeyPanel
     */
    func cancelNavigation() {
        closeNavigation(restoreCursorToOrigin: true)
    }

    /**
     @name closeNavigation
     @description 关闭导航的唯一出口，负责停止事件监听、恢复光标、清空 SwiftUI 状态和淡出窗口。
     */
    private func closeNavigation(restoreCursorToOrigin: Bool) {
        guard panel.isVisible else { return }

        stopMouseTracking()
        if restoreCursorToOrigin, let originPoint {
            warpCursor(to: originPoint)
        }
        cursorCaptureWindow.orderOut(nil)
        showCursorIfNeeded()
        originPoint = nil
        dragStartPoint = nil
        menuState.selectedItemID = nil
        menuState.cursorOffset = .zero

        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignTokens.Motion.dismissDuration
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                self?.panel.orderOut(nil)
                self?.panel.alphaValue = 1
            }
        }
    }

    /**
     @name makePanel
     @description 创建承载 SwiftUI 导航的透明 NSPanel。窗口保持 floating，以便覆盖普通 app 内容。
     */
    private func makePanel() -> EscapeKeyPanel {
        let panel = EscapeKeyPanel(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.hidesOnDeactivate = false
        panel.onEscape = { [weak self] in
            self?.cancelNavigation()
        }

        let view = RadialMenuView(state: menuState, appState: appState)

        panel.contentView = NSHostingView(rootView: view)
        return panel
    }

    /**
     @name makeCursorCaptureWindow
     @description 创建透明全屏窗口并设置空光标，用于辅助隐藏系统光标。
     */
    private func makeCursorCaptureWindow() -> CursorCaptureWindow {
        let screenFrame = NSScreen.screens.reduce(NSRect.null) { result, screen in
            result.union(screen.frame)
        }

        let window = CursorCaptureWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .transient]
        window.hidesOnDeactivate = false
        window.contentView = CursorCaptureView(frame: screenFrame)
        return window
    }

    /**
     @name showCursorCaptureWindow
     @description 每次打开导航时重新覆盖所有屏幕范围，适配显示器布局变化。
     */
    private func showCursorCaptureWindow() {
        let screenFrame = NSScreen.screens.reduce(NSRect.null) { result, screen in
            result.union(screen.frame)
        }
        cursorCaptureWindow.setFrame(screenFrame, display: false)
        cursorCaptureWindow.orderFront(nil)
    }

    /**
     @name startMouseTracking
     @description 监听左键/触摸板按下、拖动、松开。普通移动不生效，避免未按住时红点漂移。
     */
    private func startMouseTracking() {
        stopMouseTracking()

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseEvent(event)
            }
            return event
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseEvent(event)
            }
        }
    }

    /**
     @name stopMouseTracking
     @description 移除 local/global 监听器，防止导航关闭后继续消费鼠标事件。
     */
    private func stopMouseTracking() {
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }

        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
    }

    /**
     @name handleMouseEvent
     @description 将鼠标事件解释为三段交互：按下建立拖动起点，拖动更新红点，松开按是否命中决定关闭或回中心。
     */
    private func handleMouseEvent(_ event: NSEvent) {
        hideCursorIfNeeded()

        switch event.type {
        case .leftMouseDown:
            dragStartPoint = NSEvent.mouseLocation
            hideCursorIfNeeded()
            menuState.selectedItemID = nil
            menuState.cursorOffset = .zero
        case .leftMouseDragged:
            updateSelection(for: NSEvent.mouseLocation)
        case .leftMouseUp:
            if menuState.selectedItemID == nil {
                resetNavigationPosition()
            } else {
                settleSelectionIfNeeded()
                closeNavigation(restoreCursorToOrigin: true)
            }
        default:
            break
        }
    }

    /**
     @name updateSelection
     @description 根据拖动位移更新红点位置；红点视觉上限制在半径内，但不 warp 真实光标，避免边界卡死。
     */
    private func updateSelection(for point: NSPoint) {
        guard let dragStartPoint else {
            menuState.selectedItemID = nil
            menuState.cursorOffset = .zero
            return
        }

        let dx = point.x - dragStartPoint.x
        let dy = point.y - dragStartPoint.y
        let distance = hypot(dx, dy)

        if distance > appState.menuRadius {
            let scale = appState.menuRadius / distance
            menuState.cursorOffset = CGSize(
                width: dx * scale,
                height: -(dy * scale)
            )
        } else {
            menuState.cursorOffset = CGSize(width: dx, height: -dy)
        }

        guard distance >= appState.deadZoneRadius else {
            menuState.selectedItemID = nil
            return
        }

        menuState.selectedItemID = selectedItemID(cursorOffset: menuState.cursorOffset)
    }

    /**
     @name selectedItemID
     @description 用红点和图标中心距离做真实命中，只有进入图标区域才选中，避免按角度提前高亮。
     */
    private func selectedItemID(cursorOffset: CGSize) -> String? {
        let hitRadius = appState.itemSize / 2 + 8
        let cursorPoint = CGPoint(x: cursorOffset.width, y: cursorOffset.height)

        return RadialMenuView.items.enumerated().first { index, _ in
            let itemPoint = RadialMenuView.visualPosition(for: index, radius: appState.menuRadius)
            return hypot(cursorPoint.x - itemPoint.x, cursorPoint.y - itemPoint.y) <= hitRadius
        }?.element.id
    }

    /**
     @name resetNavigationPosition
     @description 未命中时松开触摸板/鼠标不关闭导航，只把红点和真实光标恢复到中心。
     */
    private func resetNavigationPosition() {
        guard let originPoint else { return }
        warpCursor(to: originPoint)
        dragStartPoint = nil
        menuState.selectedItemID = nil
        menuState.cursorOffset = .zero
        hideCursorIfNeeded()
    }

    /**
     @name settleSelectionIfNeeded
     @description 命中任意菜单项时统一回调上层执行动作。
     */
    private func settleSelectionIfNeeded() {
        guard let selectedItem = RadialMenuView.items.first(where: { $0.id == menuState.selectedItemID }) else {
            return
        }

        logger.info("Selected item: \(selectedItem.title, privacy: .public)")
        onSelectItem(selectedItem)
    }

    /**
     @name hideCursorIfNeeded
     @description 使用 Quartz 按 display 隐藏系统光标；通过状态位避免 hide/show 不平衡。
     */
    private func hideCursorIfNeeded() {
        guard !isCursorHidden else { return }
        CGDisplayHideCursor(cursorDisplayID)
        isCursorHidden = true
    }

    /**
     @name showCursorIfNeeded
     @description 恢复被 QuickNav 隐藏的系统光标。
     */
    private func showCursorIfNeeded() {
        guard isCursorHidden else { return }
        CGDisplayShowCursor(cursorDisplayID)
        isCursorHidden = false
    }

    /**
     @name frameCentered
     @description 计算导航窗口位置，让窗口围绕打开时鼠标点，同时保持在当前屏幕可见区域内。
     */
    private func frameCentered(on point: NSPoint) -> NSRect {
        let screen = NSScreen.screens.first { screen in
            NSMouseInRect(point, screen.frame, false)
        } ?? NSScreen.main

        let visibleFrame = screen?.visibleFrame ?? NSRect(origin: .zero, size: windowSize)
        var origin = NSPoint(
            x: point.x - windowSize.width / 2,
            y: point.y - windowSize.height / 2
        )

        origin.x = min(max(origin.x, visibleFrame.minX + 12), visibleFrame.maxX - windowSize.width - 12)
        origin.y = min(max(origin.y, visibleFrame.minY + 12), visibleFrame.maxY - windowSize.height - 12)

        return NSRect(origin: origin, size: windowSize)
    }

    /**
     @name warpCursor
     @description 将 AppKit 坐标转换为 Quartz 坐标后再移动真实光标，避免 y 轴方向导致大偏移。
     */
    private func warpCursor(to appKitPoint: NSPoint) {
        CGWarpMouseCursorPosition(quartzPoint(from: appKitPoint))
    }

    /**
     @name quartzPoint
     @description AppKit 坐标原点在左下，Quartz display 坐标原点按显示器边界计算；warp 前必须转换。
     */
    private func quartzPoint(from appKitPoint: NSPoint) -> CGPoint {
        guard let screen = screen(for: appKitPoint) else {
            return appKitPoint
        }

        let displayID = displayID(for: screen)
        let displayBounds = CGDisplayBounds(displayID)

        return CGPoint(
            x: displayBounds.minX + (appKitPoint.x - screen.frame.minX),
            y: displayBounds.minY + (screen.frame.maxY - appKitPoint.y)
        )
    }

    /**
     @name displayID
     @description 根据 AppKit 点或屏幕解析 CGDirectDisplayID，用于多屏隐藏光标与坐标转换。
     */
    private func displayID(for point: NSPoint) -> CGDirectDisplayID {
        guard let screen = screen(for: point) else {
            return CGMainDisplayID()
        }
        return displayID(for: screen)
    }

    private func displayID(for screen: NSScreen) -> CGDirectDisplayID {
        let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        return screenNumber.map { CGDirectDisplayID($0.uint32Value) } ?? CGMainDisplayID()
    }

    private func screen(for point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) } ?? NSScreen.main
    }
}

@MainActor
final class EscapeKeyPanel: NSPanel {
    // Escape 关闭导航时的回调，由 RadialWindowController 注入。
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    /**
     @name keyDown
     @description 让透明无边框面板也能响应 Escape 关闭导航。
     */
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onEscape?()
            return
        }

        super.keyDown(with: event)
    }
}

@MainActor
final class CursorCaptureWindow: NSWindow {
}

@MainActor
final class CursorCaptureView: NSView {
    /**
     @name resetCursorRects
     @description 给透明捕获窗口设置 1px 空光标，增强导航期间隐藏系统光标的稳定性。
     */
    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: NSCursor.emptyCursor)
    }
}

@MainActor
private extension NSCursor {
    // 透明光标图片用于 cursor rect，避免系统在透明窗口上恢复默认箭头。
    static var emptyCursor: NSCursor {
        let image = NSImage(size: NSSize(width: 1, height: 1))
        return NSCursor(image: image, hotSpot: .zero)
    }
}

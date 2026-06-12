/**
 @SkillID QuickNavRadialGeometry
 @Description 提供径向菜单坐标和命中计算的纯函数，避免窗口控制器承载算法细节。
 @Capabilities 计算菜单项相对中心坐标、按红点位置命中图标区域、处理中心 dead zone。
 @LastUpdatedBy Codex
 */
import Foundation

/// 轻量二维点，避免 Core 依赖 SwiftUI/AppKit 的 CGPoint。
public struct RadialPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// 径向菜单几何工具。输入坐标使用 SwiftUI 视图坐标：x 向右为正，y 向下为正。
public enum RadialMenuGeometry {
    /// 返回第 index 个菜单项相对中心的位置。0 号在正上方，后续按屏幕视觉顺时针排列。
    public static func visualPosition(for index: Int, total: Int, radius: Double) -> RadialPoint {
        guard total > 0 else {
            return RadialPoint(x: 0, y: 0)
        }

        let degrees = 90 - Double(index) * 360 / Double(total)
        let radians = degrees * .pi / 180

        return RadialPoint(
            x: cos(radians) * radius,
            y: -sin(radians) * radius
        )
    }

    /// 根据红点位置查找真正进入图标命中区的菜单项；距离中心太近时明确返回 nil。
    public static func selectedItemID(
        cursorOffset: RadialPoint,
        items: [NavigationItem],
        radius: Double,
        itemSize: Double,
        deadZoneRadius: Double
    ) -> String? {
        let distanceFromCenter = hypot(cursorOffset.x, cursorOffset.y)
        guard distanceFromCenter >= deadZoneRadius else {
            return nil
        }

        let hitRadius = itemSize / 2 + 8

        return items.enumerated().first { index, _ in
            let itemPoint = visualPosition(for: index, total: items.count, radius: radius)
            return hypot(cursorOffset.x - itemPoint.x, cursorOffset.y - itemPoint.y) <= hitRadius
        }?.element.id
    }

    /// 固定槽位命中：slotCount 控制圆环有多少个固定位置，items 只填充前几个槽位。
    /// 例如 pageSize=8 且当前页只有 2 个菜单时，只检测正上方和右上方两个槽位。
    public static func selectedItemIDInFixedSlots(
        cursorOffset: RadialPoint,
        items: [NavigationItem],
        slotCount: Int,
        radius: Double,
        itemSize: Double,
        deadZoneRadius: Double
    ) -> String? {
        let distanceFromCenter = hypot(cursorOffset.x, cursorOffset.y)
        guard distanceFromCenter >= deadZoneRadius, slotCount > 0 else {
            return nil
        }

        let hitRadius = itemSize / 2 + 8

        return items.enumerated().first { index, _ in
            guard index < slotCount else { return false }
            let itemPoint = visualPosition(for: index, total: slotCount, radius: radius)
            return hypot(cursorOffset.x - itemPoint.x, cursorOffset.y - itemPoint.y) <= hitRadius
        }?.element.id
    }
}

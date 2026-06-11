/**
 @SkillID QuickNavDesignTokens
 @Description QuickNav 原型阶段的视觉常量集合，保持径向菜单和替代光标的尺寸、颜色、动效一致。
 @Capabilities 提供 Raycast 风格深色配色、菜单半径、中心缓冲区半径、图标尺寸、出现/选择/关闭动效时间。
 @LastUpdatedBy Codex
 */
import Foundation

public enum DesignTokens {
    // 圆角仅保留当前 SwiftUI 视图实际使用的 item/panel 两档。
    public enum Radius {
        public static let item = 16.0
        public static let panel = 12.0
    }

    // radius 同时用于应用图标布局、红点视觉夹紧范围和命中计算的基准距离。
    public enum Menu {
        public static let radius = 125.0
        public static let deadZoneRadius = 37.0
        public static let itemSize = 60.0
        public static let isBackgroundVisible = false
        public static let backgroundRadius = 175.0
        public static let backgroundOpacity = 0.24
    }

    // 动效保持短促，避免影响方向选择手感。
    public enum Motion {
        public static let appearDuration: TimeInterval = 0.14
        public static let selectionDuration: TimeInterval = 0.10
        public static let dismissDuration: TimeInterval = 0.10
    }
}

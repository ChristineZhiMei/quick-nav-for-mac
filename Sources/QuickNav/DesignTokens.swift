/**
 @SkillID QuickNavDesignTokens
 @Description QuickNav 原型阶段的视觉常量集合，保持径向菜单和替代光标的尺寸、颜色、动效一致。
 @Capabilities 提供 Raycast 风格深色配色、菜单半径、死区半径、图标尺寸、出现/选择/关闭动效时间。
 @LastUpdatedBy Codex
 */
import SwiftUI

enum DesignTokens {
    // 颜色常量沿用设计文档中的深色浮层和红色强调色。
    enum Color {
        static let overlayBackground = SwiftUI.Color(red: 0.067, green: 0.067, blue: 0.075).opacity(0.92)
        static let overlayStroke = SwiftUI.Color.white.opacity(0.10)
        static let itemBackground = SwiftUI.Color(red: 0.141, green: 0.141, blue: 0.149)
        static let textPrimary = SwiftUI.Color(red: 0.96, green: 0.96, blue: 0.97)
        static let textSecondary = SwiftUI.Color(red: 0.63, green: 0.63, blue: 0.67)
        static let accent = SwiftUI.Color(red: 1.0, green: 0.30, blue: 0.30)
    }

    // 圆角仅保留当前 SwiftUI 视图实际使用的 item/panel 两档。
    enum Radius {
        static let item: CGFloat = 16
        static let panel: CGFloat = 12
    }

    // radius 同时用于应用图标布局、红点视觉夹紧范围和命中计算的基准距离。
    enum Menu {
        static let radius: CGFloat = 140
        static let deadZoneRadius: CGFloat = 36
        static let itemSize: CGFloat = 52
    }

    // 动效保持短促，避免影响方向选择手感。
    enum Motion {
        static let appearDuration: TimeInterval = 0.14
        static let selectionDuration: TimeInterval = 0.10
        static let dismissDuration: TimeInterval = 0.10
    }
}

import QuickNavCore

enum RadialMenuGeometryValidationScenarios {
    static func visualPositionsForEightItemsUseRightSideAsZeroDegrees() {
        let radius = 100.0

        assertPoint(RadialMenuGeometry.visualPosition(for: 0, total: 8, radius: radius), x: 100, y: 0)
        assertPoint(RadialMenuGeometry.visualPosition(for: 2, total: 8, radius: radius), x: 0, y: -100)
        assertPoint(RadialMenuGeometry.visualPosition(for: 4, total: 8, radius: radius), x: -100, y: 0)
        assertPoint(RadialMenuGeometry.visualPosition(for: 6, total: 8, radius: radius), x: 0, y: 100)
    }

    static func selectedItemRequiresIconHitArea() {
        let selectedID = RadialMenuGeometry.selectedItemID(
            cursorOffset: RadialPoint(x: 100, y: 0),
            items: DefaultNavigationCatalog.items,
            radius: 100,
            itemSize: 60,
            deadZoneRadius: 37
        )

        precondition(selectedID == "menu")
    }

    static func deadZoneReturnsNil() {
        let selectedID = RadialMenuGeometry.selectedItemID(
            cursorOffset: RadialPoint(x: 20, y: 0),
            items: DefaultNavigationCatalog.items,
            radius: 100,
            itemSize: 60,
            deadZoneRadius: 37
        )

        precondition(selectedID == nil)
    }

    private static func assertPoint(_ point: RadialPoint, x: Double, y: Double) {
        precondition(abs(point.x - x) < 0.0001)
        precondition(abs(point.y - y) < 0.0001)
    }
}

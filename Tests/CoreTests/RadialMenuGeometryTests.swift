import QuickNavCore

enum RadialMenuGeometryValidationScenarios {
    static func visualPositionsForEightItemsStartAtTopAndMoveClockwise() {
        let radius = 100.0

        assertPoint(RadialMenuGeometry.visualPosition(for: 0, total: 8, radius: radius), x: 0, y: -100)
        assertPoint(RadialMenuGeometry.visualPosition(for: 2, total: 8, radius: radius), x: 100, y: 0)
        assertPoint(RadialMenuGeometry.visualPosition(for: 4, total: 8, radius: radius), x: 0, y: 100)
        assertPoint(RadialMenuGeometry.visualPosition(for: 6, total: 8, radius: radius), x: -100, y: 0)
    }

    static func selectedItemRequiresIconHitArea() {
        let selectedID = RadialMenuGeometry.selectedItemID(
            cursorOffset: RadialPoint(x: 0, y: -100),
            items: DefaultNavigationCatalog.items,
            radius: 100,
            itemSize: 60,
            deadZoneRadius: 37
        )

        precondition(selectedID == "menu")
    }

    static func fixedSlotsOnlyHitVisiblePageItems() {
        let pageItems = Array(DefaultNavigationCatalog.items[8..<10])

        let selectedID = RadialMenuGeometry.selectedItemIDInFixedSlots(
            cursorOffset: RadialPoint(x: 0, y: -100),
            items: pageItems,
            slotCount: 8,
            radius: 100,
            itemSize: 60,
            deadZoneRadius: 37
        )
        let emptySlotID = RadialMenuGeometry.selectedItemIDInFixedSlots(
            cursorOffset: RadialPoint(x: 100, y: 0),
            items: pageItems,
            slotCount: 8,
            radius: 100,
            itemSize: 60,
            deadZoneRadius: 37
        )

        precondition(selectedID == "calendar")
        precondition(emptySlotID == nil)
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

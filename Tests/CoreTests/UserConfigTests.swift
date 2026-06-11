import Foundation
import QuickNavCore

enum QuickNavUserConfigValidationScenarios {
    static func decodeMissingThemeAndMenuUsesDefaults() throws {
        let json = """
        {
          "hotKey": {
            "key": "R",
            "modifiers": ["command", "shift"]
          }
        }
        """

        let config = try JSONDecoder().decode(QuickNavUserConfig.self, from: Data(json.utf8))

        precondition(config.hotKey == HotKeyConfig(key: "R", modifiers: [.command, .shift]))
        precondition(config.theme == .default)
        precondition(config.menu == .default)
    }

    static func decodeLegacyMenuItemWithoutActionUsesDefaultCatalogAction() throws {
        let json = """
        {
          "menu": {
            "radius": 125,
            "deadZoneRadius": 37,
            "itemSize": 60,
            "items": [
              {
                "id": "reload",
                "title": "重载",
                "systemImage": "arrow.clockwise"
              }
            ]
          }
        }
        """

        let config = try JSONDecoder().decode(QuickNavUserConfig.self, from: Data(json.utf8))

        precondition(config.menu.items.first?.action == .reloadConfig)
    }
}

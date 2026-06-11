import QuickNavCore

enum HotKeyConfigValidationScenarios {
    static func validationRequiresModifier() {
        do {
            _ = try HotKeyConfig(key: "S", modifiers: []).validated()
            fatalError("Expected missingModifier")
        } catch HotKeyConfigError.missingModifier {
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    static func validationRejectsUnsupportedKey() {
        do {
            _ = try HotKeyConfig(key: "Space", modifiers: [.control]).validated()
            fatalError("Expected unsupportedKey")
        } catch HotKeyConfigError.unsupportedKey("SPACE") {
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    static func validationNormalizesKeyAndModifierOrder() throws {
        let config = try HotKeyConfig(key: "s", modifiers: [.control, .command]).validated()

        precondition(config.key == "S")
        precondition(config.modifiers == [.command, .control])
        precondition(config.displayText == "Command + Control + S")
    }
}

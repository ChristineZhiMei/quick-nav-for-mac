# QuickNav for Mac

QuickNav is a macOS resident shortcut launcher. Hold a global hotkey, move the pointer toward a radial menu item, then release to open a URL, launch an app, or run a local command.

The product direction is a lightweight personal macOS utility: low interruption, fast pointer-driven selection, local JSON configuration, and a Raycast-inspired dark interface.

![QuickNav Raycast design](docs/assets/design/quicknav-raycast-design.png)

## Current Status

- Product requirements are drafted.
- Development architecture is drafted.
- Raycast-inspired visual direction is drafted.
- Pencil design exploration is exported to `docs/assets/design/quicknav-raycast-design.png`.
- Minimal SwiftPM app scaffold is implemented: menu bar app, `Command + Shift + D` hotkey, and a basic radial navigation surface.

## Run Locally

Build the app:

```bash
swift build
```

Run the menu bar prototype:

```bash
swift run QuickNav
```

Once running, the `Q` item appears in the macOS menu bar. Click `Q` to open the status menu. Hold `Command + Shift + D` to show the navigation surface, then press and drag with one finger on the trackpad or mouse to move the red cursor dot. Releasing the trackpad or mouse only closes the surface when an item is selected; otherwise it resets the dot and cursor back to the center. Releasing the hotkey always closes the surface and restores the system cursor to the starting point.

## Documents

- [Product Requirements](docs/prd.md)
- [Development Plan](docs/development.md)
- [Design Direction](docs/design.md)

## Project Structure

```text
quick-nav-for-mac/
├── README.md
├── docs/
│   ├── prd.md
│   ├── development.md
│   ├── design.md
│   └── assets/
│       ├── brand/
│       │   └── quicknav-clean.svg
│       ├── design/
│       │   └── quicknav-raycast-design.png
│       └── prototypes/
│           └── *.png
```

## Product Summary

QuickNav appears around the current pointer position while the global hotkey is held. The pointer is hidden and a red cursor dot moves only while the trackpad or mouse is pressed. The red dot is visually clamped to the navigation radius without warping the real pointer during drag. Items are selected only when the dot reaches the item icon area. The first item opens the status menu.

Default interaction decisions:

- Hotkey: `Command + Shift + D`
- Menu radius: `140px`
- Dead zone radius: `36px`
- Default menu item count: `8`
- Angle origin: right side of the screen
- Direction order: clockwise

## Design Direction

The interface follows a Raycast-inspired style without copying Raycast's command palette shape directly. The radial menu remains the primary QuickNav interaction model.

Key visual decisions:

- Dark translucent surfaces.
- Compact tool UI.
- High-contrast typography.
- Red accent for active selection.
- Strong selection feedback through color, scale, shadow, and text contrast.
- macOS-native implementation using SwiftUI, AppKit, SF Symbols, and system materials where practical.

## Planned Technical Stack

- Swift
- SwiftUI
- AppKit
- Carbon HotKey or equivalent global hotkey handling
- `NSEvent` / `CGEvent` mouse tracking
- `NSWorkspace` and `Process` for action execution
- `Codable` JSON configuration
- XCTest for angle calculation, config parsing, and action validation

## Implementation Notes

The current prototype intentionally does not execute real actions or load JSON configuration. The first implementation milestone is only the app shell: status bar presence, press-and-hold global hotkey behavior, hidden-cursor directional selection, and a Raycast-inspired radial menu shape.

## Asset Notes

`docs/assets/prototypes/` contains early visual references and generated prototype images. The current design reference to use for implementation is:

```text
docs/assets/design/quicknav-raycast-design.png
```

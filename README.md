# MenuFold

MenuFold is a native macOS menu-bar organizer. It creates a movable boundary in the menu bar: only the icons you place to the left can be revealed or tucked away, while everything to the right always remains visible.

## Use

1. Launch MenuFold.
2. Open **Arrangement Guide**. MenuFold reveals every icon and places `‹‹` beside its menu-bar icon.
3. In the real menu bar at the top of the screen, hold Command and drag the `‹‹` divider left.
4. Release it between the icons that may hide and those that should always remain visible.
5. Click the MenuFold icon to toggle the hidden section, or use your shortcut.

The default shortcut is Option-Command-M. Open **Settings → Behavior**, click the shortcut recorder, and type any modifier-key combination to replace it.

Quitting MenuFold always reveals the hidden section.

## Build

```sh
./scripts/build-app.sh
./scripts/install-app.sh
```

The build script signs the app with `Apple Development: Abdul Rafay (6ZJ47FNNCB)` by default.

## Requirements

- macOS 14 or later
- Xcode 16 or later
- An installed Apple Development signing certificate

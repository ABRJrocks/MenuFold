import AppKit
import SwiftUI

@main
enum MenuFoldApp {
  @MainActor
  static func main() {
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.delegate = delegate
    application.setActivationPolicy(.accessory)
    application.run()
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var model: AppModel?
  private var menuBarController: MenuBarController?
  private var windowCoordinator: WindowCoordinator?
  private var hotKey: GlobalHotKey?

  func applicationDidFinishLaunching(_ notification: Notification) {
    let model = AppModel()
    let windows = WindowCoordinator(model: model)
    let menuBarController = MenuBarController(model: model, windows: windows)

    model.onToggleRequested = { [weak menuBarController] in
      menuBarController?.toggleHiddenItems()
    }
    model.onOpenSettingsRequested = { [weak windows] in
      windows?.showSettings()
    }
    model.onShowGuideRequested = { [weak windows] in
      windows?.showOnboarding()
    }

    self.model = model
    self.windowCoordinator = windows
    self.menuBarController = menuBarController
    model.onBeginArrangementRequested = { [weak menuBarController] in
      menuBarController?.beginArrangement()
    }
    model.onShortcutChanged = { [weak self] in
      self?.configureGlobalHotKey()
    }
    configureGlobalHotKey()

    model.enableLaunchAtLoginIfNeeded()

    if !model.hasCompletedOnboarding {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
        windows.showOnboarding()
      }
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    hotKey?.invalidate()
    menuBarController?.revealBeforeQuitting()
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool
  {
    if !flag {
      windowCoordinator?.showSettings()
    }
    return true
  }

  private func configureGlobalHotKey() {
    hotKey?.invalidate()
    hotKey = nil

    guard let model else { return }
    let newHotKey = GlobalHotKey(
      keyCode: model.shortcutKeyCode,
      modifiers: model.shortcutModifiers
    ) {
      model.requestToggle()
    }

    hotKey = newHotKey
    model.hotKeyAvailable = newHotKey != nil
    UserDefaults.standard.set(newHotKey != nil, forKey: "menuFold.hotKeyRegistered")
  }
}

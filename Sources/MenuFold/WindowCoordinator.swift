import AppKit
import SwiftUI

@MainActor
final class WindowCoordinator {
  private let model: AppModel
  private var onboardingWindow: NSWindow?
  private var settingsWindow: NSWindow?

  init(model: AppModel) {
    self.model = model
  }

  var isOnboardingVisible: Bool {
    onboardingWindow?.isVisible ?? false
  }

  func showOnboarding() {
    model.beginArrangement()

    if let onboardingWindow {
      present(onboardingWindow)
      return
    }

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 620, height: 570),
      styleMask: [.titled, .closable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    window.title = "Welcome to MenuFold"
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.isMovableByWindowBackground = true
    window.isReleasedWhenClosed = false
    window.center()
    window.contentViewController = NSHostingController(
      rootView: OnboardingView(model: model) { [weak self] in
        self?.closeOnboarding()
      }
    )
    onboardingWindow = window
    present(window)
  }

  func closeOnboarding() {
    onboardingWindow?.close()
  }

  func showSettings() {
    if let settingsWindow {
      present(settingsWindow)
      return
    }

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 560, height: 500),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    window.title = "MenuFold Settings"
    window.isReleasedWhenClosed = false
    window.center()
    window.contentViewController = NSHostingController(rootView: SettingsView(model: model))
    settingsWindow = window
    present(window)
  }

  private func present(_ window: NSWindow) {
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
  }
}

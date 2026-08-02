import AppKit
import Carbon
import Testing

@testable import MenuFold

struct MenuFoldTests {
  @Test func rehidePolicyRequiresAnEnabledPositiveDelay() {
    #expect(RehidePolicy(isEnabled: true, delay: 8).shouldSchedule)
    #expect(!RehidePolicy(isEnabled: false, delay: 8).shouldSchedule)
    #expect(!RehidePolicy(isEnabled: true, delay: 0).shouldSchedule)
  }

  @Test func shortcutFormatterUsesMacModifierOrder() {
    let display = ShortcutFormatter.displayString(
      modifiers: UInt32(controlKey | optionKey | shiftKey | cmdKey),
      keyLabel: "h"
    )

    #expect(display == "⌃⌥⇧⌘H")
  }

  @Test @MainActor func arrangementGuideReopensAfterBeingClosed() {
    _ = NSApplication.shared
    let suiteName = "MenuFoldTests.WindowCoordinator.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let model = AppModel(defaults: defaults)
    let coordinator = WindowCoordinator(model: model)

    coordinator.showOnboarding()
    #expect(coordinator.isOnboardingVisible)

    coordinator.closeOnboarding()
    #expect(!coordinator.isOnboardingVisible)

    coordinator.showOnboarding()
    #expect(coordinator.isOnboardingVisible)
    coordinator.closeOnboarding()
  }
}

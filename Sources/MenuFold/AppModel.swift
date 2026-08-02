import AppKit
import Carbon
import Combine
import ServiceManagement

struct RehidePolicy: Equatable {
  var isEnabled: Bool
  var delay: TimeInterval

  var shouldSchedule: Bool { isEnabled && delay > 0 }
}

@MainActor
final class AppModel: ObservableObject {
  private enum Key {
    static let isHidden = "menuFold.isHidden"
    static let autoRehide = "menuFold.autoRehide"
    static let rehideDelay = "menuFold.rehideDelay"
    static let hasCompletedOnboarding = "menuFold.hasCompletedOnboarding"
    static let shortcutKeyCode = "menuFold.shortcutKeyCode"
    static let shortcutModifiers = "menuFold.shortcutModifiers"
    static let shortcutKeyLabel = "menuFold.shortcutKeyLabel"
  }

  @Published private(set) var isHidden: Bool
  @Published var autoRehide: Bool {
    didSet { defaults.set(autoRehide, forKey: Key.autoRehide) }
  }
  @Published var rehideDelay: TimeInterval {
    didSet { defaults.set(rehideDelay, forKey: Key.rehideDelay) }
  }
  @Published private(set) var launchAtLoginEnabled = false
  @Published var launchAtLoginMessage: String?
  @Published var hotKeyAvailable = false
  @Published private(set) var shortcutKeyCode: UInt32
  @Published private(set) var shortcutModifiers: UInt32
  @Published private(set) var shortcutKeyLabel: String

  var onToggleRequested: (() -> Void)?
  var onOpenSettingsRequested: (() -> Void)?
  var onShowGuideRequested: (() -> Void)?
  var onShortcutChanged: (() -> Void)?
  var onBeginArrangementRequested: (() -> Void)?

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults

    if defaults.object(forKey: Key.isHidden) == nil {
      defaults.set(false, forKey: Key.isHidden)
    }
    if defaults.object(forKey: Key.autoRehide) == nil {
      defaults.set(true, forKey: Key.autoRehide)
    }
    if defaults.object(forKey: Key.rehideDelay) == nil {
      defaults.set(8.0, forKey: Key.rehideDelay)
    }
    if defaults.object(forKey: Key.shortcutKeyCode) == nil {
      defaults.set(Int(kVK_ANSI_M), forKey: Key.shortcutKeyCode)
      defaults.set(Int(cmdKey | optionKey), forKey: Key.shortcutModifiers)
      defaults.set("M", forKey: Key.shortcutKeyLabel)
    }

    isHidden = defaults.bool(forKey: Key.isHidden)
    autoRehide = defaults.bool(forKey: Key.autoRehide)
    rehideDelay = defaults.double(forKey: Key.rehideDelay)
    shortcutKeyCode = UInt32(defaults.integer(forKey: Key.shortcutKeyCode))
    shortcutModifiers = UInt32(defaults.integer(forKey: Key.shortcutModifiers))
    shortcutKeyLabel = defaults.string(forKey: Key.shortcutKeyLabel) ?? "M"
    refreshLaunchAtLoginStatus()
  }

  var hasCompletedOnboarding: Bool {
    defaults.bool(forKey: Key.hasCompletedOnboarding)
  }

  var rehidePolicy: RehidePolicy {
    RehidePolicy(isEnabled: autoRehide, delay: rehideDelay)
  }

  var shortcutDisplay: String {
    ShortcutFormatter.displayString(modifiers: shortcutModifiers, keyLabel: shortcutKeyLabel)
  }

  func setHidden(_ hidden: Bool) {
    isHidden = hidden
    defaults.set(hidden, forKey: Key.isHidden)
  }

  func completeOnboarding() {
    defaults.set(true, forKey: Key.hasCompletedOnboarding)
  }

  func requestToggle() {
    onToggleRequested?()
  }

  func beginArrangement() {
    onBeginArrangementRequested?()
  }

  func setShortcut(keyCode: UInt32, modifiers: UInt32, keyLabel: String) {
    shortcutKeyCode = keyCode
    shortcutModifiers = modifiers
    shortcutKeyLabel = keyLabel.uppercased()
    defaults.set(Int(keyCode), forKey: Key.shortcutKeyCode)
    defaults.set(Int(modifiers), forKey: Key.shortcutModifiers)
    defaults.set(shortcutKeyLabel, forKey: Key.shortcutKeyLabel)
    onShortcutChanged?()
  }

  func resetShortcut() {
    setShortcut(
      keyCode: UInt32(kVK_ANSI_M),
      modifiers: UInt32(cmdKey | optionKey),
      keyLabel: "M"
    )
  }

  func refreshLaunchAtLoginStatus() {
    launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
  }

  func enableLaunchAtLoginIfNeeded() {
    guard SMAppService.mainApp.status != .enabled else {
      launchAtLoginEnabled = true
      return
    }
    setLaunchAtLogin(true)
  }

  func setLaunchAtLogin(_ enabled: Bool) {
    launchAtLoginMessage = nil
    do {
      if enabled {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
    } catch {
      launchAtLoginMessage =
        enabled
        ? "macOS needs your approval in Login Items."
        : "MenuFold could not update Login Items."
    }
    refreshLaunchAtLoginStatus()
  }

  func openLoginItemsSettings() {
    guard let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")
    else { return }
    NSWorkspace.shared.open(url)
  }
}

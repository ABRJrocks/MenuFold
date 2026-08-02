import AppKit
import Carbon
import SwiftUI

enum ShortcutFormatter {
  static func displayString(modifiers: UInt32, keyLabel: String) -> String {
    var result = ""
    if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
    if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
    if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
    if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
    return result + keyLabel.uppercased()
  }
}

struct ShortcutRecorder: NSViewRepresentable {
  let displayString: String
  let onChange: (UInt32, UInt32, String) -> Void

  func makeNSView(context: Context) -> ShortcutRecorderButton {
    let button = ShortcutRecorderButton()
    button.onShortcut = onChange
    button.setDisplayString(displayString)
    return button
  }

  func updateNSView(_ nsView: ShortcutRecorderButton, context: Context) {
    nsView.onShortcut = onChange
    nsView.setDisplayString(displayString)
  }
}

@MainActor
final class ShortcutRecorderButton: NSButton {
  var onShortcut: ((UInt32, UInt32, String) -> Void)?

  private var currentDisplay = ""
  private var isRecording = false

  override var acceptsFirstResponder: Bool { true }

  init() {
    super.init(frame: NSRect(x: 0, y: 0, width: 108, height: 28))
    configure()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    configure()
  }

  private func configure() {
    bezelStyle = .rounded
    controlSize = .regular
    font = .monospacedSystemFont(ofSize: 12, weight: .medium)
    setButtonType(.momentaryChange)
    setAccessibilityLabel("Keyboard shortcut recorder")
    setAccessibilityHelp("Click, then type a shortcut using at least one modifier key")
  }

  override var intrinsicContentSize: NSSize {
    NSSize(width: 118, height: 28)
  }

  func setDisplayString(_ value: String) {
    currentDisplay = value
    if !isRecording { title = value }
  }

  override func mouseDown(with event: NSEvent) {
    window?.makeFirstResponder(self)
    isRecording = true
    title = "Type shortcut…"
  }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == UInt16(kVK_Escape) {
      finishRecording(with: currentDisplay)
      return
    }

    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    let carbonModifiers = Self.carbonModifiers(from: flags)
    guard carbonModifiers != 0, let label = Self.keyLabel(for: event) else {
      title = "Add a modifier"
      NSSound.beep()
      return
    }

    let keyCode = UInt32(event.keyCode)
    let display = ShortcutFormatter.displayString(
      modifiers: carbonModifiers,
      keyLabel: label
    )
    currentDisplay = display
    onShortcut?(keyCode, carbonModifiers, label)
    finishRecording(with: display)
  }

  override func resignFirstResponder() -> Bool {
    isRecording = false
    title = currentDisplay
    return super.resignFirstResponder()
  }

  private func finishRecording(with display: String) {
    isRecording = false
    title = display
    window?.makeFirstResponder(nil)
  }

  private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
    var result: UInt32 = 0
    if flags.contains(.control) { result |= UInt32(controlKey) }
    if flags.contains(.option) { result |= UInt32(optionKey) }
    if flags.contains(.shift) { result |= UInt32(shiftKey) }
    if flags.contains(.command) { result |= UInt32(cmdKey) }
    return result
  }

  private static func keyLabel(for event: NSEvent) -> String? {
    switch Int(event.keyCode) {
    case kVK_Space: return "Space"
    case kVK_Return: return "↩"
    case kVK_Tab: return "Tab"
    case kVK_Delete: return "⌫"
    case kVK_ForwardDelete: return "⌦"
    case kVK_LeftArrow: return "←"
    case kVK_RightArrow: return "→"
    case kVK_UpArrow: return "↑"
    case kVK_DownArrow: return "↓"
    case kVK_Home: return "Home"
    case kVK_End: return "End"
    case kVK_PageUp: return "Page Up"
    case kVK_PageDown: return "Page Down"
    default:
      guard let characters = event.charactersIgnoringModifiers, !characters.isEmpty else {
        return nil
      }
      return characters.uppercased()
    }
  }
}

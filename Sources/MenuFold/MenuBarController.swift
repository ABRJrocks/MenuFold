import AppKit
import Combine
import SwiftUI

@MainActor
final class MenuBarController: NSObject {
  private enum StatusItemID {
    static let control = "MenuFold.Control"
    static let boundary = "MenuFold.Boundary"
  }

  private static let expandedLength: CGFloat = 10_000

  private let model: AppModel
  private let windows: WindowCoordinator
  private let controlItem: NSStatusItem
  private let boundaryItem: NSStatusItem
  private let popover = NSPopover()
  private var rehideTimer: Timer?
  private var cancellables = Set<AnyCancellable>()

  init(model: AppModel, windows: WindowCoordinator) {
    self.model = model
    self.windows = windows

    Self.seedPreferredPositions()

    controlItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    controlItem.autosaveName = StatusItemID.control

    boundaryItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    boundaryItem.autosaveName = StatusItemID.boundary

    super.init()

    configureControlItem()
    configureBoundaryItem()
    configurePopover()
    applyVisibility(animated: false)

    model.$autoRehide
      .combineLatest(model.$rehideDelay)
      .dropFirst()
      .sink { [weak self] _, _ in self?.rescheduleRehideIfNeeded() }
      .store(in: &cancellables)
  }

  private static func seedPreferredPositions() {
    let controlKey = "NSStatusItem Preferred Position \(StatusItemID.control)"
    let boundaryKey = "NSStatusItem Preferred Position \(StatusItemID.boundary)"
    let layoutVersionKey = "menuFold.statusItemLayoutVersion"
    if UserDefaults.standard.object(forKey: controlKey) == nil {
      UserDefaults.standard.set(CGFloat(0), forKey: controlKey)
    }
    if UserDefaults.standard.integer(forKey: layoutVersionKey) < 3 {
      // Keep the boundary beside MenuFold for first-time setup. The user can
      // Command-drag this one reliable item to define the two sections.
      UserDefaults.standard.set(CGFloat(1), forKey: boundaryKey)
      UserDefaults.standard.set(3, forKey: layoutVersionKey)
    }
  }

  private func configureControlItem() {
    guard let button = controlItem.button else { return }
    button.image = symbol("rectangle.3.group.fill", pointSize: 15, weight: .semibold)
    button.image?.isTemplate = true
    button.imagePosition = .imageOnly
    button.toolTip = "MenuFold — click to organize"
    button.target = self
    button.action = #selector(showPopover(_:))
    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    button.setAccessibilityLabel("MenuFold")
    button.setAccessibilityHelp("Opens controls for hidden menu bar items")
  }

  private func configureBoundaryItem() {
    guard let button = boundaryItem.button else { return }
    button.image = symbol("chevron.left.2", pointSize: 10, weight: .bold)
    button.image?.isTemplate = true
    button.imagePosition = .imageOnly
    button.toolTip = "MenuFold boundary — Command-drag items to its left"
    button.target = self
    button.action = #selector(boundaryClicked(_:))
    button.setAccessibilityLabel("Hidden items boundary")
    button.setAccessibilityHelp("Command-drag menu bar items to the left of this boundary")
  }

  private func configurePopover() {
    popover.behavior = .transient
    popover.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    popover.contentSize = NSSize(width: 380, height: 510)
    popover.contentViewController = NSHostingController(
      rootView: MenuFoldPopoverView(model: model, windows: windows)
    )
  }

  private func symbol(_ name: String, pointSize: CGFloat, weight: NSFont.Weight) -> NSImage? {
    let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
    return NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(
      configuration)
  }

  @objc private func showPopover(_ sender: Any?) {
    if NSApp.currentEvent?.type == .rightMouseUp {
      showContextMenu()
      return
    }
    guard let button = controlItem.button else { return }
    if popover.isShown {
      popover.performClose(nil)
    } else {
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
      popover.contentViewController?.view.window?.makeKey()
    }
  }

  @objc private func boundaryClicked(_ sender: Any?) {
    toggleHiddenItems()
  }

  func toggleHiddenItems() {
    setHidden(!model.isHidden)
  }

  func beginArrangement() {
    rehideTimer?.invalidate()
    model.setHidden(false)
    applyVisibility(animated: false)
  }

  private func setHidden(_ hidden: Bool) {
    model.setHidden(hidden)
    applyVisibility(animated: true)
    if hidden {
      rehideTimer?.invalidate()
    } else {
      scheduleRehideIfNeeded()
    }
  }

  private func applyVisibility(animated: Bool) {
    let update = {
      self.boundaryItem.length =
        self.model.isHidden
        ? Self.expandedLength
        : NSStatusItem.variableLength
      self.boundaryItem.button?.alphaValue = self.model.isHidden ? 0.82 : 1
      self.controlItem.button?.contentTintColor =
        self.model.isHidden ? nil : NSColor.controlAccentColor
    }

    if animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.18
        context.timingFunction = CAMediaTimingFunction(name: .easeOut)
        update()
      }
    } else {
      update()
    }
  }

  private func scheduleRehideIfNeeded() {
    rehideTimer?.invalidate()
    let policy = model.rehidePolicy
    guard !model.isHidden, policy.shouldSchedule else { return }
    rehideTimer = Timer.scheduledTimer(withTimeInterval: policy.delay, repeats: false) {
      [weak self] _ in
      Task { @MainActor in self?.setHidden(true) }
    }
  }

  private func rescheduleRehideIfNeeded() {
    guard !model.isHidden else { return }
    scheduleRehideIfNeeded()
  }

  private func showContextMenu() {
    let menu = NSMenu()
    let toggle = NSMenuItem(
      title: (model.isHidden ? "Show Hidden Items" : "Hide Selected Items")
        + " (\(model.shortcutDisplay))",
      action: #selector(contextToggle(_:)),
      keyEquivalent: ""
    )
    toggle.target = self
    menu.addItem(toggle)
    menu.addItem(.separator())

    let guide = NSMenuItem(
      title: "Arrangement Guide", action: #selector(openGuide(_:)), keyEquivalent: "")
    guide.target = self
    menu.addItem(guide)

    let settings = NSMenuItem(
      title: "Settings…", action: #selector(openSettings(_:)), keyEquivalent: ",")
    settings.target = self
    menu.addItem(settings)
    menu.addItem(.separator())

    let quit = NSMenuItem(title: "Quit MenuFold", action: #selector(quit(_:)), keyEquivalent: "q")
    quit.target = self
    menu.addItem(quit)

    controlItem.menu = menu
    controlItem.button?.performClick(nil)
    controlItem.menu = nil
  }

  @objc private func contextToggle(_ sender: Any?) { toggleHiddenItems() }
  @objc private func openGuide(_ sender: Any?) { windows.showOnboarding() }
  @objc private func openSettings(_ sender: Any?) { windows.showSettings() }
  @objc private func quit(_ sender: Any?) { NSApp.terminate(nil) }

  func revealBeforeQuitting() {
    rehideTimer?.invalidate()
    boundaryItem.length = NSStatusItem.variableLength
  }
}

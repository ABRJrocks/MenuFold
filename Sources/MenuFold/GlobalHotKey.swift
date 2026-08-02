@preconcurrency import Carbon
import Foundation

@MainActor
final class GlobalHotKey {
  private var hotKeyRef: EventHotKeyRef?
  private var handlerRef: EventHandlerRef?
  private let action: () -> Void

  init?(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
    self.action = action

    var eventType = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    let opaqueSelf = Unmanaged.passUnretained(self).toOpaque()
    let status = InstallEventHandler(
      GetApplicationEventTarget(),
      { _, event, userData in
        guard let event, let userData else { return OSStatus(eventNotHandledErr) }
        var eventID = EventHotKeyID()
        let readStatus = GetEventParameter(
          event,
          EventParamName(kEventParamDirectObject),
          EventParamType(typeEventHotKeyID),
          nil,
          MemoryLayout<EventHotKeyID>.size,
          nil,
          &eventID
        )
        guard readStatus == noErr, eventID.id == 1 else { return OSStatus(eventNotHandledErr) }
        let owner = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
        MainActor.assumeIsolated { owner.action() }
        return noErr
      },
      1,
      &eventType,
      opaqueSelf,
      &handlerRef
    )

    guard status == noErr else { return nil }

    let hotKeyID = EventHotKeyID(signature: OSType(0x4D_46_4C_44), id: 1)  // MFLD
    guard
      RegisterEventHotKey(
        keyCode,
        modifiers,
        hotKeyID,
        GetApplicationEventTarget(),
        0,
        &hotKeyRef
      ) == noErr
    else {
      if let handlerRef { RemoveEventHandler(handlerRef) }
      return nil
    }
  }

  func invalidate() {
    if let hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
      self.hotKeyRef = nil
    }
    if let handlerRef {
      RemoveEventHandler(handlerRef)
      self.handlerRef = nil
    }
  }
}

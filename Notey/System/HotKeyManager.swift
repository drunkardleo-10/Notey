import Carbon
import AppKit

@MainActor
final class HotKeyManager {

    private var registeredHotKeys: [EventHotKeyRef] = []
    private var handlers: Dictionary<UInt32, () -> Void> = [:]
    private var nextId: UInt32 = 1

    private static let hotKeySignature: UInt32 = 0x4E544559

    init() {
        installEventHandler()
    }

    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        let id = nextId
        nextId += 1

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.hotKeySignature, id: id)

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let ref = hotKeyRef {
            registeredHotKeys.append(ref)
            handlers[id] = handler
        } else {
            print("[HotKeyManager] Failed to register hotkey. Status: \(status)")
        }
    }

    func registerArchiveToggle(handler: @escaping () -> Void) {
        register(
            keyCode: UInt32(kVK_ANSI_L),
            modifiers: UInt32(optionKey | cmdKey),
            handler: handler
        )
    }

    func unregisterAll() {
        for ref in registeredHotKeys {
            UnregisterEventHotKey(ref)
        }
        registeredHotKeys.removeAll()
        handlers.removeAll()
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr else { return OSStatus(eventNotHandledErr) }

                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

                DispatchQueue.main.async {
                    manager.handlers[hotKeyID.id]?()
                }

                return noErr
            },
            1,
            &eventType,
            selfPtr,
            nil
        )
    }
}

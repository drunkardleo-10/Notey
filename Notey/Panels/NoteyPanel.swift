import AppKit

class NoteyPanel: NSPanel {

    var canBecomeKeyOverride: Bool = true
    var canBecomeMainOverride: Bool = false

    override var canBecomeKey: Bool {
        canBecomeKeyOverride
    }

    override var canBecomeMain: Bool {
        canBecomeMainOverride
    }

    func configureAsEdgeDeck() {
        canBecomeKeyOverride = false
        canBecomeMainOverride = false

        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        level = .statusBar                      
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        acceptsMouseMovedEvents = true
        ignoresMouseEvents = false
        hidesOnDeactivate = false

        styleMask = [.borderless, .nonactivatingPanel]

        orderFrontRegardless()
    }

    func configureAsEditor() {
        canBecomeKeyOverride = true
        canBecomeMainOverride = true

        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovable = true
        hidesOnDeactivate = false

        styleMask = [.borderless]
    }

    func configureAsModal() {
        canBecomeKeyOverride = true

        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]

        level = .statusBar
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovable = true
        hidesOnDeactivate = false

        styleMask = [.borderless, .nonactivatingPanel]

        orderFrontRegardless()
    }

    func setPinnedLevel(_ pinned: Bool) {
        level = .statusBar 
        orderFrontRegardless()
    }
}

import SwiftUI

final class NoteyHostingView<Content: View>: NSHostingView<Content> {
    @MainActor required init(rootView: Content) {
        super.init(rootView: rootView)
        sizingOptions = []
    }

    @MainActor required dynamic init?(coder: NSCoder) {
        super.init(coder: coder)
        sizingOptions = []
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}

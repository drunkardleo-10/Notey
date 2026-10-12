import AppKit
import SwiftUI

@MainActor
final class OnboardingPanelController: NSObject {

    let panel: NoteyPanel

    private var hostingView: NoteyHostingView<OnboardingView>?

    var onComplete: (() -> Void)?

    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete

        let frame = ScreenUtilities.centeredFrame(
            width: NoteyLayout.onboardingWidth,
            height: NoteyLayout.onboardingHeight
        ) ?? CGRect(x: 200, y: 200, width: NoteyLayout.onboardingWidth, height: NoteyLayout.onboardingHeight)

        panel = NoteyPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init()

        panel.configureAsModal()
    }

    func show() {
        let onboardingView = OnboardingView(
            onComplete: { [weak self] in self?.hide() }
        )

        let hosting = NoteyHostingView(rootView: onboardingView)
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hosting
        self.hostingView = hosting

        if let frame = ScreenUtilities.centeredFrame(
            width: NoteyLayout.onboardingWidth,
            height: NoteyLayout.onboardingHeight
        ) {
            panel.setFrame(frame, display: true)
        }

        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
        onComplete?()
    }

    static var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboardingV2")
    }
}

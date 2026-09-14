import AppKit
import SwiftUI

@MainActor
final class ColorPanelPresenter: NSObject {
    static let shared = ColorPanelPresenter()

    private var onColorChange: ((NoteColor) -> Void)?
    private var isInternalUpdate: Bool = false

    override private init() {
        super.init()
    }

    func show(color: NoteColor, onColorChange: @escaping (NoteColor) -> Void) {
        self.onColorChange = onColorChange

        let panel = NSColorPanel.shared
        panel.showsAlpha = false
        panel.isContinuous = true
        panel.level = .popUpMenu

        isInternalUpdate = true
        panel.color = color.nsColor
        isInternalUpdate = false

        panel.setTarget(self)
        panel.setAction(#selector(colorPanelAction(_:)))

        panel.orderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func updateColorIfVisible(_ color: NoteColor) {
        guard NSColorPanel.sharedColorPanelExists else { return }
        let panel = NSColorPanel.shared
        guard panel.isVisible else { return }

        isInternalUpdate = true
        panel.color = color.nsColor
        isInternalUpdate = false
    }

    func pickFromScreen(onColorChange: @escaping (NoteColor) -> Void) {
        self.onColorChange = onColorChange
        let sampler = NSColorSampler()
        sampler.show { [weak self] selectedColor in
            Task { @MainActor in
                guard let self, let selectedColor else { return }
                let hex = selectedColor.hexString
                let noteColor = NoteColor.custom(hex)
                self.updateColorIfVisible(noteColor)
                self.onColorChange?(noteColor)
            }
        }
    }

    func hide() {
        if NSColorPanel.sharedColorPanelExists {
            NSColorPanel.shared.orderOut(nil)
        }
        onColorChange = nil
    }

    @objc private func colorPanelAction(_ sender: NSColorPanel) {
        guard !isInternalUpdate else { return }
        let hex = sender.color.hexString
        let noteColor = NoteColor.custom(hex)
        onColorChange?(noteColor)
    }
}

import SwiftUI
import AppKit
import CoreText

extension Color {
    static let noteYellow   = Color(hex: 0xFDC844)
    static let noteCoral    = Color(hex: 0xFF8A80)
    static let noteMint     = Color(hex: 0x80E5D0)
    static let noteBlue     = Color(hex: 0x82B1FF)
    static let noteLavender = Color(hex: 0xCE93D8)

    static let cream        = Color(hex: 0xF5EFE6)
    static let creamCard    = Color(hex: 0xFAF6EE)
    static let creamHover   = Color(hex: 0xEBE3D7)
    static let tealStart    = Color(hex: 0x3A7377)
    static let tealEnd      = Color(hex: 0x1E3F43)

    static let textPrimary  = Color(hex: 0x2C2622)
    static let textMuted    = Color(hex: 0x8C827A)
    static let textDanger   = Color(hex: 0xD32F2F)

    static let border       = Color(hex: 0x2C2622).opacity(0.12)
    static let borderSubtle = Color(hex: 0x2C2622).opacity(0.06)

    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

extension NSColor {
    static let noteYellow   = NSColor(srgbRed: 0xFD/255, green: 0xC8/255, blue: 0x44/255, alpha: 1)
    static let noteCoral    = NSColor(srgbRed: 0xFF/255, green: 0x8A/255, blue: 0x80/255, alpha: 1)
    static let noteMint     = NSColor(srgbRed: 0x80/255, green: 0xE5/255, blue: 0xD0/255, alpha: 1)
    static let noteBlue     = NSColor(srgbRed: 0x82/255, green: 0xB1/255, blue: 0xFF/255, alpha: 1)
    static let noteLavender = NSColor(srgbRed: 0xCE/255, green: 0x93/255, blue: 0xD8/255, alpha: 1)
    static let cream        = NSColor(srgbRed: 0xF5/255, green: 0xEF/255, blue: 0xE6/255, alpha: 1)
}

extension NoteColor {
    var swiftUIColor: Color {
        switch self {
        case .yellow:   return .noteYellow
        case .coral:    return .noteCoral
        case .mint:     return .noteMint
        case .blue:     return .noteBlue
        case .lavender: return .noteLavender
        }
    }

    var nsColor: NSColor {
        switch self {
        case .yellow:   return .noteYellow
        case .coral:    return .noteCoral
        case .mint:     return .noteMint
        case .blue:     return .noteBlue
        case .lavender: return .noteLavender
        }
    }

    var hexCode: String {
        switch self {
        case .yellow:   return "#FDC844"
        case .coral:    return "#FF8A80"
        case .mint:     return "#80E5D0"
        case .blue:     return "#82B1FF"
        case .lavender: return "#CE93D8"
        }
    }
}

struct NoteyFonts {
    nonisolated(unsafe) private static var isCaveatRegistered: Bool = false

    static func registerCaveatIfNeeded() {
        guard !isCaveatRegistered else { return }
        isCaveatRegistered = true

        if NSFont(name: "Caveat", size: 16) != nil || NSFont(name: "Caveat-Regular", size: 16) != nil {
            return
        }

        var candidateURLs: [URL] = []

        #if SWIFT_PACKAGE
        if let moduleURL = Bundle.module.url(forResource: "Caveat", withExtension: "ttf") {
            candidateURLs.append(moduleURL)
        }
        #endif

        if let mainURL = Bundle.main.url(forResource: "Caveat", withExtension: "ttf") {
            candidateURLs.append(mainURL)
        }

        let sourceDirURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/Caveat.ttf")
        candidateURLs.append(sourceDirURL)

        candidateURLs.append(URL(fileURLWithPath: "/Users/leo/Desktop/Notey/Notey/Resources/Caveat.ttf"))

        for url in candidateURLs {
            if FileManager.default.fileExists(atPath: url.path) {
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                    return
                }
            }
        }
    }

    static func ui(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func note(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        registerCaveatIfNeeded()
        return .custom("Caveat", size: size)
    }

    static func noteNSFont(size: CGFloat, weight: NSFont.Weight = .regular, italic: Bool = false) -> NSFont {
        registerCaveatIfNeeded()

        if let base = NSFont(name: "Caveat-Regular", size: size) ?? NSFont(name: "Caveat", size: size) {
            var f = base
            if weight >= .bold {
                f = NSFontManager.shared.convert(f, toHaveTrait: .boldFontMask)
            }
            if italic {
                f = NSFontManager.shared.convert(f, toHaveTrait: .italicFontMask)
            }
            return f
        }

        var font = NSFont.systemFont(ofSize: size, weight: weight)
        if let desc = font.fontDescriptor.withDesign(.rounded) {
            font = NSFont(descriptor: desc, size: size) ?? font
        }
        if italic {
            font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        }
        return font
    }
}

extension Animation {
    static let noteySpring = Animation.spring(response: 0.26, dampingFraction: 0.82)
    static let noteyQuick  = Animation.spring(response: 0.18, dampingFraction: 0.78)
    static let noteyPop    = Animation.spring(response: 0.24, dampingFraction: 0.7)
}

enum NoteyLayout {
    static let deckIdleWidth: CGFloat = 14
    static let deckHoverWidth: CGFloat = 240
    static let deckHeightRatio: CGFloat = 0.85

    static let tabIdleWidth: CGFloat = 6
    static let tabIdleHeight: CGFloat = 16
    static let tabIdlePillWidth: CGFloat = 6
    static let tabIdlePillHeight: CGFloat = 16
    static let tabPeekingWidth: CGFloat = 36
    static let tabPeekingBottomWidth: CGFloat = 36
    static let tabPeekingHeight: CGFloat = 74
    static let tabStepHeight: CGFloat = 74
    static let tabExpandedWidth: CGFloat = 195
    static let tabExpandedHeight: CGFloat = 150

    static let editorWidth: CGFloat = 380
    static let editorHeight: CGFloat = 400
    static let editorCornerRadius: CGFloat = 20

    static let archiveWidth: CGFloat = 620
    static let archiveHeight: CGFloat = 440

    static let onboardingWidth: CGFloat = 740
    static let onboardingHeight: CGFloat = 460
}

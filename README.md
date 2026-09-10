# Notey

A minimal, native macOS edge-docked sticky notes application written in Swift and SwiftUI.

Designed to live subtly on the edge of your desktop, Notey provides instant access to quick notes, scratchpads, and checklists without disrupting your focus or cluttering your workspace.

---

## Highlights

### Edge-Docked Architecture
- **Discreet Idle Presence**: Sleek 6px pill tabs peek out from the right screen boundary, staying out of sight during focused work.
- **Proximity-Aware Deck**: Hovering directly near the tabs smoothly fans them out into an overlapping card stack.
- **Single-Note Expansion**: Moving the cursor over any tab expands that note with an authentic card preview while collapsing any others.

### Tactile Card Deck Interface
- **Cascading Stack**: Vertical tab handles display the note's category or label ("NOTE") with a perforation line and layered depth.
- **Handwriting Typography**: Plain text notes render in `Chalkboard SE` for an authentic sticky-note aesthetic.
- **Color Coding**: Visual palette with Yellow, Coral, Mint, Blue, and Lavender tones.

### Focused Writing & Checklists
- **Markdown Scratchpad**: Multi-line plain text editing with full word wrapping, undo/redo, and native AppKit first-responder integration.
- **Interactive Checklists**: Rapid task tracking with intuitive keyboard controls—press Enter to create items, Backspace to merge/delete, and arrow keys to navigate.
- **Autosave & Local Storage**: Changes persist immediately to disk via local atomic JSON storage with zero telemetry or network latency.

### Native macOS Integration
- **True Desktop Panels**: Powered by `NSPanel` for smooth floating desktop window levels, non-activating focus behaviors, and clean animations.
- **Global Hotkeys**: Quick-access shortcuts for instant capture and archive management.
- **Menu Bar Status Item**: Control panel state, create notes, and toggle window modes from the system status bar.

---

## Architecture & Tech Stack

- **Language**: Swift 6 (Strict Concurrency ready)
- **UI Framework**: SwiftUI + AppKit (`NSPanel`, `NSTrackingArea`, `NSTextView`, `NSHostingView`)
- **Storage**: Local atomic JSON store (`FileManager` + `JSONEncoder`/`JSONDecoder`)
- **Platforms**: macOS 14.0+ (Apple Silicon & Intel)
- **Build Tooling**: Swift Package Manager (`Package.swift`) & Xcode (`project.yml` / `Notey.xcodeproj`)

---

## Getting Started

### Prerequisites
- macOS 14.0 (Sonoma) or newer
- Xcode 15+ / Swift 5.9+

### Build & Test via Terminal

```bash
# Build the project
swift build

# Run unit tests (14 passing tests)
swift test
```

### Open in Xcode

```bash
open Notey.xcodeproj
```
Press `Cmd + R` to build and launch Notey.

---

## License

MIT License.

# Notey

A minimal macOS application to keep notes and pin it as a dock.

Designed to live subtly on the edge of your desktop, Notey provides instant access to quick notes, scratchpads, and checklists without disrupting your focus or cluttering your workspace.

## Highlights

### Edge-Docked Architecture
Notey attaches directly to the screen boundary. It stays concealed out of sight during focus work and expands effortlessly whenever you move your cursor to the edge or invoke the global shortcut.

### Card Deck Interface
Move away from traditional folder trees and complex sidebars. Notey arranges notes in a visually tactile card stack, allowing quick switching, color-coded hierarchy, and effortless context recovery.

### Focused Writing & Checklists
- Markdown Scratchpad: A clean editor supporting rich formatting, shortcuts, and fluid typing.
- Interactive Checklists: Dedicated task tracking for managing quick daily to-dos.
- Visual Categorization: Color-code cards to separate thoughts by project, priority, or topic.

### Built Exclusively for macOS
- Native Panel Integration: Powered by macOS NSPanel APIs for true floating desktop behavior, non-activating focus modes, and vibrant backdrop blur.
- Resource Efficient: Engineered with a Rust runtime to maintain minimal memory footprint and zero lag.
- Privacy & Local Storage: Notes remain stored locally on disk for zero-latency loading and absolute privacy.

## Architecture & Core Tech

- Desktop Engine: Tauri v2 (Rust runtime core)
- Application UI: SvelteKit, TypeScript
- Native Layer: Objective-C & Cocoa NSPanel integration
- Storage: High-performance local JSON storage layer


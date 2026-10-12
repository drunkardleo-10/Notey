import SwiftUI

struct OnboardingStageView: View {

    let step: Int

    var body: some View {
        ZStack {
            stageBackground

            Group {
                switch step {
                case 1:
                    Step1EdgeSimulation()
                case 2:
                    Step2FanSimulation()
                case 3:
                    Step3EditorSimulation()
                case 4:
                    Step4ArchiveSimulation()
                default:
                    EmptyView()
                }
            }
            .id(step)
            .transition(.blurReplace.combined(with: .scale(0.94)))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var stageBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let tint = LinearGradient(
            colors: [Color(hex: 0x4A9EA8).opacity(0.55), Color(hex: 0x1D555D).opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        if #available(macOS 26.0, *) {
            shape
                .fill(tint)
                .glassEffect(.regular, in: shape)
        } else {
            shape
                .fill(tint)
                .overlay(shape.strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
        }
    }
}

private struct StageHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(NoteyFonts.ui(size: 11, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct DemoTab: Identifiable {
    let id: Int
    let label: String
    let color: Color
    let title: String
}

private let demoTabs: [DemoTab] = [
    DemoTab(id: 0, label: "IDEAS", color: .noteYellow, title: "Ideas"),
    DemoTab(id: 1, label: "TASKS", color: .noteCoral, title: "Tasks"),
    DemoTab(id: 2, label: "BOOKS", color: .noteMint, title: "Books"),
    DemoTab(id: 3, label: "GYM", color: .noteBlue, title: "Gym")
]

private struct Step1EdgeSimulation: View {
    @State private var hovered: Int? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HStack(spacing: 0) {
                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    ForEach(demoTabs) { tab in
                        PeekingTab(tab: tab, isHovered: hovered == tab.id)
                            .onHover { inside in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                                    hovered = inside ? tab.id : (hovered == tab.id ? nil : hovered)
                                }
                            }
                    }
                }
            }
            .frame(maxHeight: .infinity)

            StageHint(text: "Hover a tab")
                .padding(14)
        }
    }
}

private struct PeekingTab: View {
    let tab: DemoTab
    let isHovered: Bool

    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 6,
            bottomLeadingRadius: 6,
            bottomTrailingRadius: 0,
            topTrailingRadius: 0
        )
        .fill(tab.color)
        .frame(width: isHovered ? 88 : 12, height: 44)
        .overlay(alignment: .leading) {
            if isHovered {
                Text(tab.label)
                    .font(NoteyFonts.ui(size: 10, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(Color(hex: 0x2C2622).opacity(0.75))
                    .padding(.leading, 12)
                    .transition(.opacity)
            }
        }
        .shadow(color: Color.black.opacity(0.28), radius: 3, x: -2, y: 1)
        .contentShape(Rectangle())
    }
}

private struct FanSpec {
    let color: Color
    let title: String
    let text: String
    let rotation: Double
    let x: CGFloat
    let y: CGFloat
}

private let fanSpecs: [FanSpec] = [
    FanSpec(color: .noteYellow, title: "Getting started", text: "Hover to fan your deck of notes", rotation: -9, x: -34, y: -12),
    FanSpec(color: .noteMint, title: "Tasks", text: "No focus stealing", rotation: 9, x: 34, y: 12),
    FanSpec(color: .noteCoral, title: "Ideas", text: "Always on top across all Spaces", rotation: 0, x: 0, y: 0)
]

private struct Step2FanSimulation: View {
    @State private var fanned = false
    @State private var lifted: Int? = nil

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Spacer()
                VStack(spacing: 6) {
                    ForEach(demoTabs) { tab in
                        UnevenRoundedRectangle(
                            topLeadingRadius: 4,
                            bottomLeadingRadius: 4,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        )
                        .fill(tab.color.opacity(fanned ? 0.35 : 1))
                        .frame(width: 12, height: 44)
                    }
                }
            }

            ZStack {
                ForEach(Array(fanSpecs.enumerated()), id: \.offset) { index, spec in
                    FannedDemoCard(spec: spec)
                        .scaleEffect(lifted == index ? 1.07 : 1)
                        .rotationEffect(.degrees(fanned ? spec.rotation : 0))
                        .offset(
                            x: fanned ? spec.x : 130,
                            y: fanned ? spec.y + (lifted == index ? -8 : 0) : 0
                        )
                        .opacity(fanned ? 1 : 0)
                        .zIndex(lifted == index ? 10 : Double(index))
                        .onHover { inside in
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                                lifted = inside ? index : (lifted == index ? nil : lifted)
                            }
                        }
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05),
                            value: fanned
                        )
                }
            }

            HStack {
                Spacer()
                Color.clear
                    .frame(width: 70)
                    .contentShape(Rectangle())
                    .onHover { inside in
                        if inside {
                            fanned = true
                        }
                    }
            }

            VStack {
                Spacer()
                HStack {
                    StageHint(text: fanned ? "Hover a note" : "Move to the right edge")
                        .padding(14)
                    Spacer()
                }
            }
        }
    }
}

private struct FannedDemoCard: View {
    let spec: FanSpec

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(spec.title)
                .font(NoteyFonts.ui(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: 0x2C2622))

            Text(spec.text)
                .font(NoteyFonts.note(size: 11))
                .foregroundStyle(Color(hex: 0x2C2622).opacity(0.85))
                .lineLimit(2)
        }
        .padding(10)
        .frame(width: 155, height: 105, alignment: .topLeading)
        .background(spec.color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.24), radius: 10, x: -2, y: 5)
    }
}

private struct Step3EditorSimulation: View {
    @State private var text = "Cut the onboarding modal, ship search first."
    @State private var color: Color = .noteYellow
    @State private var saved = true
    @State private var saveTask: Task<Void, Never>? = nil
    @FocusState private var focused: Bool

    private let palette: [Color] = [.noteYellow, .noteCoral, .noteMint, .noteBlue, .noteLavender]

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Spacer()
                VStack(spacing: 8) {
                    BackgroundTabLabel(text: "SPRINT", color: Color(hex: 0x5D8A7E))
                    BackgroundTabLabel(text: "BOOKS", color: Color(hex: 0x467576))
                    BackgroundTabLabel(text: "GYM", color: Color(hex: 0x366367))
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: 0x2C2622).opacity(0.35))
                        .frame(width: 5, height: 5)

                    Text("Sprint 24")
                        .font(NoteyFonts.ui(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: 0x2C2622))

                    Spacer()

                    Text(saved ? "Saved" : "Saving…")
                        .font(NoteyFonts.ui(size: 10, weight: .regular))
                        .foregroundStyle(Color(hex: 0x2C2622).opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Rectangle()
                    .fill(Color(hex: 0x2C2622).opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 10)

                TextField("Type something…", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($focused)
                    .font(NoteyFonts.note(size: 13.5))
                    .foregroundStyle(Color(hex: 0x2C2622))
                    .lineSpacing(2)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .onChange(of: text) { _, _ in
                        markSaving()
                    }

                Spacer(minLength: 0)

                HStack(spacing: 7) {
                    ForEach(Array(palette.enumerated()), id: \.offset) { _, swatch in
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                color = swatch
                            }
                            markSaving()
                        } label: {
                            Circle()
                                .fill(swatch)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: 0x2C2622).opacity(0.75), lineWidth: 1.5)
                                        .frame(width: 18, height: 18)
                                        .opacity(swatch == color ? 1 : 0)
                                )
                                .frame(width: 20, height: 20)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
            .frame(width: 215, height: 205)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.28), radius: 16, y: 8)

            VStack {
                Spacer()
                HStack {
                    StageHint(text: "Type, then pick a color")
                        .padding(14)
                    Spacer()
                }
            }
        }
        .onAppear {
            focused = true
        }
    }

    private func markSaving() {
        saved = false
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            saved = true
        }
    }
}

private struct BackgroundTabLabel: View {
    let text: String
    let color: Color

    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 6,
            bottomLeadingRadius: 6,
            bottomTrailingRadius: 0,
            topTrailingRadius: 0
        )
        .fill(color.opacity(0.65))
        .frame(width: 18, height: 60)
        .overlay(
            Text(text)
                .font(NoteyFonts.ui(size: 8, weight: .heavy))
                .tracking(1.0)
                .foregroundStyle(Color.black.opacity(0.4))
                .rotationEffect(.degrees(90))
                .fixedSize()
        )
    }
}

private struct ArchiveEntry: Identifiable {
    let id: Int
    let title: String
    let text: String
    let color: Color
}

private let archiveEntries: [ArchiveEntry] = [
    ArchiveEntry(id: 0, title: "Q2 retro", text: "Velocity was fine, review load was not. Two people carried most reviews. Rotate weekly.", color: .noteYellow),
    ArchiveEntry(id: 1, title: "Lisbon", text: "Book the tram tour. Pastéis de Belém before noon.", color: .noteCoral),
    ArchiveEntry(id: 2, title: "Sourdough", text: "Feed the starter, 70% hydration, bake at 240°.", color: .noteMint),
    ArchiveEntry(id: 3, title: "Interview", text: "Ask about on-call rotation and review culture.", color: .noteBlue),
    ArchiveEntry(id: 4, title: "Reading", text: "Finish chapter 6, then the paper on CRDTs.", color: .noteLavender)
]

private struct Step4ArchiveSimulation: View {
    @State private var entries = archiveEntries
    @State private var selected: Int = 0
    @State private var query = ""
    @State private var restored: [String] = []

    private var filtered: [ArchiveEntry] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return entries }
        return entries.filter {
            $0.title.lowercased().contains(q) || $0.text.lowercased().contains(q)
        }
    }

    private var current: ArchiveEntry? {
        filtered.first(where: { $0.id == selected }) ?? filtered.first
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Spacer()
                VStack(spacing: 8) {
                    BackgroundTabLabel(text: "SPRINT", color: Color(hex: 0x5D8A7E).opacity(0.4))
                    BackgroundTabLabel(text: "BOOKS", color: Color(hex: 0x467576).opacity(0.4))
                    BackgroundTabLabel(text: "GYM", color: Color(hex: 0x366367).opacity(0.4))
                }
            }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color(hex: 0x2C2622).opacity(0.5))

                        TextField("Search", text: $query)
                            .textFieldStyle(.plain)
                            .font(NoteyFonts.ui(size: 9.5))
                            .foregroundStyle(Color(hex: 0x2C2622))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0x2C2622).opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.bottom, 3)

                    ForEach(filtered) { entry in
                        ArchiveDemoItem(
                            title: entry.title,
                            color: entry.color,
                            isSelected: entry.id == current?.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selected = entry.id
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(8)
                .frame(width: 115)

                Rectangle()
                    .fill(Color(hex: 0x2C2622).opacity(0.08))
                    .frame(width: 1)

                VStack(alignment: .leading, spacing: 6) {
                    if let entry = current {
                        Text(entry.title)
                            .font(NoteyFonts.ui(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: 0x2C2622))

                        Text(entry.text)
                            .font(NoteyFonts.note(size: 10.5))
                            .foregroundStyle(Color(hex: 0x2C2622).opacity(0.9))
                            .lineSpacing(3)

                        Spacer(minLength: 0)

                        Button {
                            restore(entry)
                        } label: {
                            Text("Restore to deck")
                                .font(NoteyFonts.ui(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: 0x2C2622))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(hex: 0x2C2622).opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("Nothing found")
                            .font(NoteyFonts.ui(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: 0x2C2622).opacity(0.6))
                        Spacer(minLength: 0)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(current?.color ?? Color.white.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(8)
            }
            .frame(width: 335, height: 225)
            .background(Color(hex: 0xFAF7F0))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: 0x2C2622).opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.32), radius: 18, y: 8)

            VStack {
                Spacer()
                HStack {
                    StageHint(
                        text: restored.isEmpty
                            ? "Search, select, restore"
                            : "Restored \(restored.count) to the deck"
                    )
                    .padding(14)
                    Spacer()
                }
            }
        }
    }

    private func restore(_ entry: ArchiveEntry) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            entries.removeAll { $0.id == entry.id }
            restored.append(entry.title)
            if let next = filtered.first {
                selected = next.id
            }
        }
    }
}

private struct ArchiveDemoItem: View {
    let title: String
    let color: Color
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(color)
                .frame(width: 3, height: 12)

            Text(title)
                .font(NoteyFonts.ui(size: 10.5, weight: isSelected ? .bold : .regular))
                .foregroundStyle(Color(hex: 0x2C2622))

            Rectangle()
                .fill(Color(hex: 0x2C2622).opacity(0.08))
                .frame(height: 1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(isSelected ? Color(hex: 0xDDD7CC) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

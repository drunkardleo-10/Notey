import SwiftUI

struct OnboardingStageView: View {

    let step: Int

    var body: some View {
        ZStack {
            
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x4A9EA8),
                            Color(hex: 0x1D555D)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

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
            .transition(
                .asymmetric(
                    insertion: .opacity.combined(with: .offset(x: 35)),
                    removal: .opacity.combined(with: .offset(x: -35))
                )
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.15), radius: 8, y: 3)

    }
}

private struct Step1EdgeSimulation: View {
    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            VStack(spacing: 6) {
                PeekingTab(color: Color.noteYellow)
                PeekingTab(color: Color.noteCoral)
                PeekingTab(color: Color.noteMint)
                PeekingTab(color: Color.noteBlue)
            }
        }
    }
}

private struct PeekingTab: View {
    let color: Color

    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 4,
            bottomLeadingRadius: 4,
            bottomTrailingRadius: 0,
            topTrailingRadius: 0
        )
        .fill(color)
        .frame(width: 12, height: 44)
        .shadow(color: Color.black.opacity(0.28), radius: 3, x: -2, y: 1)
    }
}

private struct Step2FanSimulation: View {
    var body: some View {
        ZStack {
            
            HStack(spacing: 0) {
                Spacer()
                VStack(spacing: 6) {
                    PeekingTab(color: Color.noteYellow.opacity(0.5))
                    PeekingTab(color: Color.noteCoral.opacity(0.5))
                    PeekingTab(color: Color.noteMint.opacity(0.5))
                    PeekingTab(color: Color.noteBlue.opacity(0.5))
                }
            }

            ZStack {
                
                FannedDemoCard(
                    color: Color.noteYellow,
                    title: "Getting started",
                    noteBody: "Hover to fan your deck of notes",
                    rotation: -9,
                    xOffset: -34,
                    yOffset: -12
                )

                FannedDemoCard(
                    color: Color.noteMint,
                    title: "Tasks",
                    noteBody: "No focus stealing",
                    rotation: 9,
                    xOffset: 34,
                    yOffset: 12
                )

                FannedDemoCard(
                    color: Color.noteCoral,
                    title: "Ideas",
                    noteBody: "Always on top across all Spaces",
                    rotation: 0,
                    xOffset: 0,
                    yOffset: 0
                )
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    MouseCursorView()
                        .padding(.trailing, 75)
                        .padding(.bottom, 60)
                }
            }
        }
    }
}

private struct FannedDemoCard: View {
    let color: Color
    let title: String
    let noteBody: String
    let rotation: Double
    let xOffset: CGFloat
    let yOffset: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(NoteyFonts.ui(size: 11, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Text(noteBody)
                .font(NoteyFonts.note(size: 11))
                .foregroundStyle(Color.textPrimary.opacity(0.85))
                .lineLimit(2)
        }
        .padding(10)
        .frame(width: 155, height: 105, alignment: .topLeading)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.24), radius: 10, x: -2, y: 5)
        .rotationEffect(.degrees(rotation))
        .offset(x: xOffset, y: yOffset)
    }
}

private struct Step3EditorSimulation: View {
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
                        .fill(Color.textPrimary.opacity(0.35))
                        .frame(width: 5, height: 5)

                    Text("Sprint 24")
                        .font(NoteyFonts.ui(size: 12, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    Text("Saved")
                        .font(NoteyFonts.ui(size: 10, weight: .regular))
                        .foregroundStyle(Color.textPrimary.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Rectangle()
                    .fill(Color.textPrimary.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 10)

                HStack(alignment: .top, spacing: 0) {
                    Text("Cut the onboarding modal, ship search first. ")
                        .font(NoteyFonts.note(size: 13.5))
                        .foregroundStyle(Color.textPrimary)
                        .lineSpacing(2)

                    Rectangle()
                        .fill(Color.textPrimary.opacity(0.7))
                        .frame(width: 1.5, height: 16)
                        .offset(y: 2)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)

                Spacer(minLength: 0)

                HStack(spacing: 7) {
                    
                    Circle()
                        .fill(Color.noteYellow)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.textPrimary.opacity(0.75), lineWidth: 1.5)
                                .frame(width: 18, height: 18)
                        )
                        .padding(.leading, 2)

                    Circle()
                        .fill(Color.noteCoral)
                        .frame(width: 14, height: 14)

                    Circle()
                        .fill(Color.noteMint)
                        .frame(width: 14, height: 14)

                    Circle()
                        .fill(Color.noteBlue)
                        .frame(width: 14, height: 14)

                    Circle()
                        .fill(Color.noteLavender)
                        .frame(width: 14, height: 14)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .frame(width: 215, height: 205)
            .background(Color.noteYellow)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.28), radius: 16, y: 8)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    MouseCursorView()
                        .padding(.trailing, 65)
                        .padding(.bottom, 65)
                }
            }
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

private struct Step4ArchiveSimulation: View {
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
                            .foregroundStyle(Color.textMuted)

                        Text("Search")
                            .font(NoteyFonts.ui(size: 9.5))
                            .foregroundStyle(Color.textMuted)

                        Spacer()
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.textPrimary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.bottom, 3)

                    ArchiveDemoItem(title: "Q2 retro", color: Color.noteYellow, isSelected: true)
                    ArchiveDemoItem(title: "Lisbon", color: Color.noteCoral, isSelected: false)
                    ArchiveDemoItem(title: "Sourdough", color: Color.noteMint, isSelected: false)
                    ArchiveDemoItem(title: "Interview", color: Color.noteBlue, isSelected: false)
                    ArchiveDemoItem(title: "Reading", color: Color.noteLavender, isSelected: false)

                    Spacer(minLength: 0)
                }
                .padding(8)
                .frame(width: 115)

                Rectangle()
                    .fill(Color.textPrimary.opacity(0.08))
                    .frame(width: 1)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Q2 retro notes")
                        .font(NoteyFonts.ui(size: 11, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text("Velocity was fine, review load was not. Two people carried most reviews — rotate weekly.")
                        .font(NoteyFonts.note(size: 10.5))
                        .foregroundStyle(Color.textPrimary.opacity(0.9))
                        .lineSpacing(3)

                    Spacer(minLength: 0)
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.noteYellow)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(8)
            }
            .frame(width: 335, height: 225)
            .background(Color(hex: 0xFAF7F0))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.textPrimary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.32), radius: 18, y: 8)

            VStack {
                Spacer()
                HStack {
                    MouseCursorView()
                        .padding(.leading, 120)
                        .padding(.bottom, 125)
                    Spacer()
                }
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
                .foregroundStyle(Color.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3.5)
        .background(
            isSelected
                ? Color(hex: 0xDDD7CC)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct MouseCursorView: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 17))
            path.addLine(to: CGPoint(x: 4.5, y: 13))
            path.addLine(to: CGPoint(x: 8.5, y: 21))
            path.addLine(to: CGPoint(x: 11.5, y: 19.5))
            path.addLine(to: CGPoint(x: 7.5, y: 12))
            path.addLine(to: CGPoint(x: 13, y: 12))
            path.closeSubpath()
        }
        .fill(Color.white)
        .overlay(
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 17))
                path.addLine(to: CGPoint(x: 4.5, y: 13))
                path.addLine(to: CGPoint(x: 8.5, y: 21))
                path.addLine(to: CGPoint(x: 11.5, y: 19.5))
                path.addLine(to: CGPoint(x: 7.5, y: 12))
                path.addLine(to: CGPoint(x: 13, y: 12))
                path.closeSubpath()
            }
            .stroke(Color.black.opacity(0.85), lineWidth: 1.2)
        )
        .frame(width: 14, height: 22)
        .shadow(color: Color.black.opacity(0.25), radius: 2, x: 1, y: 1)
    }
}

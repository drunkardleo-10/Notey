import SwiftUI

struct OnboardingStepInfo {
    let step: Int
    let title: String
    let body: String
    let badgeText: String
    let badgeDesc: String
}

private let onboardingSteps: [OnboardingStepInfo] = [
    OnboardingStepInfo(
        step: 1,
        title: "Your notes wait at\nthe edge",
        body: "A thin strip on the right edge of your screen is all you see. Each stripe is a note, in its own color, so you can tell what is there at a glance.",
        badgeText: "Nothing to click",
        badgeDesc: "the pill sits out of the way until you need it"
    ),
    OnboardingStepInfo(
        step: 2,
        title: "Hover the edge to\nfan",
        body: "Moving your cursor to the edge slides the notes out into a fanned stack. Hover any note to inspect its full text without clicking.",
        badgeText: "Hover to fan",
        badgeDesc: "cards lift and expand for preview reading"
    ),
    OnboardingStepInfo(
        step: 3,
        title: "Click a note to\nwrite in it",
        body: "The note grows into an editor in place. Type and it saves as you go — no save button, no window to manage. Pick a color from the row along the bottom.",
        badgeText: "⌥⌘N",
        badgeDesc: "creates a new note from anywhere"
    ),
    OnboardingStepInfo(
        step: 4,
        title: "Archive what you are\ndone with",
        body: "Archived notes leave the deck but are kept. Search the archive by title or by anything written inside a note, then restore it to the deck in one click.",
        badgeText: "⌥⌘L",
        badgeDesc: "opens the archive"
    )
]

struct OnboardingView: View {

    var onComplete: (() -> Void)?

    @State private var currentStep: Int = 1
    @State private var startOnLogin: Bool = true
    @Namespace private var dotNamespace

    private var currentData: OnboardingStepInfo {
        onboardingSteps[currentStep - 1]
    }

    var body: some View {
        HStack(spacing: 0) {
            
            leftPane
                .frame(width: 335)

            OnboardingStageView(step: currentStep)
                .padding(.top, 14)
                .padding(.trailing, 14)
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(
            width: NoteyLayout.onboardingWidth,
            height: NoteyLayout.onboardingHeight
        )
        .background(Color(hex: 0xF7F4EC)) 
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.textPrimary.opacity(0.12), lineWidth: 1)
        )
        .shadow(
            color: Color.textPrimary.opacity(0.3),
            radius: 30,
            y: 12
        )
        .onExitCommand {
            handleComplete()
        }
    }

    private var leftPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            NativeCloseButton(action: { handleComplete() })
                .padding(.top, 20)
                .padding(.bottom, 22)

            ZStack(alignment: .topLeading) {
                stepContentView
                    .id(currentStep)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .offset(x: 28)),
                            removal: .opacity.combined(with: .offset(x: -28))
                        )
                    )
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .clipped()

            Spacer(minLength: 0)

            HStack(alignment: .center) {
                
                HStack(spacing: 6) {
                    ForEach(1...4, id: \.self) { s in
                        ZStack {
                            Capsule()
                                .fill(Color.textPrimary.opacity(0.22))
                                .frame(width: 6, height: 6)

                            if s == currentStep {
                                Capsule()
                                    .fill(Color.textPrimary.opacity(0.72))
                                    .matchedGeometryEffect(id: "activeIndicatorPill", in: dotNamespace)
                                    .frame(width: 22, height: 6)
                            }
                        }
                        .frame(width: s == currentStep ? 22 : 6, height: 6)
                    }
                }
                .animation(.spring(response: 0.38, dampingFraction: 0.8), value: currentStep)

                Spacer()

                if currentStep < 4 {
                    Button(action: { handleComplete() }) {
                        Text("Skip")
                            .font(NoteyFonts.ui(size: 13, weight: .semibold))
                            .foregroundStyle(Color.textMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: {
                    if currentStep < 4 {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                            currentStep += 1
                        }
                    } else {
                        handleComplete()
                    }
                }) {
                    Text(currentStep == 4 ? "Create my first note" : "Continue")
                        .font(NoteyFonts.ui(size: 13, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .padding(.vertical, 9)
                        .padding(.horizontal, currentStep == 4 ? 18 : 20)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.noteYellow)
                                .shadow(
                                    color: Color.noteYellow.opacity(0.4),
                                    radius: 6,
                                    x: 0,
                                    y: 2
                                )
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.bottom, 22)
        }
        .padding(.leading, 28)
        .padding(.trailing, 22)
    }

    private var stepContentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("STEP \(currentStep) OF 4")
                .font(NoteyFonts.ui(size: 11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Color.textMuted)
                .padding(.bottom, 10)

            Text(currentData.title)
                .font(NoteyFonts.ui(size: 24, weight: .heavy))
                .lineSpacing(2)
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 14)

            Text(currentData.body)
                .font(NoteyFonts.ui(size: 13.5))
                .lineSpacing(4)
                .foregroundStyle(Color.textPrimary.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 18)

            HStack(alignment: .center, spacing: 10) {
                Text(currentData.badgeText)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.textPrimary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(currentData.badgeDesc)
                    .font(NoteyFonts.ui(size: 12))
                    .foregroundStyle(Color.textMuted)
                    .lineLimit(2)
            }
            .padding(.bottom, 14)

            if currentStep == 4 {
                Button(action: { startOnLogin.toggle() }) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.textPrimary.opacity(0.35), lineWidth: 1.5)
                                .frame(width: 18, height: 18)

                            if startOnLogin {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.noteYellow)
                                    .frame(width: 12, height: 12)
                            }
                        }

                        Text("Add to Login Items — open automatically at sign-in")
                            .font(NoteyFonts.ui(size: 12))
                            .foregroundStyle(Color.textPrimary.opacity(0.85))
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.textPrimary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }


    private func handleComplete() {
        if startOnLogin {
            try? AutostartManager.enable()
        }

        UserDefaults.standard.set(true, forKey: "hasCompletedOnboardingV2")
        onComplete?()
    }
}


import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "book.fill",
            iconColor: AuroraTheme.auroraTeal,
            title: "Welcome to Aurora Reader",
            subtitle: "Your personal reading companion with a beautiful Northern Lights experience.",
            detail: "Import books in 11+ formats including EPUB, PDF, MOBI, and more."
        ),
        OnboardingPage(
            icon: "sparkles",
            iconColor: AuroraTheme.auroraPurple,
            title: "AI-Powered Reading",
            subtitle: "Get intelligent summaries, character maps, and reading insights.",
            detail: "Optionally connect your Claude API key in Settings to unlock AI features."
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            iconColor: AuroraTheme.auroraGreen,
            title: "Track Your Progress",
            subtitle: "Build streaks, earn achievements, and compare with friends.",
            detail: "Your reading stats are tracked automatically as you read."
        ),
        OnboardingPage(
            icon: "highlighter",
            iconColor: AuroraTheme.auroraWarm,
            title: "Annotate & Discover",
            subtitle: "Highlight, take notes, build vocabulary, and explore a knowledge graph.",
            detail: "Export your annotations and insights anytime."
        ),
    ]

    var body: some View {
        ZStack {
            AuroraTheme.deepSpace.ignoresSafeArea()

            // Aurora background effects
            Circle()
                .fill(AuroraTheme.auroraTeal.opacity(0.08))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -50, y: -300)
                .ignoresSafeArea()
            Circle()
                .fill(AuroraTheme.auroraPurple.opacity(0.06))
                .frame(width: 350, height: 350)
                .blur(radius: 90)
                .offset(x: 100, y: 200)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? AuroraTheme.auroraTeal : AuroraTheme.textTertiary.opacity(0.4))
                            .frame(width: index == currentPage ? 10 : 6, height: index == currentPage ? 10 : 6)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        withAnimation { hasCompletedOnboarding = true }
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AuroraTheme.accentGradient, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)

                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        withAnimation { hasCompletedOnboarding = true }
                    }
                    .font(.subheadline)
                    .foregroundStyle(AuroraTheme.textTertiary)
                    .padding(.top, 12)
                }

                Spacer().frame(height: 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(page.iconColor.opacity(0.06))
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 40))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(page.iconColor)
            }

            Text(page.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(AuroraTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(page.subtitle)
                .font(.body)
                .foregroundStyle(AuroraTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(page.detail)
                .font(.caption)
                .foregroundStyle(AuroraTheme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
}

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let detail: String
}

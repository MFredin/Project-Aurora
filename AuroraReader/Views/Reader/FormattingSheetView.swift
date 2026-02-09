import SwiftUI

/// Sheet for previewing and applying formatting fixes to book chapters
struct FormattingSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formattingService = BookFormattingService.shared

    let chapters: [BookChapter]
    let currentChapterIndex: Int

    @State private var result: FormattingResult?
    @State private var isDeepCleaning = false
    @State private var showPreview = false
    @State private var errorMessage: String?

    private var currentChapter: BookChapter? {
        guard currentChapterIndex < chapters.count else { return nil }
        return chapters[currentChapterIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Current chapter info
                        if let chapter = currentChapter {
                            chapterInfoCard(chapter)
                        }

                        // Quick Clean (rule-based)
                        actionCard(
                            icon: "wand.and.stars",
                            iconColor: AuroraTheme.auroraTeal,
                            title: "Quick Clean",
                            subtitle: "Rule-based fixes: encoding, whitespace, broken paragraphs, stray artifacts",
                            buttonLabel: "Run Quick Clean",
                            isLoading: formattingService.isProcessing && !isDeepCleaning
                        ) {
                            if let chapter = currentChapter {
                                result = formattingService.quickClean(chapter.content)
                                showPreview = true
                            }
                        }

                        // Deep Clean (Claude AI)
                        actionCard(
                            icon: "sparkles",
                            iconColor: AuroraTheme.auroraPurple,
                            title: "AI Deep Clean",
                            subtitle: "Context-aware fixes using Claude AI. Handles complex paragraph reconstruction and heading normalization.",
                            buttonLabel: "Run Deep Clean",
                            isLoading: isDeepCleaning
                        ) {
                            Task { await runDeepClean() }
                        }

                        // Error
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(AuroraTheme.auroraWarm)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(AuroraTheme.auroraWarm)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AuroraTheme.auroraWarm.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        }

                        // Results
                        if let result, showPreview {
                            resultsCard(result)
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Fix Formatting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Chapter Info

    private func chapterInfoCard(_ chapter: BookChapter) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.title3)
                .foregroundStyle(AuroraTheme.auroraTeal)

            VStack(alignment: .leading, spacing: 2) {
                Text(chapter.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AuroraTheme.textPrimary)
                Text("\(chapter.wordCount) words")
                    .font(.caption)
                    .foregroundStyle(AuroraTheme.textTertiary)
            }

            Spacer()
        }
        .padding(14)
        .auroraCard()
    }

    // MARK: - Action Card

    private func actionCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        buttonLabel: String,
        isLoading: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AuroraTheme.textPrimary)
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AuroraTheme.textTertiary)

            Button(action: action) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                    Text(isLoading ? "Processing..." : buttonLabel)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    isLoading ? AnyShapeStyle(AuroraTheme.surface) : AnyShapeStyle(AuroraTheme.accentGradient),
                    in: RoundedRectangle(cornerRadius: 10)
                )
            }
            .disabled(isLoading || currentChapter == nil)

            if isLoading && formattingService.progress > 0 {
                ProgressView(value: formattingService.progress)
                    .tint(iconColor)
            }
        }
        .padding(16)
        .auroraCard()
    }

    // MARK: - Results Card

    private func resultsCard(_ result: FormattingResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: result.hasChanges ? "checkmark.circle.fill" : "equal.circle.fill")
                    .foregroundStyle(result.hasChanges ? AuroraTheme.auroraGreen : AuroraTheme.textTertiary)
                Text(result.hasChanges ? "Formatting Issues Found" : "No Issues Detected")
                    .font(.headline)
                    .foregroundStyle(AuroraTheme.textPrimary)
                Spacer()
                Text(result.method.rawValue)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AuroraTheme.auroraTeal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AuroraTheme.auroraTeal.opacity(0.12), in: Capsule())
            }

            if result.hasChanges {
                // Show fixes
                ForEach(result.fixes) { fix in
                    HStack(spacing: 8) {
                        Image(systemName: fix.type.iconName)
                            .font(.caption)
                            .foregroundStyle(AuroraTheme.auroraTeal)
                            .frame(width: 20)

                        Text(fix.description)
                            .font(.caption)
                            .foregroundStyle(AuroraTheme.textSecondary)

                        Spacer()

                        if fix.count > 1 {
                            Text("\(fix.count)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AuroraTheme.auroraTeal)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AuroraTheme.auroraTeal.opacity(0.15), in: Capsule())
                        }
                    }
                }

                // Apply button
                Button {
                    applyFixes(result)
                } label: {
                    Label("Apply Fixes", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AuroraTheme.auroraGreen, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .auroraCard()
    }

    // MARK: - Actions

    private func runDeepClean() async {
        guard let chapter = currentChapter else { return }
        isDeepCleaning = true
        errorMessage = nil
        defer { isDeepCleaning = false }

        do {
            result = try await formattingService.deepClean(chapter.content, chapterTitle: chapter.title)
            showPreview = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyFixes(_ result: FormattingResult) {
        guard let chapter = currentChapter else { return }
        chapter.content = result.cleanedText
        showPreview = false
        self.result = nil
    }
}

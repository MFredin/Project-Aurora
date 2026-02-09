import SwiftUI
import SwiftData

/// AI Reading Companion — recap, character map, vocab builder, Q&A chat
struct AICompanionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let book: Book
    let chapters: [BookChapter]
    let currentChapter: Int

    @State private var selectedTab: CompanionTab = .recap
    @State private var aiService = AICompanionService.shared
    @State private var chatMessages: [ChatMessage] = []
    @State private var messageText = ""

    enum CompanionTab: String, CaseIterable {
        case recap = "Recap"
        case characters = "Characters"
        case vocabulary = "Vocabulary"
        case chat = "Ask"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector

                    // Content
                    switch selectedTab {
                    case .recap: recapView
                    case .characters: characterMapView
                    case .vocabulary: vocabularyView
                    case .chat: chatView
                    }
                }
            }
            .navigationTitle("AI Companion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(CompanionTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(selectedTab == tab ? .white : AuroraTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedTab == tab
                                    ? AnyShapeStyle(AuroraTheme.secondaryGradient)
                                    : AnyShapeStyle(AuroraTheme.surface),
                                in: Capsule()
                            )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Recap View

    private var recapView: some View {
        let recap = aiService.generateRecap(
            book: book,
            chapters: chapters,
            currentChapter: currentChapter
        )

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Progress overview
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bookmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AuroraTheme.auroraTeal)
                        Text("Where You Left Off")
                            .font(.headline)
                            .foregroundStyle(AuroraTheme.textPrimary)
                    }

                    Text(recap.summary)
                        .font(.subheadline)
                        .foregroundStyle(AuroraTheme.textSecondary)

                    ProgressView(value: recap.readingProgress)
                        .tint(AuroraTheme.auroraTeal)

                    Text(recap.estimatedTimeToFinish)
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)
                }
                .padding(16)
                .auroraCard()

                // Key characters in recent chapters
                if !recap.keyCharacters.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.2.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(AuroraTheme.auroraPurple)
                            Text("Key Characters")
                                .font(.headline)
                                .foregroundStyle(AuroraTheme.textPrimary)
                        }

                        FlowLayout(spacing: 8) {
                            ForEach(recap.keyCharacters, id: \.self) { character in
                                Text(character)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AuroraTheme.textPrimary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(AuroraTheme.auroraPurple.opacity(0.15), in: Capsule())
                            }
                        }
                    }
                    .padding(16)
                    .auroraCard()
                }

                // Recent events
                if !recap.recentEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(AuroraTheme.auroraWarm)
                            Text("Recent Events")
                                .font(.headline)
                                .foregroundStyle(AuroraTheme.textPrimary)
                        }

                        ForEach(recap.recentEvents.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(AuroraTheme.auroraWarm)
                                    .frame(width: 20)

                                Text(recap.recentEvents[index])
                                    .font(.caption)
                                    .foregroundStyle(AuroraTheme.textSecondary)
                            }
                        }
                    }
                    .padding(16)
                    .auroraCard()
                }
            }
            .padding()
            .padding(.bottom, 20)
        }
    }

    // MARK: - Character Map

    private var characterMapView: some View {
        let characters = aiService.buildCharacterMap(chapters: Array(chapters.prefix(currentChapter + 1)))

        return ScrollView {
            VStack(spacing: 12) {
                if characters.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 36))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AuroraTheme.textTertiary)
                        Text("Not enough data yet")
                            .font(.subheadline)
                            .foregroundStyle(AuroraTheme.textSecondary)
                        Text("Keep reading to discover characters")
                            .font(.caption)
                            .foregroundStyle(AuroraTheme.textTertiary)
                    }
                    .padding(40)
                } else {
                    ForEach(characters) { character in
                        characterCard(character)
                    }
                }
            }
            .padding()
            .padding(.bottom, 20)
        }
    }

    private func characterCard(_ character: CharacterInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(character.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AuroraTheme.textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Text("\(character.mentionCount)")
                        .font(.caption.weight(.bold))
                    Text("mentions")
                        .font(.caption2)
                }
                .foregroundStyle(AuroraTheme.textTertiary)
            }

            Text("First appears in Chapter \(character.firstAppearanceChapter + 1)")
                .font(.caption)
                .foregroundStyle(AuroraTheme.auroraTeal)

            if !character.contextSnippets.isEmpty {
                ForEach(character.contextSnippets.prefix(2), id: \.self) { snippet in
                    Text("\"...\(snippet.prefix(100))...\"")
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(AuroraTheme.textTertiary)
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .auroraCard()
    }

    // MARK: - Vocabulary View

    private var vocabularyView: some View {
        let currentChapterObj = currentChapter < chapters.count ? chapters[currentChapter] : nil
        let suggestions = currentChapterObj.map { aiService.extractVocabulary(from: $0) } ?? []

        return ScrollView {
            VStack(spacing: 12) {
                if suggestions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.book.closed.fill")
                            .font(.system(size: 36))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AuroraTheme.textTertiary)
                        Text("No vocabulary suggestions")
                            .font(.subheadline)
                            .foregroundStyle(AuroraTheme.textSecondary)
                    }
                    .padding(40)
                } else {
                    Text("Words from \"\(currentChapterObj?.title ?? "")\"")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textSecondary)

                    ForEach(suggestions) { suggestion in
                        vocabCard(suggestion)
                    }
                }
            }
            .padding()
            .padding(.bottom, 20)
        }
    }

    private func vocabCard(_ suggestion: VocabSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(suggestion.word)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AuroraTheme.textPrimary)

                Spacer()

                Button {
                    saveVocabularyWord(suggestion)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AuroraTheme.auroraGreen)
                }
            }

            if !suggestion.context.isEmpty {
                Text(suggestion.context)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(AuroraTheme.textTertiary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .auroraCard()
    }

    // MARK: - Chat View

    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 10) {
                    if chatMessages.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 36))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(AuroraTheme.textTertiary)

                            Text("Ask about the book")
                                .font(.subheadline)
                                .foregroundStyle(AuroraTheme.textSecondary)

                            VStack(alignment: .leading, spacing: 6) {
                                suggestionButton("Who is the main character?")
                                suggestionButton("What happened in the last chapter?")
                                suggestionButton("What are the main themes?")
                            }
                        }
                        .padding(30)
                    }

                    ForEach(chatMessages) { message in
                        chatBubble(message)
                    }
                }
                .padding()
            }

            // Input bar
            HStack(spacing: 10) {
                TextField("Ask a question...", text: $messageText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(AuroraTheme.textPrimary)
                    .padding(10)
                    .background(AuroraTheme.surface, in: RoundedRectangle(cornerRadius: 20))

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(messageText.isEmpty ? AuroraTheme.textTertiary : AuroraTheme.auroraTeal)
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    private func suggestionButton(_ text: String) -> some View {
        Button {
            messageText = text
            sendMessage()
        } label: {
            HStack {
                Image(systemName: "sparkle")
                    .font(.caption2)
                Text(text)
                    .font(.caption)
            }
            .foregroundStyle(AuroraTheme.auroraTeal)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AuroraTheme.auroraTeal.opacity(0.1), in: Capsule())
        }
    }

    private func chatBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isUser { Spacer() }

            Text(message.text)
                .font(.subheadline)
                .foregroundStyle(message.isUser ? .white : AuroraTheme.textPrimary)
                .padding(12)
                .background(
                    message.isUser
                        ? AnyShapeStyle(AuroraTheme.secondaryGradient)
                        : AnyShapeStyle(AuroraTheme.surface.opacity(0.8)),
                    in: RoundedRectangle(cornerRadius: 16)
                )

            if !message.isUser { Spacer() }
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let question = messageText
        messageText = ""

        chatMessages.append(ChatMessage(text: question, isUser: true))

        let response = aiService.answerQuestion(
            question: question,
            chapters: chapters,
            currentChapter: currentChapter
        )

        chatMessages.append(ChatMessage(text: response.answer, isUser: false))
    }

    private func saveVocabularyWord(_ suggestion: VocabSuggestion) {
        let entry = VocabularyEntry(
            word: suggestion.word,
            context: suggestion.context,
            bookTitle: book.title,
            chapterTitle: suggestion.chapterTitle
        )
        entry.book = book
        modelContext.insert(entry)
        try? modelContext.save()
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

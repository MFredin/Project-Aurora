import SwiftUI
import SwiftData

struct ReaderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [UserPreferences]
    @State private var viewModel: ReaderViewModel
    @State private var statsService = ReadingStatsService.shared
    @State private var ambientService = AmbientService.shared
    @State private var currentSession: ReadingSession?

    // New feature states
    @State private var showSearch = false
    @State private var showAnnotations = false
    @State private var showAICompanion = false
    @State private var showAmbientControls = false
    @State private var showReadingModeSelector = false
    @State private var showHighlightActions = false
    @State private var selectedReadingMode: SmartReadingMode = .standard
    @State private var selectedText = ""
    @State private var highlightColor: HighlightColor = .auroraTeal
    @State private var showNoteInput = false
    @State private var noteText = ""

    init(book: Book) {
        _viewModel = State(wrappedValue: ReaderViewModel(book: book))
    }

    private var currentPreferences: UserPreferences {
        preferences.first ?? UserPreferences()
    }

    var body: some View {
        ZStack {
            currentPreferences.theme.backgroundColor
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("Loading book...")
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else {
                readerContent
            }

            // Overlaid toolbar
            if viewModel.isToolbarVisible {
                readerOverlay
            }

            // Highlight action bar
            if showHighlightActions && !selectedText.isEmpty {
                highlightActionBar
            }
        }
        .task {
            await viewModel.loadBook(modelContext: modelContext)
            ensurePreferencesExist()
            currentSession = statsService.startSession(for: viewModel.book, modelContext: modelContext)
        }
        .onDisappear {
            let chaptersRead = viewModel.currentChapterIndex
            statsService.endSession(
                pagesRead: chaptersRead,
                chaptersRead: chaptersRead,
                wordsRead: 0,
                modelContext: modelContext
            )
            ambientService.stopSoundscape()
        }
        .sheet(isPresented: $viewModel.showTableOfContents) {
            TableOfContentsView(
                chapters: viewModel.chapters,
                currentIndex: viewModel.currentChapterIndex
            ) { index in
                viewModel.goToChapter(at: index)
                ambientService.chapterCompleteHaptic()
            }
        }
        .sheet(isPresented: $viewModel.showSettings) {
            ReaderSettingsSheet(preferences: currentPreferences)
        }
        .sheet(isPresented: $viewModel.showBookmarkSheet) {
            AddBookmarkSheet { title in
                viewModel.addBookmark(title: title, modelContext: modelContext)
                ambientService.bookmarkHaptic()
            }
        }
        .sheet(isPresented: $showSearch) {
            ReaderSearchView(
                chapters: viewModel.chapters,
                bookTitle: viewModel.book.title
            ) { chapterIndex, _ in
                viewModel.goToChapter(at: chapterIndex)
            }
        }
        .sheet(isPresented: $showAnnotations) {
            NavigationStack {
                AnnotationsListView(book: viewModel.book) { highlight in
                    viewModel.goToChapter(at: highlight.chapterIndex)
                }
            }
        }
        .sheet(isPresented: $showAICompanion) {
            AICompanionView(
                book: viewModel.book,
                chapters: viewModel.chapters,
                currentChapter: viewModel.currentChapterIndex
            )
        }
        .sheet(isPresented: $showAmbientControls) {
            AmbientControlView(bookTitle: viewModel.book.title, genre: nil)
        }
        .sheet(isPresented: $showReadingModeSelector) {
            ReadingModeSelector(selectedMode: $selectedReadingMode)
        }
        .sheet(isPresented: $showNoteInput) {
            addNoteSheet
        }
        .statusBarHidden(!viewModel.isToolbarVisible)
    }

    // MARK: - Reader Content

    private var readerContent: some View {
        let prefs = currentPreferences

        return ScrollView {
            if let chapter = viewModel.currentChapter {
                VStack(alignment: .leading, spacing: 0) {
                    Text(chapter.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(prefs.theme.textColor)
                        .padding(.bottom, 16)

                    // Render based on reading mode
                    switch selectedReadingMode {
                    case .bionic:
                        BionicTextView(
                            text: chapter.content,
                            fontSize: prefs.fontSize,
                            fontFamily: prefs.fontFamily,
                            textColor: prefs.theme.textColor
                        )
                        .lineSpacing(prefs.fontSize * CGFloat(prefs.lineSpacing - 1.0))

                    case .speed:
                        SpeedReadingView(text: chapter.content)

                    case .focus:
                        VStack(spacing: 20) {
                            FocusModeView()
                            standardText(chapter: chapter, prefs: prefs)
                        }

                    case .accessibility:
                        standardText(chapter: chapter, prefs: prefs)
                            .font(.custom("OpenDyslexic", size: prefs.fontSize))
                            .lineSpacing(prefs.fontSize * CGFloat(prefs.lineSpacing))

                    case .standard:
                        standardText(chapter: chapter, prefs: prefs)
                    }

                    // Chapter highlights summary
                    let chapterHighlights = viewModel.book.highlights.filter { $0.chapterIndex == viewModel.currentChapterIndex }
                    if !chapterHighlights.isEmpty {
                        highlightsInChapter(chapterHighlights)
                    }
                }
                .padding(.horizontal, prefs.marginSize)
                .padding(.vertical, 60)
            }
        }
        .onTapGesture { viewModel.toggleToolbar() }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 {
                        viewModel.goToNextChapter()
                        ambientService.pageTurnHaptic()
                    } else if value.translation.width > 50 {
                        viewModel.goToPreviousChapter()
                        ambientService.pageTurnHaptic()
                    }
                }
        )
    }

    private func standardText(chapter: BookChapter, prefs: UserPreferences) -> some View {
        Text(chapter.content)
            .font(.custom(prefs.fontFamily, size: prefs.fontSize))
            .foregroundStyle(prefs.theme.textColor)
            .lineSpacing(prefs.fontSize * CGFloat(prefs.lineSpacing - 1.0))
            .textSelection(.enabled)
    }

    // MARK: - Highlights in Chapter

    private func highlightsInChapter(_ highlights: [Highlight]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().overlay(AuroraTheme.textTertiary.opacity(0.3))

            HStack {
                Image(systemName: "highlighter")
                    .font(.caption)
                    .foregroundStyle(AuroraTheme.auroraTeal)
                Text("\(highlights.count) highlight\(highlights.count == 1 ? "" : "s") in this chapter")
                    .font(.caption)
                    .foregroundStyle(AuroraTheme.textSecondary)
            }
            .padding(.top, 16)

            ForEach(highlights.prefix(3)) { highlight in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(highlight.highlightColor.color)
                        .frame(width: 3)

                    Text(highlight.textPreview)
                        .font(.caption2)
                        .foregroundStyle(AuroraTheme.textTertiary)
                        .lineLimit(2)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Overlay

    private var readerOverlay: some View {
        VStack {
            // Top bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .padding(6)
                }

                Spacer()

                Text(viewModel.book.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                Menu {
                    Button(action: { viewModel.showTableOfContents = true }) {
                        Label("Table of Contents", systemImage: "list.bullet.circle")
                    }
                    Button(action: { showSearch = true }) {
                        Label("Search in Book", systemImage: "magnifyingglass.circle.fill")
                    }
                    Button(action: { showAnnotations = true }) {
                        Label("Annotations", systemImage: "highlighter")
                    }

                    Divider()

                    Button(action: { showAICompanion = true }) {
                        Label("AI Companion", systemImage: "sparkles")
                    }
                    Button(action: { showReadingModeSelector = true }) {
                        Label("Reading Mode", systemImage: selectedReadingMode.iconName)
                    }
                    Button(action: { showAmbientControls = true }) {
                        Label("Ambient", systemImage: "music.note.list")
                    }

                    Divider()

                    Button(action: { viewModel.showBookmarkSheet = true }) {
                        Label("Add Bookmark", systemImage: "bookmark.circle")
                    }
                    Button(action: { viewModel.showSettings = true }) {
                        Label("Settings", systemImage: "textformat.size.larger")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .padding(6)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()

            // Bottom bar
            VStack(spacing: 8) {
                // Quick action bar
                HStack(spacing: 16) {
                    quickActionButton(icon: "magnifyingglass", label: "Search") { showSearch = true }
                    quickActionButton(icon: "highlighter", label: "Annotations") { showAnnotations = true }
                    quickActionButton(icon: "sparkles", label: "AI") { showAICompanion = true }
                    quickActionButton(icon: selectedReadingMode.iconName, label: "Mode") { showReadingModeSelector = true }
                    quickActionButton(
                        icon: ambientService.isAmbientEnabled ? "speaker.wave.2.fill" : "speaker.fill",
                        label: "Ambient"
                    ) { showAmbientControls = true }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)

                // Chapter navigation
                HStack {
                    Button(action: {
                        viewModel.goToPreviousChapter()
                        ambientService.pageTurnHaptic()
                    }) {
                        Image(systemName: "chevron.backward.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .disabled(!viewModel.canGoToPreviousChapter)

                    Spacer()

                    Text(viewModel.progressText)
                        .font(.caption)

                    Spacer()

                    Button(action: {
                        viewModel.goToNextChapter()
                        ambientService.pageTurnHaptic()
                    }) {
                        Image(systemName: "chevron.forward.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .disabled(!viewModel.canGoToNextChapter)
                }

                ProgressView(value: viewModel.progressPercentage)
                    .tint(.accentColor)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .transition(.opacity)
    }

    private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.caption)
                    .symbolRenderingMode(.hierarchical)
                Text(label)
                    .font(.system(size: 9))
            }
            .foregroundStyle(AuroraTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Highlight Action Bar

    private var highlightActionBar: some View {
        VStack {
            Spacer()

            VStack(spacing: 10) {
                // Color picker
                HStack(spacing: 12) {
                    ForEach(HighlightColor.allCases) { color in
                        Circle()
                            .fill(color.color)
                            .frame(width: 28, height: 28)
                            .overlay {
                                if highlightColor == color {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            .onTapGesture { highlightColor = color }
                    }
                }

                // Actions
                HStack(spacing: 16) {
                    Button {
                        addHighlight(withNote: false)
                    } label: {
                        Label("Highlight", systemImage: "highlighter")
                            .font(.caption.weight(.medium))
                    }

                    Button {
                        showNoteInput = true
                    } label: {
                        Label("Add Note", systemImage: "note.text")
                            .font(.caption.weight(.medium))
                    }

                    Button {
                        showHighlightActions = false
                        selectedText = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.medium))
                    }
                }
                .foregroundStyle(AuroraTheme.textPrimary)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.bottom, 120)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Add Note Sheet

    private var addNoteSheet: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text(selectedText.prefix(100) + (selectedText.count > 100 ? "..." : ""))
                        .font(.caption)
                        .italic()
                        .foregroundStyle(AuroraTheme.textSecondary)
                        .padding(12)
                        .background(highlightColor.backgroundColor, in: RoundedRectangle(cornerRadius: 8))

                    TextEditor(text: $noteText)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(AuroraTheme.textPrimary)
                        .padding(8)
                        .background(AuroraTheme.surface, in: RoundedRectangle(cornerRadius: 8))

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        noteText = ""
                        showNoteInput = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addHighlight(withNote: true)
                        showNoteInput = false
                    }
                }
            }
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text(message)
        } actions: {
            Button("Go Back") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Helpers

    private func addHighlight(withNote: Bool) {
        guard !selectedText.isEmpty else { return }
        let chapter = viewModel.currentChapter
        let highlight = Highlight(
            highlightedText: selectedText,
            note: withNote ? noteText : "",
            color: highlightColor,
            chapterIndex: viewModel.currentChapterIndex,
            chapterTitle: chapter?.title ?? "",
            rangeStart: 0,
            rangeLength: selectedText.count
        )
        highlight.book = viewModel.book
        viewModel.book.highlights.append(highlight)
        modelContext.insert(highlight)
        try? modelContext.save()

        selectedText = ""
        noteText = ""
        showHighlightActions = false
    }

    private func ensurePreferencesExist() {
        if preferences.isEmpty {
            let prefs = UserPreferences()
            modelContext.insert(prefs)
            try? modelContext.save()
        }
    }
}

import SwiftUI
import SwiftData

struct ReaderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [UserPreferences]
    @State private var viewModel: ReaderViewModel
    @State private var statsService = ReadingStatsService.shared
    @State private var currentSession: ReadingSession?

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
        }
        .sheet(isPresented: $viewModel.showTableOfContents) {
            TableOfContentsView(
                chapters: viewModel.chapters,
                currentIndex: viewModel.currentChapterIndex
            ) { index in
                viewModel.goToChapter(at: index)
            }
        }
        .sheet(isPresented: $viewModel.showSettings) {
            ReaderSettingsSheet(preferences: currentPreferences)
        }
        .sheet(isPresented: $viewModel.showBookmarkSheet) {
            AddBookmarkSheet { title in
                viewModel.addBookmark(title: title, modelContext: modelContext)
            }
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

                    Text(chapter.content)
                        .font(.custom(prefs.fontFamily, size: prefs.fontSize))
                        .foregroundStyle(prefs.theme.textColor)
                        .lineSpacing(prefs.fontSize * CGFloat(prefs.lineSpacing - 1.0))
                        .textSelection(.enabled)
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
                    } else if value.translation.width > 50 {
                        viewModel.goToPreviousChapter()
                    }
                }
        )
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
                // Chapter navigation
                HStack {
                    Button(action: { viewModel.goToPreviousChapter() }) {
                        Image(systemName: "chevron.backward.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .disabled(!viewModel.canGoToPreviousChapter)

                    Spacer()

                    Text(viewModel.progressText)
                        .font(.caption)

                    Spacer()

                    Button(action: { viewModel.goToNextChapter() }) {
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

    private func ensurePreferencesExist() {
        if preferences.isEmpty {
            let prefs = UserPreferences()
            modelContext.insert(prefs)
            try? modelContext.save()
        }
    }
}

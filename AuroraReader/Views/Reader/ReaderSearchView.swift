import SwiftUI

/// In-book search overlay for the reader
struct ReaderSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchService = SearchService.shared

    let chapters: [BookChapter]
    let bookTitle: String
    let onNavigate: (Int, Int) -> Void // chapterIndex, position

    @State private var searchText = ""
    @State private var results: [SearchResult] = []
    @State private var selectedResultIndex: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Results count
                    if !searchText.isEmpty {
                        HStack {
                            Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(AuroraTheme.textSecondary)
                            Spacer()
                            if let index = selectedResultIndex {
                                Text("\(index + 1) of \(results.count)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AuroraTheme.auroraTeal)

                                HStack(spacing: 12) {
                                    Button {
                                        navigatePrevious()
                                    } label: {
                                        Image(systemName: "chevron.up.circle.fill")
                                            .symbolRenderingMode(.hierarchical)
                                    }
                                    Button {
                                        navigateNext()
                                    } label: {
                                        Image(systemName: "chevron.down.circle.fill")
                                            .symbolRenderingMode(.hierarchical)
                                    }
                                }
                                .foregroundStyle(AuroraTheme.auroraTeal)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    // Results list
                    if results.isEmpty && !searchText.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.title)
                                .foregroundStyle(AuroraTheme.textTertiary)
                            Text("No results found")
                                .font(.subheadline)
                                .foregroundStyle(AuroraTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !searchText.isEmpty {
                        List {
                            ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                                Button {
                                    selectedResultIndex = index
                                    onNavigate(result.chapterIndex, result.position)
                                } label: {
                                    searchResultRow(result, isSelected: selectedResultIndex == index)
                                }
                                .listRowBackground(
                                    selectedResultIndex == index
                                        ? AuroraTheme.auroraTeal.opacity(0.1)
                                        : AuroraTheme.surface
                                )
                            }
                        }
                        .scrollContentBackground(.hidden)
                    } else {
                        // Recent searches
                        if !searchService.recentSearches.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recent Searches")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AuroraTheme.textSecondary)
                                    .padding(.horizontal)

                                ForEach(searchService.recentSearches, id: \.self) { recent in
                                    Button {
                                        searchText = recent
                                        performSearch()
                                    } label: {
                                        HStack {
                                            Image(systemName: "clock.circle.fill")
                                                .symbolRenderingMode(.hierarchical)
                                                .foregroundStyle(AuroraTheme.textTertiary)
                                            Text(recent)
                                                .foregroundStyle(AuroraTheme.textPrimary)
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                    }
                                }
                            }
                            .padding(.top, 16)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Search in Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search...")
            .onChange(of: searchText) { _, _ in
                performSearch()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func searchResultRow(_ result: SearchResult, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(result.chapterTitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(AuroraTheme.auroraTeal)

            Text(highlightedContext(result.contextText, query: searchText))
                .font(.caption)
                .foregroundStyle(AuroraTheme.textPrimary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }

    private func highlightedContext(_ text: String, query: String) -> AttributedString {
        var attributed = AttributedString(text)
        if let range = attributed.range(of: query, options: .caseInsensitive) {
            attributed[range].foregroundColor = UIColor(AuroraTheme.auroraWarm)
            attributed[range].font = .caption.bold()
        }
        return attributed
    }

    private func performSearch() {
        guard !searchText.isEmpty else {
            results = []
            selectedResultIndex = nil
            return
        }
        results = searchService.searchInBook(
            query: searchText,
            chapters: chapters,
            bookTitle: bookTitle
        )
        selectedResultIndex = results.isEmpty ? nil : 0
    }

    private func navigateNext() {
        guard !results.isEmpty, let current = selectedResultIndex else { return }
        let next = (current + 1) % results.count
        selectedResultIndex = next
        onNavigate(results[next].chapterIndex, results[next].position)
    }

    private func navigatePrevious() {
        guard !results.isEmpty, let current = selectedResultIndex else { return }
        let prev = current > 0 ? current - 1 : results.count - 1
        selectedResultIndex = prev
        onNavigate(results[prev].chapterIndex, results[prev].position)
    }
}

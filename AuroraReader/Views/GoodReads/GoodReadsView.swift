import SwiftUI

struct GoodReadsView: View {
    @State private var service = GoodReadsService.shared
    @State private var searchText = ""
    @State private var searchResults: [GoodReadsBook] = []
    @State private var isSearching = false
    @State private var selectedShelf = "Want to Read"

    private let shelves = ["Want to Read", "Currently Reading", "Read"]

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                // Aurora background glow
                Circle()
                    .fill(AuroraTheme.auroraWarm.opacity(0.06))
                    .frame(width: 350, height: 350)
                    .blur(radius: 90)
                    .offset(x: -50, y: -200)
                    .ignoresSafeArea()

                Circle()
                    .fill(AuroraTheme.auroraPurple.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 100, y: 200)
                    .ignoresSafeArea()

                authenticatedContentView
            }
            .navigationTitle("Discover")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search books...")
            .onSubmit(of: .search) {
                Task { await performSearch() }
            }
            .task {
                // Auto-activate — Open Library requires no API key
                if !service.isAuthenticated {
                    try? await service.authenticate(apiKey: "")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Authenticated Content

    private var authenticatedContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Search results
                if isSearching {
                    ProgressView("Searching...")
                        .tint(AuroraTheme.auroraTeal)
                        .foregroundStyle(AuroraTheme.textSecondary)
                        .padding(.top, 40)
                } else if !searchResults.isEmpty {
                    searchResultsSection
                }

                // Shelves
                shelvesSection

                // Trending placeholder
                trendingSection
            }
            .padding()
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Search Results")
                    .font(.headline)
                    .foregroundStyle(AuroraTheme.textPrimary)
                Spacer()
                Text("\(searchResults.count) found")
                    .font(.caption)
                    .foregroundStyle(AuroraTheme.textTertiary)
            }

            ForEach(searchResults) { book in
                goodReadsBookRow(book)
            }
        }
    }

    private var shelvesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Shelves")
                .font(.headline)
                .foregroundStyle(AuroraTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(shelves, id: \.self) { shelf in
                        Button {
                            selectedShelf = shelf
                        } label: {
                            Text(shelf)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(selectedShelf == shelf ? .white : AuroraTheme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedShelf == shelf
                                        ? AnyShapeStyle(AuroraTheme.accentGradient)
                                        : AnyShapeStyle(AuroraTheme.surface),
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            selectedShelf == shelf
                                                ? Color.clear
                                                : Color.white.opacity(0.08),
                                            lineWidth: 0.5
                                        )
                                )
                        }
                    }
                }
            }

            // Empty shelf placeholder
            VStack(spacing: 12) {
                Image(systemName: "text.book.closed.fill")
                    .font(.title)
                    .foregroundStyle(AuroraTheme.textTertiary)
                Text("No books on this shelf yet")
                    .font(.subheadline)
                    .foregroundStyle(AuroraTheme.textTertiary)
                Text("Search for books above and tap + to add them")
                    .font(.caption)
                    .foregroundStyle(AuroraTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .auroraCard()
        }
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trending This Week")
                    .font(.headline)
                    .foregroundStyle(AuroraTheme.textPrimary)
                Spacer()
                Text("See All")
                    .font(.subheadline)
                    .foregroundStyle(AuroraTheme.auroraTeal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<5, id: \.self) { i in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AuroraTheme.coverPalettes[i % AuroraTheme.coverPalettes.count][0].gradient)
                                .frame(width: 100, height: 150)
                                .overlay(
                                    Image(systemName: "book.fill")
                                        .foregroundStyle(.white.opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                                )

                            Text("Book Title")
                                .font(.caption)
                                .foregroundStyle(AuroraTheme.textPrimary)
                                .lineLimit(1)
                                .frame(width: 100)

                            HStack(spacing: 2) {
                                ForEach(0..<5) { star in
                                    Image(systemName: star < 4 ? "star.fill" : "star")
                                        .font(.system(size: 8))
                                        .foregroundStyle(AuroraTheme.auroraWarm)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func goodReadsBookRow(_ book: GoodReadsBook) -> some View {
        HStack(spacing: 14) {
            // Cover image or gradient placeholder
            if let coverURL = book.imageURL, let url = URL(string: coverURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AuroraTheme.coverGradient(for: book.title))
                            .overlay(Image(systemName: "book.fill").foregroundStyle(.white.opacity(0.6)).font(.caption))
                    }
                }
                .frame(width: 50, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AuroraTheme.coverGradient(for: book.title))
                    .frame(width: 50, height: 70)
                    .overlay(
                        Image(systemName: "book.fill")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.caption)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AuroraTheme.textPrimary)
                    .lineLimit(1)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(AuroraTheme.textSecondary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    HStack(spacing: 1) {
                        ForEach(0..<5) { star in
                            Image(systemName: Double(star) < book.averageRating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundStyle(AuroraTheme.auroraWarm)
                        }
                    }
                    Text("\(book.ratingsCount) ratings")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)
                }
            }

            Spacer()

            Button {
                Task {
                    try? await service.addToShelf(goodreadsId: book.id, shelfName: "Want to Read")
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AuroraTheme.auroraTeal)
            }
        }
        .padding(12)
        .auroraCard()
    }

    private func performSearch() async {
        guard !searchText.isEmpty else { return }
        isSearching = true
        defer { isSearching = false }
        searchResults = (try? await service.searchBooks(query: searchText)) ?? []
    }
}

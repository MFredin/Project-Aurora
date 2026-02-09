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

                if !service.isAuthenticated {
                    connectGoodReadsView
                } else {
                    authenticatedContentView
                }
            }
            .navigationTitle("Discover")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search books on GoodReads")
            .onSubmit(of: .search) {
                Task { await performSearch() }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Not Connected

    private var connectGoodReadsView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AuroraTheme.auroraWarm.opacity(0.1))
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(AuroraTheme.auroraPurple.opacity(0.08))
                    .frame(width: 160, height: 160)
                BrandAssets.GoodReadsLogo(size: 56)
            }

            Text("Discover Books")
                .font(.title2.weight(.bold))
                .foregroundStyle(AuroraTheme.textPrimary)

            Text("Connect to GoodReads to discover new books,\nread reviews, and track your reading.")
                .font(.subheadline)
                .foregroundStyle(AuroraTheme.textSecondary)
                .multilineTextAlignment(.center)

            Text("COMING SOON")
                .font(.caption2.weight(.bold))
                .foregroundStyle(AuroraTheme.auroraWarm)
                .tracking(1.5)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(AuroraTheme.auroraWarm.opacity(0.12), in: Capsule())

            Text("GoodReads integration is being finalized.\nStay tuned for book discovery and reviews.")
                .font(.caption)
                .foregroundStyle(AuroraTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Authenticated Content

    private var authenticatedContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Search results
                if !searchResults.isEmpty {
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
            Text("Search Results")
                .font(.headline)
                .foregroundStyle(AuroraTheme.textPrimary)

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
            RoundedRectangle(cornerRadius: 6)
                .fill(AuroraTheme.coverGradient(for: book.title))
                .frame(width: 50, height: 70)
                .overlay(
                    Image(systemName: "book.fill")
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.caption)
                )

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

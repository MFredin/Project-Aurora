import SwiftUI

struct BookmarkListView: View {
    let bookmarks: [Bookmark]
    let onSelect: (Bookmark) -> Void
    let onDelete: (Bookmark) -> Void

    var body: some View {
        Group {
            if bookmarks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark.circle.fill")
                        .font(.system(size: 40))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AuroraTheme.textTertiary)
                    Text("No Bookmarks")
                        .font(.headline)
                        .foregroundStyle(AuroraTheme.textSecondary)
                    Text("Bookmarks you add will appear here.")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(sortedBookmarks) { bookmark in
                        Button {
                            onSelect(bookmark)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(bookmark.title)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AuroraTheme.textPrimary)

                                Text("Chapter \(bookmark.chapter + 1)")
                                    .font(.caption)
                                    .foregroundStyle(AuroraTheme.textSecondary)

                                if !bookmark.textSnippet.isEmpty {
                                    Text(bookmark.textSnippet)
                                        .font(.caption)
                                        .foregroundStyle(AuroraTheme.textTertiary)
                                        .lineLimit(2)
                                }

                                Text(bookmark.dateCreated, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(AuroraTheme.textTertiary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                onDelete(bookmark)
                            } label: {
                                Label("Delete", systemImage: "trash.circle")
                            }
                        }
                        .listRowBackground(AuroraTheme.surface)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var sortedBookmarks: [Bookmark] {
        bookmarks.sorted { $0.dateCreated > $1.dateCreated }
    }
}

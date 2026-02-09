import SwiftUI

struct BookmarkListView: View {
    let bookmarks: [Bookmark]
    let onSelect: (Bookmark) -> Void
    let onDelete: (Bookmark) -> Void

    var body: some View {
        Group {
            if bookmarks.isEmpty {
                ContentUnavailableView(
                    "No Bookmarks",
                    systemImage: "bookmark.circle",
                    description: Text("Bookmarks you add will appear here.")
                )
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

                                Text("Chapter \(bookmark.chapter + 1)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if !bookmark.textSnippet.isEmpty {
                                    Text(bookmark.textSnippet)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(2)
                                }

                                Text(bookmark.dateCreated, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                onDelete(bookmark)
                            } label: {
                                Label("Delete", systemImage: "trash.circle")
                            }
                        }
                    }
                }
            }
        }
    }

    private var sortedBookmarks: [Bookmark] {
        bookmarks.sorted { $0.dateCreated > $1.dateCreated }
    }
}

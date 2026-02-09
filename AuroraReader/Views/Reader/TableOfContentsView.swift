import SwiftUI

struct TableOfContentsView: View {
    let chapters: [BookChapter]
    let currentIndex: Int
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                    Button {
                        onSelect(index)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(chapter.title)
                                    .font(.body)
                                    .foregroundStyle(index == currentIndex ? .accentColor : .primary)
                                    .fontWeight(index == currentIndex ? .semibold : .regular)

                                Text("\(chapter.wordCount) words · \(chapter.estimatedReadingTimeMinutes) min read")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if index == currentIndex {
                                Image(systemName: "bookmark.fill")
                                    .foregroundStyle(.accentColor)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Table of Contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

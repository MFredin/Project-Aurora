import SwiftUI

struct TableOfContentsView: View {
    let chapters: [BookChapter]
    let currentIndex: Int
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                if chapters.isEmpty {
                    ContentUnavailableView {
                        Label("No Chapters", systemImage: "book.circle")
                    } description: {
                        Text("This book doesn't have chapter information.")
                    }
                    .foregroundStyle(AuroraTheme.textSecondary)
                } else {
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
                                            .foregroundStyle(index == currentIndex ? AuroraTheme.auroraTeal : AuroraTheme.textPrimary)
                                            .fontWeight(index == currentIndex ? .semibold : .regular)

                                        Text("\(chapter.wordCount) words · \(chapter.estimatedReadingTimeMinutes) min read")
                                            .font(.caption)
                                            .foregroundStyle(AuroraTheme.textTertiary)
                                    }

                                    Spacer()

                                    if index == currentIndex {
                                        Image(systemName: "bookmark.fill")
                                            .foregroundStyle(AuroraTheme.auroraTeal)
                                            .font(.caption)
                                    }
                                }
                            }
                            .listRowBackground(
                                index == currentIndex
                                    ? AuroraTheme.auroraTeal.opacity(0.08)
                                    : AuroraTheme.surface
                            )
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Table of Contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AuroraTheme.auroraTeal)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

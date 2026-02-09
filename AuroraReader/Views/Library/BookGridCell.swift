import SwiftUI

struct BookGridCell: View {
    let book: Book

    var body: some View {
        VStack(spacing: 8) {
            bookCover
                .frame(width: 140, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

            VStack(spacing: 2) {
                Text(book.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(book.author)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let progress = book.readingProgress, progress.progressPercentage > 0 {
                ProgressView(value: progress.progressPercentage)
                    .tint(.accentColor)
                    .frame(width: 100)
            }
        }
        .frame(width: 150)
    }

    @ViewBuilder
    private var bookCover: some View {
        if let imageData = book.coverImageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            defaultCover
        }
    }

    private var defaultCover: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors(for: book.title),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: iconForFormat(book.bookFormat))
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))

                Text(book.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 8)

                Text(book.author)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .padding(.horizontal, 8)
            }
        }
    }

    private func gradientColors(for title: String) -> [Color] {
        let hash = abs(title.hashValue)
        let palettes: [[Color]] = [
            [.blue, .purple],
            [.orange, .red],
            [.green, .teal],
            [.indigo, .blue],
            [.pink, .purple],
            [.teal, .cyan],
            [.brown, .orange],
            [.mint, .green],
        ]
        return palettes[hash % palettes.count]
    }

    private func iconForFormat(_ format: BookFormat) -> String {
        switch format {
        case .epub: return "book.fill"
        case .pdf: return "doc.richtext"
        case .plainText: return "doc.plaintext"
        }
    }
}

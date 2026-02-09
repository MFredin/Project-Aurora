import SwiftUI

struct BookListRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            bookThumbnail
                .frame(width: 50, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(book.bookFormat.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.fill.tertiary)
                        .clipShape(Capsule())

                    Text(book.formattedFileSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let progress = book.readingProgress, progress.progressPercentage > 0 {
                        Text("\(Int(progress.progressPercentage * 100))%")
                            .font(.caption)
                            .foregroundStyle(.accentColor)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var bookThumbnail: some View {
        if let imageData = book.coverImageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "book.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
            }
        }
    }
}

import SwiftUI

struct BookListRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            bookThumbnail
                .frame(width: 50, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(AuroraTheme.textPrimary)
                    .lineLimit(1)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(AuroraTheme.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(book.bookFormat.displayName)
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.auroraTeal)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AuroraTheme.auroraTeal.opacity(0.15), in: Capsule())

                    Text(book.formattedFileSize)
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)

                    if let progress = book.readingProgress, progress.progressPercentage > 0 {
                        Text("\(Int(progress.progressPercentage * 100))%")
                            .font(.caption)
                            .foregroundStyle(AuroraTheme.auroraGreen)
                    }

                    if book.cloudSource != nil {
                        Image(systemName: "cloud.fill")
                            .font(.caption2)
                            .foregroundStyle(AuroraTheme.auroraBlue)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AuroraTheme.textTertiary)
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
                AuroraTheme.coverGradient(for: book.title)
                Image(systemName: book.bookFormat.iconName)
                    .font(.caption)
                    .foregroundStyle(.white)
            }
        }
    }
}

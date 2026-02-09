import SwiftUI

struct BookGridCell: View {
    let book: Book

    var body: some View {
        VStack(spacing: 8) {
            bookCover
                .frame(width: 140, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )
                .shadow(color: AuroraTheme.auroraBlue.opacity(0.15), radius: 8, x: 0, y: 4)

            VStack(spacing: 2) {
                Text(book.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AuroraTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(book.author)
                    .font(.caption2)
                    .foregroundStyle(AuroraTheme.textSecondary)
                    .lineLimit(1)
            }

            if let progress = book.readingProgress, progress.progressPercentage > 0 {
                ProgressView(value: progress.progressPercentage)
                    .tint(AuroraTheme.auroraTeal)
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
            AuroraTheme.coverGradient(for: book.title)

            VStack(spacing: 8) {
                Image(systemName: book.bookFormat.iconName)
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.85))

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

                Text(book.bookFormat.displayName)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.2), in: Capsule())
            }
        }
    }
}

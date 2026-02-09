import SwiftUI

/// Brand logo views for third-party service integrations.
/// Renders scalable vector-style logos using SwiftUI shapes for pixel-perfect display
/// without requiring external asset files.
enum BrandAssets {

    // MARK: - Dropbox Logo

    /// Dropbox diamond-box logo rendered in SwiftUI
    struct DropboxLogo: View {
        var size: CGFloat = 24

        var body: some View {
            Canvas { context, canvasSize in
                let s = min(canvasSize.width, canvasSize.height)
                let unit = s / 24

                // Dropbox is 5 diamonds arranged in an open-box pattern
                let color = Color(red: 0.0, green: 0.38, blue: 1.0) // Dropbox blue #0061FE

                // Top-left diamond
                drawDiamond(in: &context, cx: 7 * unit, cy: 5 * unit, w: 6 * unit, h: 4.5 * unit, color: color)
                // Top-right diamond
                drawDiamond(in: &context, cx: 17 * unit, cy: 5 * unit, w: 6 * unit, h: 4.5 * unit, color: color)
                // Bottom-left diamond
                drawDiamond(in: &context, cx: 7 * unit, cy: 13 * unit, w: 6 * unit, h: 4.5 * unit, color: color)
                // Bottom-right diamond
                drawDiamond(in: &context, cx: 17 * unit, cy: 13 * unit, w: 6 * unit, h: 4.5 * unit, color: color)
                // Center bottom diamond (smaller)
                drawDiamond(in: &context, cx: 12 * unit, cy: 17.5 * unit, w: 6 * unit, h: 3.5 * unit, color: color)
            }
            .frame(width: size, height: size)
        }

        private func drawDiamond(in context: inout GraphicsContext, cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat, color: Color) {
            var path = Path()
            path.move(to: CGPoint(x: cx, y: cy - h))
            path.addLine(to: CGPoint(x: cx + w, y: cy))
            path.addLine(to: CGPoint(x: cx, y: cy + h))
            path.addLine(to: CGPoint(x: cx - w, y: cy))
            path.closeSubpath()
            context.fill(path, with: .color(color))
        }
    }

    /// Google Drive triangle logo rendered in SwiftUI
    struct GoogleDriveLogo: View {
        var size: CGFloat = 24

        var body: some View {
            Canvas { context, canvasSize in
                let s = min(canvasSize.width, canvasSize.height)
                let unit = s / 24

                // Google Drive: three overlapping parallelogram shapes
                // Green section (left triangle / top)
                var greenPath = Path()
                greenPath.move(to: CGPoint(x: 5 * unit, y: 20 * unit))
                greenPath.addLine(to: CGPoint(x: 12 * unit, y: 4 * unit))
                greenPath.addLine(to: CGPoint(x: 16 * unit, y: 4 * unit))
                greenPath.addLine(to: CGPoint(x: 9 * unit, y: 20 * unit))
                greenPath.closeSubpath()
                context.fill(greenPath, with: .color(Color(red: 0.0, green: 0.65, blue: 0.31))) // #00A650

                // Yellow section (bottom)
                var yellowPath = Path()
                yellowPath.move(to: CGPoint(x: 5 * unit, y: 20 * unit))
                yellowPath.addLine(to: CGPoint(x: 9 * unit, y: 20 * unit))
                yellowPath.addLine(to: CGPoint(x: 21 * unit, y: 20 * unit))
                yellowPath.addLine(to: CGPoint(x: 19 * unit, y: 16 * unit))
                yellowPath.addLine(to: CGPoint(x: 3 * unit, y: 16 * unit))
                yellowPath.closeSubpath()
                context.fill(yellowPath, with: .color(Color(red: 1.0, green: 0.73, blue: 0.0))) // #FFBA00

                // Blue section (right)
                var bluePath = Path()
                bluePath.move(to: CGPoint(x: 16 * unit, y: 4 * unit))
                bluePath.addLine(to: CGPoint(x: 21 * unit, y: 20 * unit))
                bluePath.addLine(to: CGPoint(x: 19 * unit, y: 16 * unit))
                bluePath.addLine(to: CGPoint(x: 14.5 * unit, y: 8 * unit))
                bluePath.closeSubpath()
                context.fill(bluePath, with: .color(Color(red: 0.25, green: 0.52, blue: 0.96))) // #4285F4
            }
            .frame(width: size, height: size)
        }
    }

    /// Proton Drive shield logo rendered in SwiftUI
    struct ProtonDriveLogo: View {
        var size: CGFloat = 24

        var body: some View {
            Canvas { context, canvasSize in
                let s = min(canvasSize.width, canvasSize.height)
                let unit = s / 24

                // Shield shape
                var shieldPath = Path()
                shieldPath.move(to: CGPoint(x: 12 * unit, y: 2 * unit))
                shieldPath.addLine(to: CGPoint(x: 21 * unit, y: 6 * unit))
                shieldPath.addQuadCurve(
                    to: CGPoint(x: 12 * unit, y: 22 * unit),
                    control: CGPoint(x: 21 * unit, y: 15 * unit)
                )
                shieldPath.addQuadCurve(
                    to: CGPoint(x: 3 * unit, y: 6 * unit),
                    control: CGPoint(x: 3 * unit, y: 15 * unit)
                )
                shieldPath.closeSubpath()

                // Proton purple gradient
                let gradient = Gradient(colors: [
                    Color(red: 0.43, green: 0.30, blue: 0.93), // #6D4DEE
                    Color(red: 0.55, green: 0.32, blue: 0.98)  // #8B52FA
                ])
                context.fill(shieldPath, with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: s, y: s)))

                // Arrow inside the shield pointing up-right
                var arrowPath = Path()
                arrowPath.move(to: CGPoint(x: 9 * unit, y: 15 * unit))
                arrowPath.addLine(to: CGPoint(x: 15 * unit, y: 9 * unit))
                arrowPath.addLine(to: CGPoint(x: 15 * unit, y: 12.5 * unit))
                arrowPath.move(to: CGPoint(x: 15 * unit, y: 9 * unit))
                arrowPath.addLine(to: CGPoint(x: 11.5 * unit, y: 9 * unit))
                context.stroke(arrowPath, with: .color(.white), style: StrokeStyle(lineWidth: 1.5 * unit, lineCap: .round, lineJoin: .round))
            }
            .frame(width: size, height: size)
        }
    }

    /// GoodReads "G" logo rendered in SwiftUI
    struct GoodReadsLogo: View {
        var size: CGFloat = 24

        var body: some View {
            ZStack {
                Circle()
                    .fill(Color(red: 0.88, green: 0.82, blue: 0.71)) // GoodReads tan #E0D2B4
                    .frame(width: size, height: size)

                Text("g")
                    .font(.system(size: size * 0.6, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 0.24, green: 0.20, blue: 0.16)) // Dark brown
                    .offset(y: -size * 0.02)
            }
        }
    }

    // MARK: - Branded Icon Wrapper

    /// Wraps a brand logo in a rounded-rect container with brand-colored background
    struct BrandIcon: View {
        let brand: Brand
        var size: CGFloat = 40

        enum Brand {
            case dropbox
            case googleDrive
            case protonDrive
            case goodReads
        }

        var body: some View {
            Group {
                switch brand {
                case .dropbox:
                    DropboxLogo(size: size * 0.55)
                        .frame(width: size, height: size)
                        .background(Color(red: 0.0, green: 0.38, blue: 1.0).opacity(0.15))
                case .googleDrive:
                    GoogleDriveLogo(size: size * 0.55)
                        .frame(width: size, height: size)
                        .background(Color(red: 0.25, green: 0.52, blue: 0.96).opacity(0.15))
                case .protonDrive:
                    ProtonDriveLogo(size: size * 0.55)
                        .frame(width: size, height: size)
                        .background(Color(red: 0.43, green: 0.30, blue: 0.93).opacity(0.15))
                case .goodReads:
                    GoodReadsLogo(size: size * 0.55)
                        .frame(width: size, height: size)
                        .background(Color(red: 0.88, green: 0.82, blue: 0.71).opacity(0.15))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
        }

        /// Maps a CloudStorageProvider to the corresponding Brand
        static func brand(for provider: CloudStorageProvider) -> Brand {
            switch provider {
            case .dropbox: return .dropbox
            case .googleDrive: return .googleDrive
            case .protonDrive: return .protonDrive
            }
        }
    }
}

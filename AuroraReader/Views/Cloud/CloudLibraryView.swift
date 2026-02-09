import SwiftUI

struct CloudLibraryView: View {
    @State private var cloudManager = CloudStorageManager.shared
    @State private var selectedProvider: CloudStorageProvider?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                // Aurora background glow
                Circle()
                    .fill(AuroraTheme.auroraBlue.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 100, y: -200)
                    .ignoresSafeArea()

                if cloudManager.connectedProviders.isEmpty {
                    connectProvidersView
                } else if let provider = selectedProvider {
                    fileBrowserView(for: provider)
                } else {
                    providerSelectionView
                }
            }
            .navigationTitle("Cloud Library")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search cloud files")
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - No Providers Connected

    private var connectProvidersView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AuroraTheme.auroraBlue.opacity(0.1))
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(AuroraTheme.auroraPurple.opacity(0.08))
                    .frame(width: 160, height: 160)
                BrandAssets.DropboxLogo(size: 44)
                    .opacity(0.7)
            }

            Text("Connect Cloud Storage")
                .font(.title2.weight(.bold))
                .foregroundStyle(AuroraTheme.textPrimary)

            Text("Import books directly from your cloud storage accounts.")
                .font(.subheadline)
                .foregroundStyle(AuroraTheme.textSecondary)
                .multilineTextAlignment(.center)

            Text("COMING SOON")
                .font(.caption2.weight(.bold))
                .foregroundStyle(AuroraTheme.auroraTeal)
                .tracking(1.5)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(AuroraTheme.auroraTeal.opacity(0.12), in: Capsule())

            Text("Cloud storage integration is being finalized.\nYou can import books from the Files app via the Library tab.")
                .font(.caption)
                .foregroundStyle(AuroraTheme.textTertiary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(CloudStorageProvider.allCases) { provider in
                    cloudProviderButton(provider)
                }
            }
            .padding(.top, 8)
        }
        .padding(40)
    }

    // MARK: - Provider Selection

    private var providerSelectionView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Connected providers
                ForEach(Array(cloudManager.connectedProviders), id: \.self) { provider in
                    Button {
                        selectedProvider = provider
                    } label: {
                        HStack(spacing: 16) {
                            BrandAssets.BrandIcon(brand: BrandAssets.BrandIcon.brand(for: provider), size: 44)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(provider.displayName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(AuroraTheme.textPrimary)
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundStyle(AuroraTheme.auroraGreen)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(AuroraTheme.textTertiary)
                        }
                        .padding(16)
                        .auroraCard()
                    }
                }

                // Disconnected providers
                let disconnected = CloudStorageProvider.allCases.filter { !cloudManager.connectedProviders.contains($0) }
                if !disconnected.isEmpty {
                    Text("Add More")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)
                        .padding(.top, 8)

                    ForEach(disconnected) { provider in
                        cloudProviderButton(provider)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - File Browser

    private func fileBrowserView(for provider: CloudStorageProvider) -> some View {
        VStack {
            if cloudManager.isLoading {
                ProgressView()
                    .tint(AuroraTheme.auroraTeal)
            } else if cloudManager.currentFiles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.circle.fill")
                        .font(.largeTitle)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AuroraTheme.textTertiary)
                    Text("No ebook files found")
                        .foregroundStyle(AuroraTheme.textSecondary)
                    Text("Upload EPUB, PDF, MOBI, or other supported formats to your \(provider.displayName)")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            } else {
                List(cloudManager.currentFiles.filter { $0.isSupported }) { file in
                    HStack(spacing: 12) {
                        Image(systemName: file.bookFormat?.iconName ?? "doc")
                            .foregroundStyle(AuroraTheme.auroraTeal)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.name)
                                .foregroundStyle(AuroraTheme.textPrimary)
                                .lineLimit(1)
                            HStack {
                                Text(file.bookFormat?.displayName ?? "Unknown")
                                    .font(.caption)
                                    .foregroundStyle(AuroraTheme.auroraTeal)
                                Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                                    .font(.caption)
                                    .foregroundStyle(AuroraTheme.textTertiary)
                            }
                        }

                        Spacer()

                        Image(systemName: "arrow.down.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AuroraTheme.auroraGreen)
                    }
                    .listRowBackground(AuroraTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    selectedProvider = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(AuroraTheme.auroraTeal)
                }
            }
        }
    }

    // MARK: - Helpers

    private func cloudProviderButton(_ provider: CloudStorageProvider) -> some View {
        Button {
            Task {
                try? await cloudManager.connect(provider)
                selectedProvider = provider
            }
        } label: {
            HStack(spacing: 16) {
                BrandAssets.BrandIcon(brand: BrandAssets.BrandIcon.brand(for: provider), size: 40)

                Text("Connect \(provider.displayName)")
                    .font(.body.weight(.medium))
                    .foregroundStyle(AuroraTheme.textPrimary)

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AuroraTheme.auroraTeal)
            }
            .padding(16)
            .auroraCard()
        }
    }
}

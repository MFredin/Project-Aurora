import SwiftUI

struct ReaderSettingsSheet: View {
    @Bindable var preferences: UserPreferences
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                Form {
                    // Font Size
                    Section("Font Size") {
                        HStack {
                            Text("A")
                                .font(.system(size: 14))
                                .foregroundStyle(AuroraTheme.textSecondary)

                            Slider(value: $preferences.fontSizeRaw, in: 12...32, step: 1)
                                .tint(AuroraTheme.auroraTeal)

                            Text("A")
                                .font(.system(size: 24))
                                .foregroundStyle(AuroraTheme.textSecondary)
                        }

                        Text("Current: \(Int(preferences.fontSizeRaw))pt")
                            .font(.caption)
                            .foregroundStyle(AuroraTheme.textTertiary)
                    }
                    .listRowBackground(AuroraTheme.surface)

                    // Font Family
                    Section("Font") {
                        Picker("Font Family", selection: $preferences.fontFamily) {
                            ForEach(UserPreferences.availableFonts, id: \.self) { font in
                                Text(font)
                                    .font(.custom(font, size: 16))
                                    .tag(font)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        .foregroundStyle(AuroraTheme.textPrimary)
                    }
                    .listRowBackground(AuroraTheme.surface)

                    // Line Spacing
                    Section("Line Spacing") {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.caption)
                                .foregroundStyle(AuroraTheme.textSecondary)
                            Slider(value: $preferences.lineSpacing, in: 1.0...2.5, step: 0.1)
                                .tint(AuroraTheme.auroraTeal)
                            Image(systemName: "line.3.horizontal")
                                .font(.body)
                                .foregroundStyle(AuroraTheme.textSecondary)
                        }
                        Text("Current: \(String(format: "%.1f", preferences.lineSpacing))x")
                            .font(.caption)
                            .foregroundStyle(AuroraTheme.textTertiary)
                    }
                    .listRowBackground(AuroraTheme.surface)

                    // Margin
                    Section("Margins") {
                        Slider(value: $preferences.marginSize, in: 8...40, step: 4)
                            .tint(AuroraTheme.auroraTeal)
                        Text("Current: \(Int(preferences.marginSize))pt")
                            .font(.caption)
                            .foregroundStyle(AuroraTheme.textTertiary)
                    }
                    .listRowBackground(AuroraTheme.surface)

                    // Theme
                    Section("Theme") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(ReaderTheme.allCases, id: \.self) { theme in
                                ThemeButton(
                                    theme: theme,
                                    isSelected: preferences.theme == theme
                                ) {
                                    preferences.theme = theme
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(AuroraTheme.surface)

                    // Reading Options
                    Section("Reading") {
                        Toggle("Keep Screen Awake", isOn: $preferences.keepScreenAwake)
                            .foregroundStyle(AuroraTheme.textPrimary)
                            .tint(AuroraTheme.auroraTeal)
                    }
                    .listRowBackground(AuroraTheme.surface)

                    // Preview
                    Section("Preview") {
                        Text("The quick brown fox jumps over the lazy dog. This is a preview of how your text will appear while reading.")
                            .font(.custom(preferences.fontFamily, size: preferences.fontSize))
                            .lineSpacing(preferences.fontSize * CGFloat(preferences.lineSpacing - 1.0))
                            .foregroundStyle(preferences.theme.textColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(preferences.theme.backgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .listRowBackground(AuroraTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Reader Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AuroraTheme.auroraTeal)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ThemeButton: View {
    let theme: ReaderTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.backgroundColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isSelected ? AuroraTheme.auroraTeal : AuroraTheme.textTertiary.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    }
                    .frame(height: 44)
                    .overlay {
                        Text("Aa")
                            .font(.caption)
                            .foregroundStyle(theme.textColor)
                    }

                Text(theme.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? AuroraTheme.auroraTeal : AuroraTheme.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

import SwiftUI
import SwiftData

/// View for browsing, filtering, and exporting highlights & annotations
struct AnnotationsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Highlight.dateCreated, order: .reverse) private var allHighlights: [Highlight]

    let book: Book?
    let onNavigateToHighlight: ((Highlight) -> Void)?

    @State private var selectedColor: HighlightColor?
    @State private var showNotesOnly = false
    @State private var searchText = ""
    @State private var showExportSheet = false
    @State private var editingHighlight: Highlight?

    init(book: Book? = nil, onNavigateToHighlight: ((Highlight) -> Void)? = nil) {
        self.book = book
        self.onNavigateToHighlight = onNavigateToHighlight
    }

    private var filteredHighlights: [Highlight] {
        var result = allHighlights

        // Filter by book if specified
        if let book {
            result = result.filter { $0.book?.id == book.id }
        }

        // Filter by color
        if let color = selectedColor {
            result = result.filter { $0.highlightColor == color }
        }

        // Filter notes only
        if showNotesOnly {
            result = result.filter { $0.hasNote }
        }

        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.highlightedText.lowercased().contains(query) ||
                $0.note.lowercased().contains(query) ||
                $0.tags.contains { $0.lowercased().contains(query) }
            }
        }

        return result
    }

    var body: some View {
        ZStack {
            AuroraTheme.deepSpace.ignoresSafeArea()

            if filteredHighlights.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        filterBar
                        highlightsList
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle(book != nil ? "Annotations" : "All Annotations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search highlights & notes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up.circle.fill")
                    }
                    Toggle("Notes Only", isOn: $showNotesOnly)
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AuroraTheme.auroraTeal)
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportAnnotationsSheet(highlights: filteredHighlights)
        }
        .sheet(item: $editingHighlight) { highlight in
            EditAnnotationSheet(highlight: highlight)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All colors
                FilterChip(title: "All", isSelected: selectedColor == nil) {
                    selectedColor = nil
                }

                // Color filters
                ForEach(HighlightColor.allCases) { color in
                    FilterChip(
                        title: color.displayName,
                        isSelected: selectedColor == color,
                        accentColor: color.color
                    ) {
                        selectedColor = selectedColor == color ? nil : color
                    }
                }
            }
        }
    }

    // MARK: - Highlights List

    private var highlightsList: some View {
        LazyVStack(spacing: 10) {
            ForEach(filteredHighlights) { highlight in
                HighlightRow(highlight: highlight) {
                    onNavigateToHighlight?(highlight)
                    dismiss()
                } onEdit: {
                    editingHighlight = highlight
                } onDelete: {
                    deleteHighlight(highlight)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "highlighter")
                .font(.system(size: 44))
                .foregroundStyle(AuroraTheme.textTertiary)

            Text("No Annotations Yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AuroraTheme.textPrimary)

            Text("Select text while reading to add highlights and notes")
                .font(.subheadline)
                .foregroundStyle(AuroraTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private func deleteHighlight(_ highlight: Highlight) {
        modelContext.delete(highlight)
        try? modelContext.save()
    }
}

// MARK: - Highlight Row

struct HighlightRow: View {
    let highlight: Highlight
    let onNavigate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Color bar + text
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(highlight.highlightColor.color)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text(highlight.textPreview)
                        .font(.subheadline)
                        .foregroundStyle(AuroraTheme.textPrimary)
                        .italic()

                    if highlight.hasNote {
                        HStack(spacing: 4) {
                            Image(systemName: "note.text")
                                .font(.caption2)
                            Text(highlight.note)
                                .font(.caption)
                        }
                        .foregroundStyle(AuroraTheme.textSecondary)
                        .lineLimit(2)
                    }

                    // Tags
                    if !highlight.tags.isEmpty {
                        FlowLayout(spacing: 4) {
                            ForEach(highlight.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(AuroraTheme.auroraTeal)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AuroraTheme.auroraTeal.opacity(0.12), in: Capsule())
                            }
                        }
                    }

                    // Metadata
                    HStack(spacing: 8) {
                        if let bookTitle = highlight.book?.title {
                            Text(bookTitle)
                                .lineLimit(1)
                        }
                        Text("Ch. \(highlight.chapterIndex + 1)")
                        Spacer()
                        Text(highlight.dateCreated, style: .date)
                    }
                    .font(.caption2)
                    .foregroundStyle(AuroraTheme.textTertiary)
                }
            }
        }
        .padding(12)
        .auroraCard()
        .contentShape(Rectangle())
        .onTapGesture { onNavigate() }
        .contextMenu {
            Button { onEdit() } label: {
                Label("Edit Note", systemImage: "pencil.circle.fill")
            }
            Button { onNavigate() } label: {
                Label("Go to Highlight", systemImage: "arrow.right.circle.fill")
            }
            Divider()
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash.circle.fill")
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var accentColor: Color = AuroraTheme.auroraTeal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected && accentColor != AuroraTheme.auroraTeal {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 8, height: 8)
                }
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : AuroraTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? AnyShapeStyle(accentColor.opacity(0.8))
                    : AnyShapeStyle(AuroraTheme.surface),
                in: Capsule()
            )
        }
    }
}

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

// MARK: - Export Sheet

struct ExportAnnotationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let highlights: [Highlight]

    @State private var exportFormat: ExportFormat = .markdown

    enum ExportFormat: String, CaseIterable {
        case markdown = "Markdown"
        case plainText = "Plain Text"
        case json = "JSON"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                VStack(spacing: 20) {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    ScrollView {
                        Text(generateExport())
                            .font(.caption.monospaced())
                            .foregroundStyle(AuroraTheme.textPrimary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .auroraCard()
                    }

                    Button {
                        let text = generateExport()
                        UIPasteboard.general.string = text
                        dismiss()
                    } label: {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc.fill")
                    }
                    .buttonStyle(AuroraButtonStyle())
                }
                .padding()
            }
            .navigationTitle("Export Annotations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func generateExport() -> String {
        switch exportFormat {
        case .markdown:
            return generateMarkdown()
        case .plainText:
            return generatePlainText()
        case .json:
            return generateJSON()
        }
    }

    private func generateMarkdown() -> String {
        var output = "# Annotations Export\n\n"
        let grouped = Dictionary(grouping: highlights) { $0.book?.title ?? "Unknown" }
        for (bookTitle, bookHighlights) in grouped.sorted(by: { $0.key < $1.key }) {
            output += "## \(bookTitle)\n\n"
            for h in bookHighlights {
                output += "> \(h.highlightedText)\n\n"
                if h.hasNote { output += "**Note:** \(h.note)\n\n" }
                if !h.tags.isEmpty { output += "Tags: \(h.tags.map { "#\($0)" }.joined(separator: " "))\n\n" }
                output += "---\n\n"
            }
        }
        return output
    }

    private func generatePlainText() -> String {
        highlights.map { h in
            var text = "\"\(h.highlightedText)\""
            if h.hasNote { text += "\n  Note: \(h.note)" }
            text += "\n  — \(h.book?.title ?? "Unknown"), Ch. \(h.chapterIndex + 1)"
            return text
        }.joined(separator: "\n\n")
    }

    private func generateJSON() -> String {
        let items: [[String: Any]] = highlights.map { h in
            [
                "text": h.highlightedText,
                "note": h.note,
                "color": h.highlightColor.rawValue,
                "book": h.book?.title ?? "",
                "chapter": h.chapterIndex,
                "tags": h.tags
            ] as [String: Any]
        }

        guard let data = try? JSONSerialization.data(withJSONObject: items, options: .prettyPrinted),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}

// MARK: - Edit Annotation Sheet

struct EditAnnotationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let highlight: Highlight

    @State private var noteText: String = ""
    @State private var selectedColor: HighlightColor = .auroraTeal
    @State private var newTag: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Highlighted text preview
                        Text(highlight.textPreview)
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(AuroraTheme.textPrimary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(selectedColor.backgroundColor, in: RoundedRectangle(cornerRadius: 8))

                        // Color picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Highlight Color")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AuroraTheme.textSecondary)

                            HStack(spacing: 12) {
                                ForEach(HighlightColor.allCases) { color in
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            if selectedColor == color {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .onTapGesture { selectedColor = color }
                                }
                            }
                        }

                        // Note editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AuroraTheme.textSecondary)

                            TextEditor(text: $noteText)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(AuroraTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(AuroraTheme.textPrimary)
                        }

                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AuroraTheme.textSecondary)

                            FlowLayout(spacing: 6) {
                                ForEach(highlight.tags, id: \.self) { tag in
                                    HStack(spacing: 2) {
                                        Text("#\(tag)")
                                            .font(.caption2)
                                        Button {
                                            highlight.removeTag(tag)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 8, weight: .bold))
                                        }
                                    }
                                    .foregroundStyle(AuroraTheme.auroraTeal)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AuroraTheme.auroraTeal.opacity(0.12), in: Capsule())
                                }
                            }

                            HStack {
                                TextField("Add tag", text: $newTag)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(AuroraTheme.textPrimary)
                                    .padding(8)
                                    .background(AuroraTheme.surface, in: RoundedRectangle(cornerRadius: 8))

                                Button {
                                    highlight.addTag(newTag)
                                    newTag = ""
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(AuroraTheme.auroraTeal)
                                }
                                .disabled(newTag.isEmpty)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Annotation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        highlight.updateNote(noteText)
                        highlight.highlightColor = selectedColor
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                noteText = highlight.note
                selectedColor = highlight.highlightColor
            }
        }
    }
}

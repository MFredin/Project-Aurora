import SwiftUI
import SwiftData

/// Interactive knowledge graph visualization
struct KnowledgeGraphView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var nodes: [KnowledgeNode]

    @State private var graphService = KnowledgeGraphService.shared
    @State private var selectedNode: KnowledgeNode?
    @State private var filterType: KnowledgeNode.NodeType?
    @State private var filterBook: String?
    @State private var showAddNode = false
    @State private var showSuggestions = false
    @State private var scale: CGFloat = 1.0

    private var filteredNodes: [KnowledgeNode] {
        var result = nodes
        if let type = filterType {
            result = result.filter { $0.type == type }
        }
        if let book = filterBook {
            result = result.filter { $0.sourceBookTitle == book }
        }
        return result
    }

    private var uniqueBooks: [String] {
        Array(Set(nodes.map(\.sourceBookTitle))).filter { !$0.isEmpty }.sorted()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                if nodes.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        filterBar
                        graphCanvas
                        if let node = selectedNode {
                            nodeDetailPanel(node)
                        }
                    }
                }
            }
            .navigationTitle("Knowledge Graph")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showAddNode = true
                        } label: {
                            Label("Add Node", systemImage: "plus.circle.fill")
                        }
                        Button {
                            showSuggestions = true
                        } label: {
                            Label("Discover Connections", systemImage: "sparkle.magnifyingglass")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AuroraTheme.auroraTeal)
                    }
                }
            }
            .sheet(isPresented: $showAddNode) {
                AddKnowledgeNodeSheet()
            }
            .sheet(isPresented: $showSuggestions) {
                ConnectionSuggestionsView(nodes: filteredNodes)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterType == nil) {
                    filterType = nil
                }
                ForEach(KnowledgeNode.NodeType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.displayName,
                        isSelected: filterType == type,
                        accentColor: colorForType(type)
                    ) {
                        filterType = filterType == type ? nil : type
                    }
                }

                Divider()
                    .frame(height: 20)
                    .overlay(AuroraTheme.textTertiary)

                ForEach(uniqueBooks, id: \.self) { book in
                    FilterChip(
                        title: book,
                        isSelected: filterBook == book,
                        accentColor: AuroraTheme.auroraPurple
                    ) {
                        filterBook = filterBook == book ? nil : book
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Graph Canvas

    private var graphCanvas: some View {
        GeometryReader { geo in
            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    // Draw links
                    ForEach(filteredNodes) { node in
                        ForEach(node.linkedNodeIds, id: \.self) { linkedId in
                            if let linkedNode = filteredNodes.first(where: { $0.id == linkedId }) {
                                Path { path in
                                    path.move(to: CGPoint(x: node.positionX + 40, y: node.positionY + 20))
                                    path.addLine(to: CGPoint(x: linkedNode.positionX + 40, y: linkedNode.positionY + 20))
                                }
                                .stroke(AuroraTheme.textTertiary.opacity(0.3), lineWidth: 1)
                            }
                        }
                    }

                    // Draw nodes
                    ForEach(filteredNodes) { node in
                        graphNode(node)
                            .position(x: node.positionX + 40, y: node.positionY + 20)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        node.positionX = value.location.x - 40
                                        node.positionY = value.location.y - 20
                                    }
                                    .onEnded { _ in
                                        try? modelContext.save()
                                    }
                            )
                    }
                }
                .frame(width: max(geo.size.width, 800), height: max(geo.size.height, 600))
                .scaleEffect(scale)
            }
        }
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = min(3.0, max(0.3, value))
                }
        )
    }

    private func graphNode(_ node: KnowledgeNode) -> some View {
        Button {
            withAnimation { selectedNode = selectedNode?.id == node.id ? nil : node }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: node.type.iconName)
                    .font(.body)
                    .foregroundStyle(colorForType(node.type))

                Text(node.title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AuroraTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 80)
            }
            .padding(8)
            .background(
                selectedNode?.id == node.id
                    ? colorForType(node.type).opacity(0.2)
                    : AuroraTheme.surface.opacity(0.9),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        selectedNode?.id == node.id
                            ? colorForType(node.type).opacity(0.6)
                            : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
    }

    // MARK: - Node Detail Panel

    private func nodeDetailPanel(_ node: KnowledgeNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: node.type.iconName)
                    .foregroundStyle(colorForType(node.type))
                Text(node.title)
                    .font(.headline)
                    .foregroundStyle(AuroraTheme.textPrimary)
                Spacer()
                Button {
                    withAnimation { selectedNode = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AuroraTheme.textTertiary)
                }
            }

            if !node.content.isEmpty {
                Text(node.content)
                    .font(.caption)
                    .foregroundStyle(AuroraTheme.textSecondary)
                    .lineLimit(3)
            }

            HStack(spacing: 12) {
                Label(node.type.displayName, systemImage: node.type.iconName)
                if !node.sourceBookTitle.isEmpty {
                    Label(node.sourceBookTitle, systemImage: "book.fill")
                }
                Label("\(node.linkedNodeIds.count) links", systemImage: "link")
            }
            .font(.caption2)
            .foregroundStyle(AuroraTheme.textTertiary)

            if !node.tags.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(node.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundStyle(AuroraTheme.auroraTeal)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AuroraTheme.auroraTeal.opacity(0.12), in: Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .transition(.move(edge: .bottom))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile.fill")
                .font(.system(size: 44))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AuroraTheme.textTertiary)

            Text("Your Knowledge Graph")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AuroraTheme.textPrimary)

            Text("Highlight text while reading and add it to your knowledge graph to build connections across books")
                .font(.subheadline)
                .foregroundStyle(AuroraTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private func colorForType(_ type: KnowledgeNode.NodeType) -> Color {
        switch type {
        case .concept: return AuroraTheme.auroraTeal
        case .character: return AuroraTheme.auroraPurple
        case .theme: return AuroraTheme.auroraPink
        case .quote: return AuroraTheme.auroraWarm
        case .idea: return AuroraTheme.auroraGreen
        case .reference: return AuroraTheme.auroraBlue
        }
    }
}

// MARK: - Add Node Sheet

struct AddKnowledgeNodeSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var selectedType: KnowledgeNode.NodeType = .concept
    @State private var tags = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        TextField("Title", text: $title)
                            .textFieldStyle(.plain)
                            .foregroundStyle(AuroraTheme.textPrimary)
                            .padding(12)
                            .background(AuroraTheme.surface, in: RoundedRectangle(cornerRadius: 8))

                        // Type picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AuroraTheme.textSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(KnowledgeNode.NodeType.allCases, id: \.self) { type in
                                        Button {
                                            selectedType = type
                                        } label: {
                                            Label(type.displayName, systemImage: type.iconName)
                                                .font(.caption)
                                                .foregroundStyle(selectedType == type ? .white : AuroraTheme.textSecondary)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(
                                                    selectedType == type
                                                        ? AnyShapeStyle(AuroraTheme.accentGradient)
                                                        : AnyShapeStyle(AuroraTheme.surface),
                                                    in: Capsule()
                                                )
                                        }
                                    }
                                }
                            }
                        }

                        TextEditor(text: $content)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(AuroraTheme.textPrimary)
                            .padding(8)
                            .background(AuroraTheme.surface, in: RoundedRectangle(cornerRadius: 8))

                        TextField("Tags (comma separated)", text: $tags)
                            .textFieldStyle(.plain)
                            .foregroundStyle(AuroraTheme.textPrimary)
                            .padding(12)
                            .background(AuroraTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .padding()
                }
            }
            .navigationTitle("New Node")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let node = KnowledgeNode(title: title, type: selectedType, content: content)
                        node.tags = tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        modelContext.insert(node)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Connection Suggestions

struct ConnectionSuggestionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let nodes: [KnowledgeNode]
    @State private var graphService = KnowledgeGraphService.shared

    private var suggestions: [(KnowledgeNode, KnowledgeNode, Double)] {
        graphService.discoverConnections(nodes: nodes)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                if suggestions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkle.magnifyingglass")
                            .font(.title)
                            .foregroundStyle(AuroraTheme.textTertiary)
                        Text("No connections found")
                            .font(.subheadline)
                            .foregroundStyle(AuroraTheme.textSecondary)
                        Text("Add more nodes to discover connections")
                            .font(.caption)
                            .foregroundStyle(AuroraTheme.textTertiary)
                    }
                } else {
                    List {
                        ForEach(Array(suggestions.prefix(20).enumerated()), id: \.offset) { _, suggestion in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(suggestion.0.title) \u{2194} \(suggestion.1.title)")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(AuroraTheme.textPrimary)
                                    Text("Similarity: \(Int(suggestion.2 * 100))%")
                                        .font(.caption)
                                        .foregroundStyle(AuroraTheme.textTertiary)
                                }

                                Spacer()

                                Button {
                                    graphService.linkNodes(suggestion.0, suggestion.1, modelContext: modelContext)
                                } label: {
                                    Image(systemName: "link.circle.fill")
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(AuroraTheme.auroraGreen)
                                }
                            }
                            .listRowBackground(AuroraTheme.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Suggested Connections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

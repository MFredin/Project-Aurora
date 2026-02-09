import Foundation
import SwiftData

/// Service for building and managing the cross-book knowledge graph
@Observable
final class KnowledgeGraphService {
    static let shared = KnowledgeGraphService()

    var isProcessing: Bool = false

    private init() {}

    // MARK: - Node Management

    /// Creates a knowledge node from a highlight
    func createNode(
        from highlight: Highlight,
        type: KnowledgeNode.NodeType,
        modelContext: ModelContext
    ) -> KnowledgeNode {
        let node = KnowledgeNode(
            title: String(highlight.highlightedText.prefix(50)),
            type: type,
            content: highlight.highlightedText,
            sourceBookTitle: highlight.book?.title ?? "",
            sourceChapter: highlight.chapterTitle
        )
        node.highlight = highlight
        node.book = highlight.book
        node.tags = highlight.tags
        modelContext.insert(node)
        try? modelContext.save()
        return node
    }

    /// Creates a standalone knowledge node
    func createNode(
        title: String,
        type: KnowledgeNode.NodeType,
        content: String = "",
        book: Book? = nil,
        chapter: String = "",
        modelContext: ModelContext
    ) -> KnowledgeNode {
        let node = KnowledgeNode(
            title: title,
            type: type,
            content: content,
            sourceBookTitle: book?.title ?? "",
            sourceChapter: chapter
        )
        node.book = book
        modelContext.insert(node)
        try? modelContext.save()
        return node
    }

    /// Links two knowledge nodes together
    func linkNodes(_ node1: KnowledgeNode, _ node2: KnowledgeNode, modelContext: ModelContext) {
        node1.linkTo(node2)
        try? modelContext.save()
    }

    // MARK: - Auto-Discovery

    /// Finds potential connections between nodes based on shared keywords
    func discoverConnections(nodes: [KnowledgeNode]) -> [(KnowledgeNode, KnowledgeNode, Double)] {
        var connections: [(KnowledgeNode, KnowledgeNode, Double)] = []

        for i in 0..<nodes.count {
            for j in (i+1)..<nodes.count {
                let node1 = nodes[i]
                let node2 = nodes[j]

                // Skip already linked
                guard !node1.linkedNodeIds.contains(node2.id) else { continue }

                let similarity = calculateSimilarity(node1, node2)
                if similarity > 0.3 {
                    connections.append((node1, node2, similarity))
                }
            }
        }

        return connections.sorted { $0.2 > $1.2 }
    }

    /// Auto-generates nodes from book highlights
    func autoGenerateNodes(
        from highlights: [Highlight],
        existingNodes: [KnowledgeNode],
        modelContext: ModelContext
    ) -> [KnowledgeNode] {
        isProcessing = true
        defer { isProcessing = false }

        var newNodes: [KnowledgeNode] = []
        let existingTitles = Set(existingNodes.map(\.title.lowercased))

        for highlight in highlights {
            let title = String(highlight.highlightedText.prefix(50))
            guard !existingTitles.contains(title.lowercased()) else { continue }

            let type = inferNodeType(from: highlight.highlightedText)
            let node = KnowledgeNode(
                title: title,
                type: type,
                content: highlight.highlightedText,
                sourceBookTitle: highlight.book?.title ?? "",
                sourceChapter: highlight.chapterTitle
            )
            node.highlight = highlight
            node.book = highlight.book
            node.tags = highlight.tags
            modelContext.insert(node)
            newNodes.append(node)
        }

        try? modelContext.save()
        return newNodes
    }

    // MARK: - Graph Queries

    /// Gets all nodes connected to a specific node (1 degree)
    func getConnectedNodes(for node: KnowledgeNode, allNodes: [KnowledgeNode]) -> [KnowledgeNode] {
        allNodes.filter { node.linkedNodeIds.contains($0.id) }
    }

    /// Gets nodes filtered by type
    func getNodes(ofType type: KnowledgeNode.NodeType, from nodes: [KnowledgeNode]) -> [KnowledgeNode] {
        nodes.filter { $0.type == type }
    }

    /// Gets nodes from a specific book
    func getNodes(forBook bookTitle: String, from nodes: [KnowledgeNode]) -> [KnowledgeNode] {
        nodes.filter { $0.sourceBookTitle == bookTitle }
    }

    // MARK: - Graph Statistics

    func graphStats(nodes: [KnowledgeNode]) -> GraphStats {
        let totalLinks = nodes.reduce(0) { $0 + $1.linkedNodeIds.count } / 2 // bidirectional
        let bookCount = Set(nodes.map(\.sourceBookTitle)).count
        let typeCounts = Dictionary(grouping: nodes, by: \.type).mapValues(\.count)

        return GraphStats(
            totalNodes: nodes.count,
            totalLinks: totalLinks,
            bookCount: bookCount,
            typeCounts: typeCounts
        )
    }

    // MARK: - Private Helpers

    private func calculateSimilarity(_ node1: KnowledgeNode, _ node2: KnowledgeNode) -> Double {
        var score: Double = 0

        // Shared tags
        let tags1 = Set(node1.tags)
        let tags2 = Set(node2.tags)
        let sharedTags = tags1.intersection(tags2).count
        score += Double(sharedTags) * 0.3

        // Same type bonus
        if node1.type == node2.type { score += 0.1 }

        // Content word overlap
        let words1 = Set(node1.content.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { $0.count > 4 })
        let words2 = Set(node2.content.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { $0.count > 4 })
        let overlap = words1.intersection(words2).count
        let union = words1.union(words2).count
        if union > 0 {
            score += Double(overlap) / Double(union) * 0.5
        }

        // Cross-book bonus (more interesting connections)
        if node1.sourceBookTitle != node2.sourceBookTitle && !node1.sourceBookTitle.isEmpty && !node2.sourceBookTitle.isEmpty {
            score += 0.15
        }

        return min(score, 1.0)
    }

    private func inferNodeType(from text: String) -> KnowledgeNode.NodeType {
        let lowered = text.lowercased()
        if lowered.contains("\"") || lowered.contains("\u{201C}") { return .quote }
        if text.first?.isUppercase == true && text.split(separator: " ").count <= 3 { return .character }
        if lowered.contains("theme") || lowered.contains("moral") || lowered.contains("meaning") { return .theme }
        return .concept
    }
}

struct GraphStats {
    let totalNodes: Int
    let totalLinks: Int
    let bookCount: Int
    let typeCounts: [KnowledgeNode.NodeType: Int]
}

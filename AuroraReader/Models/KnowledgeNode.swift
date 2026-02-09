import Foundation
import SwiftData

/// A node in the cross-book knowledge graph
@Model
final class KnowledgeNode {
    var id: UUID
    var title: String
    var nodeType: String
    var content: String
    var sourceBookTitle: String
    var sourceChapter: String
    var dateCreated: Date
    var linkedNodeIds: [UUID]
    var tags: [String]
    var positionX: Double
    var positionY: Double

    @Relationship var book: Book?
    @Relationship var highlight: Highlight?

    var type: NodeType {
        get { NodeType(rawValue: nodeType) ?? .concept }
        set { nodeType = newValue.rawValue }
    }

    init(
        title: String,
        type: NodeType = .concept,
        content: String = "",
        sourceBookTitle: String = "",
        sourceChapter: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.nodeType = type.rawValue
        self.content = content
        self.sourceBookTitle = sourceBookTitle
        self.sourceChapter = sourceChapter
        self.dateCreated = Date()
        self.linkedNodeIds = []
        self.tags = []
        self.positionX = Double.random(in: 50...300)
        self.positionY = Double.random(in: 50...500)
    }

    func linkTo(_ node: KnowledgeNode) {
        if !linkedNodeIds.contains(node.id) {
            linkedNodeIds.append(node.id)
        }
        if !node.linkedNodeIds.contains(id) {
            node.linkedNodeIds.append(id)
        }
    }

    enum NodeType: String, Codable, CaseIterable {
        case concept
        case character
        case theme
        case quote
        case idea
        case reference

        var iconName: String {
            switch self {
            case .concept: return "lightbulb.circle.fill"
            case .character: return "person.circle.fill"
            case .theme: return "paintpalette.fill"
            case .quote: return "quote.opening"
            case .idea: return "brain.head.profile.fill"
            case .reference: return "link.circle.fill"
            }
        }

        var displayName: String {
            rawValue.capitalized
        }
    }
}

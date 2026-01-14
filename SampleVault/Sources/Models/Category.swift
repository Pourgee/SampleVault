//
//  Category.swift
//  SampleVault
//
//  Data model for sample categories
//

import Foundation

enum CategoryType: String, Codable, CaseIterable {
    case drums = "Drums"
    case bass = "Bass"
    case synths = "Synths"
    case vocals = "Vocals"
    case fx = "FX"
    case loops = "Loops"
    case oneShots = "One-shots"
    case uncategorized = "Uncategorized"

    var subcategories: [String] {
        switch self {
        case .drums:
            return ["Kicks", "Snares", "Hats", "Percussion", "Fills"]
        case .synths:
            return ["Leads", "Pads", "Plucks", "Stabs"]
        case .vocals:
            return ["Chops", "Phrases", "Ad-libs"]
        case .fx:
            return ["Risers", "Downlifters", "Impacts", "Textures"]
        default:
            return []
        }
    }

    var icon: String {
        switch self {
        case .drums: return "🥁"
        case .bass: return "🎸"
        case .synths: return "🎹"
        case .vocals: return "🎤"
        case .fx: return "✨"
        case .loops: return "🔁"
        case .oneShots: return "⚡"
        case .uncategorized: return "📦"
        }
    }
}

struct Category: Codable, Identifiable, Hashable {
    let id: UUID
    let type: CategoryType
    let subcategory: String?
    let isUserCreated: Bool

    init(type: CategoryType, subcategory: String? = nil, isUserCreated: Bool = false) {
        self.id = UUID()
        self.type = type
        self.subcategory = subcategory
        self.isUserCreated = isUserCreated
    }

    var displayName: String {
        if let subcategory = subcategory {
            return "\(type.rawValue) / \(subcategory)"
        }
        return type.rawValue
    }
}

//
//  Tag.swift
//  SampleVault
//
//  Data model for sample tags
//

import Foundation

struct Tag: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let color: String?
    let isUserCreated: Bool
    let dateCreated: Date

    init(name: String, color: String? = nil, isUserCreated: Bool = true) {
        self.id = UUID()
        self.name = name.lowercased()
        self.color = color
        self.isUserCreated = isUserCreated
        self.dateCreated = Date()
    }
}

// Default quick-tag palette
extension Tag {
    static let defaultTags: [Tag] = [
        Tag(name: "dark", isUserCreated: false),
        Tag(name: "punchy", isUserCreated: false),
        Tag(name: "lo-fi", isUserCreated: false),
        Tag(name: "vintage", isUserCreated: false),
        Tag(name: "bright", isUserCreated: false),
        Tag(name: "warm", isUserCreated: false),
        Tag(name: "aggressive", isUserCreated: false),
        Tag(name: "soft", isUserCreated: false),
        Tag(name: "atmospheric", isUserCreated: false),
        Tag(name: "rhythmic", isUserCreated: false),
        Tag(name: "melodic", isUserCreated: false),
        Tag(name: "textural", isUserCreated: false)
    ]
}

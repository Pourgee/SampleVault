//
//  SmartFolder.swift
//  SampleVault
//
//  Data model for smart folders (saved searches)
//

import Foundation

struct SmartFolder: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var filters: SearchFilters
    var dateCreated: Date
    var dateModified: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.badge.gearshape",
        filters: SearchFilters,
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.filters = filters
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }
}

// MARK: - Search Filters
struct SearchFilters: Codable, Hashable {
    var query: String?
    var category: CategoryType?
    var subcategory: String?
    var tags: [String]?
    var isFavorite: Bool?
    var bpmMin: Int?
    var bpmMax: Int?
    var key: String?
    var durationMin: TimeInterval?
    var durationMax: TimeInterval?
    var sortBy: SortOption?

    init(
        query: String? = nil,
        category: CategoryType? = nil,
        subcategory: String? = nil,
        tags: [String]? = nil,
        isFavorite: Bool? = nil,
        bpmMin: Int? = nil,
        bpmMax: Int? = nil,
        key: String? = nil,
        durationMin: TimeInterval? = nil,
        durationMax: TimeInterval? = nil,
        sortBy: SortOption? = nil
    ) {
        self.query = query
        self.category = category
        self.subcategory = subcategory
        self.tags = tags
        self.isFavorite = isFavorite
        self.bpmMin = bpmMin
        self.bpmMax = bpmMax
        self.key = key
        self.durationMin = durationMin
        self.durationMax = durationMax
        self.sortBy = sortBy
    }

    var isEmpty: Bool {
        query == nil &&
        category == nil &&
        subcategory == nil &&
        (tags == nil || tags?.isEmpty == true) &&
        isFavorite == nil &&
        bpmMin == nil &&
        bpmMax == nil &&
        key == nil &&
        durationMin == nil &&
        durationMax == nil
    }

    var description: String {
        var parts: [String] = []

        if let query = query, !query.isEmpty {
            parts.append("'\(query)'")
        }
        if let category = category {
            parts.append(category.rawValue)
        }
        if let tags = tags, !tags.isEmpty {
            parts.append(tags.joined(separator: ", "))
        }
        if isFavorite == true {
            parts.append("Favorites")
        }
        if let bpmMin = bpmMin, let bpmMax = bpmMax {
            parts.append("\(bpmMin)-\(bpmMax) BPM")
        } else if let bpmMin = bpmMin {
            parts.append("≥\(bpmMin) BPM")
        } else if let bpmMax = bpmMax {
            parts.append("≤\(bpmMax) BPM")
        }
        if let key = key {
            parts.append("Key: \(key)")
        }

        return parts.isEmpty ? "No filters" : parts.joined(separator: " · ")
    }
}

// MARK: - Recent Search
struct RecentSearch: Identifiable, Codable {
    let id: UUID
    let query: String
    let filters: SearchFilters
    let date: Date
    var resultCount: Int

    init(
        id: UUID = UUID(),
        query: String,
        filters: SearchFilters,
        date: Date = Date(),
        resultCount: Int = 0
    ) {
        self.id = id
        self.query = query
        self.filters = filters
        self.date = date
        self.resultCount = resultCount
    }
}

// MARK: - Predefined Smart Folders
extension SmartFolder {
    static let recentlyAdded = SmartFolder(
        name: "Recently Added",
        icon: "clock",
        filters: SearchFilters(sortBy: .dateAdded)
    )

    static let recentlyPlayed = SmartFolder(
        name: "Recently Played",
        icon: "play.circle",
        filters: SearchFilters(sortBy: .lastPlayed)
    )

    static let favorites = SmartFolder(
        name: "Favorites",
        icon: "star.fill",
        filters: SearchFilters(isFavorite: true)
    )

    static let highBPM = SmartFolder(
        name: "High BPM (140+)",
        icon: "speedometer",
        filters: SearchFilters(bpmMin: 140)
    )

    static let lowBPM = SmartFolder(
        name: "Low BPM (<100)",
        icon: "tortoise",
        filters: SearchFilters(bpmMax: 100)
    )

    static let uncategorized = SmartFolder(
        name: "Uncategorized",
        icon: "questionmark.folder",
        filters: SearchFilters(category: .uncategorized)
    )

    static var predefined: [SmartFolder] {
        [recentlyAdded, recentlyPlayed, favorites, highBPM, lowBPM, uncategorized]
    }
}

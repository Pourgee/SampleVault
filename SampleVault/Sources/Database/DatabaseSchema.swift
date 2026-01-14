//
//  DatabaseSchema.swift
//  SampleVault
//
//  SQLite database schema using GRDB
//

import Foundation
import GRDB

// MARK: - Sample Database Record
struct SampleRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "samples"

    var id: String  // UUID as string
    var filename: String
    var path: String
    var bookmarkData: Data

    var fileSize: Int64
    var duration: Double
    var bpm: Int?
    var key: String?
    var waveformData: Data?

    var category: String?
    var subcategory: String?
    var notes: String?

    var isFavorite: Bool
    var playCount: Int
    var dateAdded: Date
    var lastPlayed: Date?

    // Define columns
    enum Columns: String, ColumnExpression {
        case id, filename, path, bookmarkData
        case fileSize, duration, bpm, key, waveformData
        case category, subcategory, notes
        case isFavorite, playCount, dateAdded, lastPlayed
    }
}

// MARK: - Tag Database Record
struct TagRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "tags"

    var id: String
    var name: String
    var color: String?
    var isUserCreated: Bool
    var dateCreated: Date

    enum Columns: String, ColumnExpression {
        case id, name, color, isUserCreated, dateCreated
    }
}

// MARK: - Sample-Tag Join Table
struct SampleTagRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "sample_tags"

    var sampleId: String
    var tagName: String

    enum Columns: String, ColumnExpression {
        case sampleId, tagName
    }
}

// MARK: - Database Migration
struct DatabaseMigrator {
    static func migrate(_ db: Database) throws {
        var migrator = GRDB.DatabaseMigrator()

        // v1: Initial schema
        migrator.registerMigration("v1_initial") { db in
            // Samples table
            try db.create(table: "samples") { t in
                t.column("id", .text).primaryKey()
                t.column("filename", .text).notNull()
                t.column("path", .text).notNull().unique()
                t.column("bookmarkData", .blob).notNull()

                t.column("fileSize", .integer).notNull()
                t.column("duration", .double).notNull()
                t.column("bpm", .integer)
                t.column("key", .text)
                t.column("waveformData", .blob)

                t.column("category", .text)
                t.column("subcategory", .text)
                t.column("notes", .text)

                t.column("isFavorite", .boolean).notNull().defaults(to: false)
                t.column("playCount", .integer).notNull().defaults(to: 0)
                t.column("dateAdded", .datetime).notNull()
                t.column("lastPlayed", .datetime)
            }

            // Indexes for performance
            try db.create(index: "idx_samples_filename", on: "samples", columns: ["filename"])
            try db.create(index: "idx_samples_category", on: "samples", columns: ["category"])
            try db.create(index: "idx_samples_favorite", on: "samples", columns: ["isFavorite"])
            try db.create(index: "idx_samples_dateAdded", on: "samples", columns: ["dateAdded"])

            // Tags table
            try db.create(table: "tags") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull().unique()
                t.column("color", .text)
                t.column("isUserCreated", .boolean).notNull()
                t.column("dateCreated", .datetime).notNull()
            }

            // Sample-Tags join table
            try db.create(table: "sample_tags") { t in
                t.column("sampleId", .text).notNull()
                    .references("samples", onDelete: .cascade)
                t.column("tagName", .text).notNull()
                    .references("tags", column: "name", onDelete: .cascade)
                t.primaryKey(["sampleId", "tagName"])
            }

            try db.create(index: "idx_sample_tags_sample", on: "sample_tags", columns: ["sampleId"])
            try db.create(index: "idx_sample_tags_tag", on: "sample_tags", columns: ["tagName"])

            // Full-text search index
            try db.create(virtualTable: "samples_fts", using: FTS5()) { t in
                t.column("filename")
                t.column("path")
                t.column("notes")
                t.column("category")
                t.column("subcategory")
            }

            // Insert default tags
            for tag in Tag.defaultTags {
                let record = TagRecord(
                    id: tag.id.uuidString,
                    name: tag.name,
                    color: tag.color,
                    isUserCreated: tag.isUserCreated,
                    dateCreated: tag.dateCreated
                )
                try record.insert(db)
            }
        }

        // v2: Smart folders and recent searches
        migrator.registerMigration("v2_smart_folders") { db in
            // Smart folders table
            try db.create(table: "smart_folders") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("icon", .text).notNull()
                t.column("filtersData", .blob).notNull()
                t.column("dateCreated", .datetime).notNull()
                t.column("dateModified", .datetime).notNull()
            }

            try db.create(index: "idx_smart_folders_name", on: "smart_folders", columns: ["name"])

            // Recent searches table
            try db.create(table: "recent_searches") { t in
                t.column("id", .text).primaryKey()
                t.column("query", .text).notNull()
                t.column("filtersData", .blob).notNull()
                t.column("date", .datetime).notNull()
                t.column("resultCount", .integer).notNull()
            }

            try db.create(index: "idx_recent_searches_date", on: "recent_searches", columns: ["date"])
        }

        try migrator.migrate(db)
    }
}

// MARK: - Conversion Extensions
extension Sample {
    init(from record: SampleRecord, tags: [String]) {
        self.init(
            id: UUID(uuidString: record.id) ?? UUID(),
            filename: record.filename,
            path: record.path,
            bookmarkData: record.bookmarkData,
            fileSize: record.fileSize,
            duration: record.duration,
            bpm: record.bpm,
            key: record.key,
            waveformData: record.waveformData,
            category: record.category.flatMap { CategoryType(rawValue: $0) },
            subcategory: record.subcategory,
            tags: tags,
            notes: record.notes,
            isFavorite: record.isFavorite,
            playCount: record.playCount,
            dateAdded: record.dateAdded,
            lastPlayed: record.lastPlayed
        )
    }

    func toRecord() -> SampleRecord {
        SampleRecord(
            id: id.uuidString,
            filename: filename,
            path: path,
            bookmarkData: bookmarkData,
            fileSize: fileSize,
            duration: duration,
            bpm: bpm,
            key: key,
            waveformData: waveformData,
            category: category?.rawValue,
            subcategory: subcategory,
            notes: notes,
            isFavorite: isFavorite,
            playCount: playCount,
            dateAdded: dateAdded,
            lastPlayed: lastPlayed
        )
    }
}

extension Tag {
    init(from record: TagRecord) {
        self.init(
            name: record.name,
            color: record.color,
            isUserCreated: record.isUserCreated
        )
    }

    func toRecord() -> TagRecord {
        TagRecord(
            id: id.uuidString,
            name: name,
            color: color,
            isUserCreated: isUserCreated,
            dateCreated: dateCreated
        )
    }
}

// MARK: - Smart Folder Database Record
struct SmartFolderRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "smart_folders"

    var id: String
    var name: String
    var icon: String
    var filtersData: Data
    var dateCreated: Date
    var dateModified: Date

    enum Columns: String, ColumnExpression {
        case id, name, icon, filtersData, dateCreated, dateModified
    }
}

extension SmartFolder {
    init(from record: SmartFolderRecord) throws {
        let filters = try JSONDecoder().decode(SearchFilters.self, from: record.filtersData)
        self.init(
            id: UUID(uuidString: record.id) ?? UUID(),
            name: record.name,
            icon: record.icon,
            filters: filters,
            dateCreated: record.dateCreated,
            dateModified: record.dateModified
        )
    }

    func toRecord() throws -> SmartFolderRecord {
        let filtersData = try JSONEncoder().encode(filters)
        return SmartFolderRecord(
            id: id.uuidString,
            name: name,
            icon: icon,
            filtersData: filtersData,
            dateCreated: dateCreated,
            dateModified: dateModified
        )
    }
}

// MARK: - Recent Search Database Record
struct RecentSearchRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "recent_searches"

    var id: String
    var query: String
    var filtersData: Data
    var date: Date
    var resultCount: Int

    enum Columns: String, ColumnExpression {
        case id, query, filtersData, date, resultCount
    }
}

extension RecentSearch {
    init(from record: RecentSearchRecord) throws {
        let filters = try JSONDecoder().decode(SearchFilters.self, from: record.filtersData)
        self.init(
            id: UUID(uuidString: record.id) ?? UUID(),
            query: record.query,
            filters: filters,
            date: record.date,
            resultCount: record.resultCount
        )
    }

    func toRecord() throws -> RecentSearchRecord {
        let filtersData = try JSONEncoder().encode(filters)
        return RecentSearchRecord(
            id: id.uuidString,
            query: query,
            filtersData: filtersData,
            date: date,
            resultCount: resultCount
        )
    }
}

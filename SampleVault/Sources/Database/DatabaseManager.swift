//
//  DatabaseManager.swift
//  SampleVault
//
//  Core database manager for sample persistence
//

import Foundation
import GRDB

actor DatabaseManager {
    static let shared = DatabaseManager()

    private var dbQueue: DatabaseQueue?
    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Initialization
    func initialize() async throws {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let appFolder = appSupport.appendingPathComponent("SampleVault", isDirectory: true)
        try fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)

        let dbPath = appFolder.appendingPathComponent("samples.db").path
        dbQueue = try DatabaseQueue(path: dbPath)

        try await dbQueue?.write { db in
            try DatabaseMigrator.migrate(db)
        }
    }

    // MARK: - Sample Operations
    func insertSample(_ sample: Sample) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        try await dbQueue.write { db in
            try sample.toRecord().insert(db)

            // Insert tags
            for tagName in sample.tags {
                let sampleTag = SampleTagRecord(
                    sampleId: sample.id.uuidString,
                    tagName: tagName
                )
                try? sampleTag.insert(db)
            }

            // Update FTS index
            try db.execute(
                sql: """
                INSERT INTO samples_fts(rowid, filename, path, notes, category, subcategory)
                SELECT rowid, filename, path, notes, category, subcategory
                FROM samples WHERE id = ?
                """,
                arguments: [sample.id.uuidString]
            )
        }
    }

    func insertSamples(_ samples: [Sample]) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        try await dbQueue.write { db in
            for sample in samples {
                try sample.toRecord().insert(db)

                // Insert tags
                for tagName in sample.tags {
                    let sampleTag = SampleTagRecord(
                        sampleId: sample.id.uuidString,
                        tagName: tagName
                    )
                    try? sampleTag.insert(db)
                }
            }

            // Batch update FTS index
            try db.execute(
                sql: """
                INSERT INTO samples_fts(rowid, filename, path, notes, category, subcategory)
                SELECT rowid, filename, path, notes, category, subcategory FROM samples
                WHERE id IN (\(samples.map { "'\($0.id.uuidString)'" }.joined(separator: ",")))
                """
            )
        }
    }

    func updateSample(_ sample: Sample) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        try await dbQueue.write { db in
            try sample.toRecord().update(db)

            // Update tags - remove old, insert new
            try db.execute(
                sql: "DELETE FROM sample_tags WHERE sampleId = ?",
                arguments: [sample.id.uuidString]
            )

            for tagName in sample.tags {
                let sampleTag = SampleTagRecord(
                    sampleId: sample.id.uuidString,
                    tagName: tagName
                )
                try? sampleTag.insert(db)
            }

            // Update FTS index
            try db.execute(
                sql: """
                UPDATE samples_fts SET
                    filename = ?,
                    path = ?,
                    notes = ?,
                    category = ?,
                    subcategory = ?
                WHERE rowid = (SELECT rowid FROM samples WHERE id = ?)
                """,
                arguments: [
                    sample.filename,
                    sample.path,
                    sample.notes ?? "",
                    sample.category?.rawValue ?? "",
                    sample.subcategory ?? "",
                    sample.id.uuidString
                ]
            )
        }
    }

    func deleteSample(id: UUID) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        try await dbQueue.write { db in
            try db.execute(
                sql: "DELETE FROM samples WHERE id = ?",
                arguments: [id.uuidString]
            )
        }
    }

    func getSample(id: UUID) async throws -> Sample? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try await dbQueue.read { db in
            guard let record = try SampleRecord.fetchOne(
                db,
                sql: "SELECT * FROM samples WHERE id = ?",
                arguments: [id.uuidString]
            ) else {
                return nil
            }

            let tags = try String.fetchAll(
                db,
                sql: "SELECT tagName FROM sample_tags WHERE sampleId = ?",
                arguments: [id.uuidString]
            )

            return Sample(from: record, tags: tags)
        }
    }

    func getAllSamples() async throws -> [Sample] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try await dbQueue.read { db in
            let records = try SampleRecord.fetchAll(db)
            return try records.map { record in
                let tags = try String.fetchAll(
                    db,
                    sql: "SELECT tagName FROM sample_tags WHERE sampleId = ?",
                    arguments: [record.id]
                )
                return Sample(from: record, tags: tags)
            }
        }
    }

    // MARK: - Search and Filter
    func searchSamples(
        query: String? = nil,
        category: CategoryType? = nil,
        tags: [String]? = nil,
        isFavorite: Bool? = nil,
        bpmRange: ClosedRange<Int>? = nil,
        key: String? = nil,
        sortBy: SortOption = .dateAdded,
        limit: Int? = nil,
        offset: Int = 0
    ) async throws -> [Sample] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try await dbQueue.read { db in
            var sql = "SELECT DISTINCT s.* FROM samples s"
            var arguments: [DatabaseValueConvertible] = []
            var whereClauses: [String] = []

            // Full-text search
            if let query = query, !query.isEmpty {
                sql += " JOIN samples_fts fts ON s.rowid = fts.rowid"
                whereClauses.append("samples_fts MATCH ?")
                arguments.append(query)
            }

            // Tag filter
            if let tags = tags, !tags.isEmpty {
                sql += " JOIN sample_tags st ON s.id = st.sampleId"
                let placeholders = tags.map { _ in "?" }.joined(separator: ",")
                whereClauses.append("st.tagName IN (\(placeholders))")
                arguments.append(contentsOf: tags)
            }

            // Category filter
            if let category = category {
                whereClauses.append("s.category = ?")
                arguments.append(category.rawValue)
            }

            // Favorite filter
            if let isFavorite = isFavorite {
                whereClauses.append("s.isFavorite = ?")
                arguments.append(isFavorite)
            }

            // BPM range filter
            if let bpmRange = bpmRange {
                whereClauses.append("s.bpm BETWEEN ? AND ?")
                arguments.append(bpmRange.lowerBound)
                arguments.append(bpmRange.upperBound)
            }

            // Key filter
            if let key = key {
                whereClauses.append("s.key = ?")
                arguments.append(key)
            }

            // Build WHERE clause
            if !whereClauses.isEmpty {
                sql += " WHERE " + whereClauses.joined(separator: " AND ")
            }

            // Sorting
            sql += " ORDER BY "
            switch sortBy {
            case .name:
                sql += "s.filename COLLATE NOCASE ASC"
            case .dateAdded:
                sql += "s.dateAdded DESC"
            case .duration:
                sql += "s.duration DESC"
            case .bpm:
                sql += "s.bpm ASC"
            case .lastPlayed:
                sql += "s.lastPlayed DESC NULLS LAST"
            }

            // Pagination
            if let limit = limit {
                sql += " LIMIT ? OFFSET ?"
                arguments.append(limit)
                arguments.append(offset)
            }

            let records = try SampleRecord.fetchAll(db, sql: sql, arguments: StatementArguments(arguments))

            return try records.map { record in
                let tags = try String.fetchAll(
                    db,
                    sql: "SELECT tagName FROM sample_tags WHERE sampleId = ?",
                    arguments: [record.id]
                )
                return Sample(from: record, tags: tags)
            }
        }
    }

    func updatePlayCount(id: UUID) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        try await dbQueue.write { db in
            try db.execute(
                sql: """
                UPDATE samples
                SET playCount = playCount + 1, lastPlayed = ?
                WHERE id = ?
                """,
                arguments: [Date(), id.uuidString]
            )
        }
    }

    // MARK: - Tag Operations
    func getAllTags() async throws -> [Tag] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try await dbQueue.read { db in
            let records = try TagRecord.fetchAll(db, sql: "SELECT * FROM tags ORDER BY name")
            return records.map { Tag(from: $0) }
        }
    }

    func insertTag(_ tag: Tag) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        try await dbQueue.write { db in
            try tag.toRecord().insert(db)
        }
    }

    func deleteTag(name: String) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        try await dbQueue.write { db in
            try db.execute(sql: "DELETE FROM tags WHERE name = ?", arguments: [name])
        }
    }

    // MARK: - Statistics
    func getSampleCount() async throws -> Int {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try await dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM samples") ?? 0
        }
    }

    func getCategoryCount(category: CategoryType) async throws -> Int {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try await dbQueue.read { db in
            try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM samples WHERE category = ?",
                arguments: [category.rawValue]
            ) ?? 0
        }
    }

    // MARK: - Smart Folder Operations
    func getAllSmartFolders() async throws -> [SmartFolder] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try await dbQueue.read { db in
            let records = try SmartFolderRecord.fetchAll(db, sql: "SELECT * FROM smart_folders ORDER BY name")
            return try records.map { try SmartFolder(from: $0) }
        }
    }

    func insertSmartFolder(_ folder: SmartFolder) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        try await dbQueue.write { db in
            try folder.toRecord().insert(db)
        }
    }

    func updateSmartFolder(_ folder: SmartFolder) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        var updatedFolder = folder
        updatedFolder.dateModified = Date()

        try await dbQueue.write { db in
            try updatedFolder.toRecord().update(db)
        }
    }

    func deleteSmartFolder(id: UUID) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        try await dbQueue.write { db in
            try db.execute(sql: "DELETE FROM smart_folders WHERE id = ?", arguments: [id.uuidString])
        }
    }

    // MARK: - Recent Search Operations
    func getRecentSearches(limit: Int = 10) async throws -> [RecentSearch] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try await dbQueue.read { db in
            let records = try RecentSearchRecord.fetchAll(
                db,
                sql: "SELECT * FROM recent_searches ORDER BY date DESC LIMIT ?",
                arguments: [limit]
            )
            return try records.map { try RecentSearch(from: $0) }
        }
    }

    func insertRecentSearch(_ search: RecentSearch) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        try await dbQueue.write { db in
            // Check if similar search exists
            if let existing = try RecentSearchRecord.fetchOne(
                db,
                sql: "SELECT * FROM recent_searches WHERE query = ? ORDER BY date DESC LIMIT 1",
                arguments: [search.query]
            ) {
                // Update existing entry with new date
                var updated = search
                updated.date = Date()
                try updated.toRecord().update(db)
            } else {
                // Insert new search
                try search.toRecord().insert(db)
            }

            // Keep only last 50 searches
            try db.execute(
                sql: """
                DELETE FROM recent_searches WHERE id NOT IN (
                    SELECT id FROM recent_searches ORDER BY date DESC LIMIT 50
                )
                """
            )
        }
    }

    func clearRecentSearches() async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        try await dbQueue.write { db in
            try db.execute(sql: "DELETE FROM recent_searches")
        }
    }
}

// MARK: - Supporting Types
enum SortOption: String, Codable {
    case name
    case dateAdded
    case duration
    case bpm
    case lastPlayed
}

enum DatabaseError: Error {
    case notInitialized
    case invalidData
}

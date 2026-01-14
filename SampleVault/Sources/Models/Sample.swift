//
//  Sample.swift
//  SampleVault
//
//  Core data model for audio samples
//

import Foundation

struct Sample: Identifiable, Codable, Hashable {
    let id: UUID
    let filename: String
    let path: String
    let bookmarkData: Data  // Security-scoped bookmark for sandboxed access

    var fileSize: Int64
    var duration: TimeInterval
    var bpm: Int?
    var key: String?  // e.g., "Cmaj", "Amin"
    var waveformData: Data?  // Cached peak data for waveform rendering

    var category: CategoryType?
    var subcategory: String?
    var tags: [String]  // Tag names (lightweight)
    var notes: String?

    var isFavorite: Bool
    var playCount: Int
    var dateAdded: Date
    var lastPlayed: Date?

    init(
        id: UUID = UUID(),
        filename: String,
        path: String,
        bookmarkData: Data,
        fileSize: Int64 = 0,
        duration: TimeInterval = 0,
        bpm: Int? = nil,
        key: String? = nil,
        waveformData: Data? = nil,
        category: CategoryType? = nil,
        subcategory: String? = nil,
        tags: [String] = [],
        notes: String? = nil,
        isFavorite: Bool = false,
        playCount: Int = 0,
        dateAdded: Date = Date(),
        lastPlayed: Date? = nil
    ) {
        self.id = id
        self.filename = filename
        self.path = path
        self.bookmarkData = bookmarkData
        self.fileSize = fileSize
        self.duration = duration
        self.bpm = bpm
        self.key = key
        self.waveformData = waveformData
        self.category = category
        self.subcategory = subcategory
        self.tags = tags
        self.notes = notes
        self.isFavorite = isFavorite
        self.playCount = playCount
        self.dateAdded = dateAdded
        self.lastPlayed = lastPlayed
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedFileSize: String {
        let kb = Double(fileSize) / 1024
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        }
        let mb = kb / 1024
        return String(format: "%.1f MB", mb)
    }

    var fileExtension: String {
        (path as NSString).pathExtension.uppercased()
    }

    // Supported audio formats
    static let supportedExtensions: Set<String> = [
        "wav", "aiff", "aif", "mp3", "m4a", "flac", "ogg"
    ]

    static func isSupportedFile(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return supportedExtensions.contains(ext)
    }
}

// MARK: - Auto-categorization
extension Sample {
    /// Attempt to categorize based on filename and path
    mutating func autoCategorize() {
        let lowercased = (path + filename).lowercased()

        // Check for category keywords in path/filename
        for categoryType in CategoryType.allCases {
            if lowercased.contains(categoryType.rawValue.lowercased()) {
                self.category = categoryType

                // Check for subcategories
                for sub in categoryType.subcategories {
                    if lowercased.contains(sub.lowercased()) {
                        self.subcategory = sub
                        break
                    }
                }
                return
            }
        }

        // Check specific keywords for each category
        if lowercased.contains("kick") {
            self.category = .drums
            self.subcategory = "Kicks"
        } else if lowercased.contains("snare") || lowercased.contains("clap") {
            self.category = .drums
            self.subcategory = "Snares"
        } else if lowercased.contains("hat") || lowercased.contains("hihat") || lowercased.contains("hi-hat") {
            self.category = .drums
            self.subcategory = "Hats"
        } else if lowercased.contains("perc") {
            self.category = .drums
            self.subcategory = "Percussion"
        } else if lowercased.contains("bass") || lowercased.contains("sub") {
            self.category = .bass
        } else if lowercased.contains("lead") {
            self.category = .synths
            self.subcategory = "Leads"
        } else if lowercased.contains("pad") {
            self.category = .synths
            self.subcategory = "Pads"
        } else if lowercased.contains("pluck") {
            self.category = .synths
            self.subcategory = "Plucks"
        } else if lowercased.contains("vocal") || lowercased.contains("vox") {
            self.category = .vocals
        } else if lowercased.contains("riser") || lowercased.contains("sweep") {
            self.category = .fx
            self.subcategory = "Risers"
        } else if lowercased.contains("impact") || lowercased.contains("hit") {
            self.category = .fx
            self.subcategory = "Impacts"
        } else if lowercased.contains("loop") {
            self.category = .loops
        } else if lowercased.contains("one") && lowercased.contains("shot") {
            self.category = .oneShots
        } else {
            self.category = .uncategorized
        }
    }
}

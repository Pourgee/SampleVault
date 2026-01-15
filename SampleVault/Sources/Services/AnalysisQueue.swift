//
//  AnalysisQueue.swift
//  SampleVault
//
//  Background queue for analyzing audio samples
//

import Foundation

/// Progress update for analysis operations
struct AnalysisProgress {
    let current: Int
    let total: Int
    let currentSample: Sample?

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total) * 100.0
    }
}

/// Actor managing background audio analysis operations
@MainActor
class AnalysisQueue: ObservableObject {
    static let shared = AnalysisQueue()

    @Published var isAnalyzing = false
    @Published var progress = AnalysisProgress(current: 0, total: 0, currentSample: nil)

    private var analysisTask: Task<Void, Never>?
    private let database: DatabaseManager
    private let bookmarkManager: BookmarkManager

    init(database: DatabaseManager = .shared, bookmarkManager: BookmarkManager = .shared) {
        self.database = database
        self.bookmarkManager = bookmarkManager
    }

    // MARK: - Queue Management

    /// Analyzes all samples in the library that don't have BPM or key data
    func analyzeUnanalyzedSamples() async {
        guard !isAnalyzing else { return }

        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            // Get all samples
            let allSamples = try await database.getAllSamples()

            // Filter samples that need analysis
            let samplesToAnalyze = allSamples.filter { sample in
                sample.bpm == nil || sample.key == nil
            }

            guard !samplesToAnalyze.isEmpty else {
                print("All samples already analyzed")
                return
            }

            await analyzeSamples(samplesToAnalyze)

        } catch {
            print("Error getting samples for analysis: \(error)")
        }
    }

    /// Analyzes a specific set of samples
    func analyzeSamples(_ samples: [Sample]) async {
        guard !isAnalyzing else { return }

        isAnalyzing = true
        defer {
            isAnalyzing = false
            progress = AnalysisProgress(current: 0, total: 0, currentSample: nil)
        }

        let total = samples.count
        progress = AnalysisProgress(current: 0, total: total, currentSample: nil)

        for (index, sample) in samples.enumerated() {
            // Check if task was cancelled
            if Task.isCancelled {
                print("Analysis cancelled")
                break
            }

            // Update progress
            progress = AnalysisProgress(current: index, total: total, currentSample: sample)

            // Analyze sample
            await analyzeSample(sample)

            // Update progress after completion
            progress = AnalysisProgress(current: index + 1, total: total, currentSample: nil)
        }
    }

    /// Analyzes a single sample
    private func analyzeSample(_ sample: Sample) async {
        do {
            // Resolve file URL with security-scoped access
            let url = try bookmarkManager.resolveBookmark(sample.bookmarkData)

            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            // Perform analysis
            let analyzer = AudioAnalyzer.shared
            let (bpm, key) = try await analyzer.analyzeAudio(url: url)

            // Update sample in database
            var updatedSample = sample
            if let bpm = bpm {
                updatedSample.bpm = bpm
            }
            if let key = key {
                updatedSample.key = key
            }

            try await database.updateSample(updatedSample)

            print("Analyzed: \(sample.filename) - BPM: \(bpm ?? 0), Key: \(key ?? "unknown")")

        } catch {
            print("Error analyzing sample \(sample.filename): \(error)")
        }
    }

    /// Re-analyzes specific samples (even if they already have data)
    func reanalyzeSamples(_ samples: [Sample]) async {
        guard !isAnalyzing else { return }

        isAnalyzing = true
        defer {
            isAnalyzing = false
            progress = AnalysisProgress(current: 0, total: 0, currentSample: nil)
        }

        await analyzeSamples(samples)
    }

    /// Cancels the current analysis operation
    func cancelAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
        isAnalyzing = false
        progress = AnalysisProgress(current: 0, total: 0, currentSample: nil)
    }

    // MARK: - Batch Operations

    /// Starts background analysis of unanalyzed samples
    func startBackgroundAnalysis() {
        guard analysisTask == nil else { return }

        analysisTask = Task {
            await analyzeUnanalyzedSamples()
        }
    }

    /// Analyzes samples in a specific category
    func analyzeSamplesInCategory(_ category: CategoryType) async {
        guard !isAnalyzing else { return }

        do {
            let allSamples = try await database.getAllSamples()
            let categorySamples = allSamples.filter { $0.category == category }
            let samplesToAnalyze = categorySamples.filter { $0.bpm == nil || $0.key == nil }

            await analyzeSamples(samplesToAnalyze)
        } catch {
            print("Error analyzing category samples: \(error)")
        }
    }

    /// Gets statistics about analysis status
    func getAnalysisStats() async -> (analyzed: Int, unanalyzed: Int, total: Int) {
        do {
            let allSamples = try await database.getAllSamples()
            let analyzed = allSamples.filter { $0.bpm != nil && $0.key != nil }.count
            let unanalyzed = allSamples.count - analyzed
            return (analyzed: analyzed, unanalyzed: unanalyzed, total: allSamples.count)
        } catch {
            return (analyzed: 0, unanalyzed: 0, total: 0)
        }
    }
}

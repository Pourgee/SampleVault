//
//  FileScanner.swift
//  SampleVault
//
//  Recursively scans folders for audio samples with progress tracking
//

import Foundation
import AVFoundation

actor FileScanner {
    static let shared = FileScanner()

    private var isScanning = false
    private var cancellationRequested = false

    private init() {}

    // MARK: - Scanning
    struct ScanProgress {
        var filesFound: Int
        var filesProcessed: Int
        var currentFile: String
        var isComplete: Bool
    }

    typealias ProgressHandler = (ScanProgress) -> Void

    func scanFolder(
        _ folderURL: URL,
        bookmarkData: Data,
        onProgress: @escaping ProgressHandler
    ) async throws -> [Sample] {
        guard !isScanning else {
            throw ScanError.alreadyScanning
        }

        isScanning = true
        cancellationRequested = false
        defer { isScanning = false }

        var samples: [Sample] = []
        var filesFound = 0
        var filesProcessed = 0

        // First pass: Find all audio files
        let audioFiles = try await findAudioFiles(in: folderURL)
        filesFound = audioFiles.count

        // Report initial progress
        await MainActor.run {
            onProgress(ScanProgress(
                filesFound: filesFound,
                filesProcessed: 0,
                currentFile: "",
                isComplete: false
            ))
        }

        // Second pass: Process each audio file
        for fileURL in audioFiles {
            if cancellationRequested {
                throw ScanError.cancelled
            }

            do {
                var sample = try await processSampleFile(fileURL, bookmarkData: bookmarkData)
                sample.autoCategorize()
                samples.append(sample)

                filesProcessed += 1

                // Report progress every 10 files or on last file
                if filesProcessed % 10 == 0 || filesProcessed == filesFound {
                    await MainActor.run {
                        onProgress(ScanProgress(
                            filesFound: filesFound,
                            filesProcessed: filesProcessed,
                            currentFile: fileURL.lastPathComponent,
                            isComplete: false
                        ))
                    }
                }
            } catch {
                print("Error processing \(fileURL.lastPathComponent): \(error)")
                // Continue with next file
            }
        }

        // Report completion
        await MainActor.run {
            onProgress(ScanProgress(
                filesFound: filesFound,
                filesProcessed: filesProcessed,
                currentFile: "",
                isComplete: true
            ))
        }

        return samples
    }

    func cancelScan() {
        cancellationRequested = true
    }

    // MARK: - Private Helpers
    private func findAudioFiles(in directory: URL) async throws -> [URL] {
        var audioFiles: [URL] = []
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .nameKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw ScanError.invalidDirectory
        }

        for case let fileURL as URL in enumerator {
            if cancellationRequested {
                throw ScanError.cancelled
            }

            // Check if it's a regular file
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  resourceValues.isRegularFile == true else {
                continue
            }

            // Check if it's a supported audio format
            if Sample.isSupportedFile(fileURL.path) {
                audioFiles.append(fileURL)
            }
        }

        return audioFiles
    }

    private func processSampleFile(_ fileURL: URL, bookmarkData: Data) async throws -> Sample {
        let fileManager = FileManager.default

        // Get file attributes
        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0

        // Get audio duration using AVAsset
        let asset = AVAsset(url: fileURL)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)

        // Create individual bookmark for this file
        let fileBookmark = try BookmarkManager.shared.createBookmark(for: fileURL)

        return Sample(
            filename: fileURL.lastPathComponent,
            path: fileURL.path,
            bookmarkData: fileBookmark,
            fileSize: fileSize,
            duration: durationSeconds,
            dateAdded: Date()
        )
    }
}

// MARK: - Audio Analysis Extensions
extension FileScanner {
    /// Analyze sample for BPM and key (runs after initial import)
    func analyzeSample(_ sample: Sample) async throws -> Sample {
        var updatedSample = sample

        // Resolve bookmark and perform analysis with security-scoped access
        let url = try BookmarkManager.shared.resolveBookmark(sample.bookmarkData)

        guard url.startAccessingSecurityScopedResource() else {
            throw ScanError.fileNotAccessible
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        // Detect BPM
        if let bpm = try? await detectBPM(url: url) {
            updatedSample.bpm = bpm
        }

        // Detect key
        if let key = try? await detectKey(url: url) {
            updatedSample.key = key
        }

        // Generate waveform
        if let waveformData = try? await generateWaveform(url: url) {
            updatedSample.waveformData = waveformData
        }

        return updatedSample
    }

    private func detectBPM(url: URL) async throws -> Int? {
        // Placeholder for BPM detection using AudioKit or Accelerate framework
        // This would use onset detection and tempo analysis
        // For now, return nil - will be implemented in Phase 5
        return nil
    }

    private func detectKey(url: URL) async throws -> String? {
        // Placeholder for key detection using spectral analysis
        // This would use FFT and chromagram analysis
        // For now, return nil - will be implemented in Phase 5
        return nil
    }

    private func generateWaveform(url: URL) async throws -> Data? {
        // Generate waveform using WaveformGenerator
        do {
            let waveformData = try await WaveformGenerator.shared.generateWaveform(from: url, targetSampleCount: 500)
            return try waveformData.encode()
        } catch {
            print("Waveform generation failed: \(error)")
            return nil
        }
    }
}

// MARK: - Batch Operations
extension FileScanner {
    func batchAnalyzeSamples(
        _ samples: [Sample],
        onProgress: @escaping (Int, Int) -> Void
    ) async throws -> [Sample] {
        var analyzedSamples: [Sample] = []
        var processed = 0

        for sample in samples {
            if cancellationRequested {
                throw ScanError.cancelled
            }

            do {
                let analyzed = try await analyzeSample(sample)
                analyzedSamples.append(analyzed)
            } catch {
                // Keep original sample if analysis fails
                analyzedSamples.append(sample)
            }

            processed += 1
            if processed % 5 == 0 {
                await MainActor.run {
                    onProgress(processed, samples.count)
                }
            }
        }

        return analyzedSamples
    }
}

// MARK: - Errors
enum ScanError: Error, LocalizedError {
    case alreadyScanning
    case invalidDirectory
    case cancelled
    case fileNotAccessible

    var errorDescription: String? {
        switch self {
        case .alreadyScanning:
            return "A scan operation is already in progress"
        case .invalidDirectory:
            return "Invalid directory or unable to access contents"
        case .cancelled:
            return "Scan operation was cancelled"
        case .fileNotAccessible:
            return "Unable to access audio file"
        }
    }
}

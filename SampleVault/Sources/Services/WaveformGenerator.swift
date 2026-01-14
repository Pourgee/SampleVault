//
//  WaveformGenerator.swift
//  SampleVault
//
//  Generates waveform peak data for visualization
//

import Foundation
import AVFoundation
import Accelerate

actor WaveformGenerator {
    static let shared = WaveformGenerator()

    private init() {}

    // MARK: - Waveform Generation
    struct WaveformData: Codable {
        let peaks: [Float]
        let sampleCount: Int
        let duration: TimeInterval

        func encode() throws -> Data {
            try JSONEncoder().encode(self)
        }

        static func decode(from data: Data) throws -> WaveformData {
            try JSONDecoder().decode(WaveformData.self, from: data)
        }
    }

    /// Generate waveform data from audio file URL
    /// - Parameters:
    ///   - url: Audio file URL
    ///   - targetSampleCount: Number of samples in output (default: 500 for good resolution)
    /// - Returns: WaveformData with peak values
    func generateWaveform(from url: URL, targetSampleCount: Int = 500) async throws -> WaveformData {
        let audioFile = try AVAudioFile(forReading: url)

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: audioFile.fileFormat.sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw WaveformError.formatCreationFailed
        }

        let frameCount = AVAudioFrameCount(audioFile.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw WaveformError.bufferCreationFailed
        }

        // Read entire file
        try audioFile.read(into: buffer)

        guard let channelData = buffer.floatChannelData else {
            throw WaveformError.noChannelData
        }

        let samples = Array(UnsafeBufferPointer(
            start: channelData[0],
            count: Int(buffer.frameLength)
        ))

        // Downsample to target sample count
        let peaks = downsample(samples, to: targetSampleCount)

        let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate

        return WaveformData(
            peaks: peaks,
            sampleCount: targetSampleCount,
            duration: duration
        )
    }

    /// Generate waveform data using security-scoped bookmark
    func generateWaveform(from bookmarkData: Data, targetSampleCount: Int = 500) async throws -> WaveformData {
        try await BookmarkManager.shared.accessSecurityScopedResourceAsync(bookmarkData) { url in
            try await generateWaveform(from: url, targetSampleCount: targetSampleCount)
        }
    }

    // MARK: - Downsampling
    private func downsample(_ samples: [Float], to targetCount: Int) -> [Float] {
        guard samples.count > targetCount else {
            return samples
        }

        let samplesPerBin = samples.count / targetCount
        var peaks = [Float]()
        peaks.reserveCapacity(targetCount)

        for i in 0..<targetCount {
            let start = i * samplesPerBin
            let end = min(start + samplesPerBin, samples.count)
            let slice = Array(samples[start..<end])

            // Get peak value in this slice
            let peak = slice.map { abs($0) }.max() ?? 0
            peaks.append(peak)
        }

        // Normalize peaks to 0-1 range
        if let maxPeak = peaks.max(), maxPeak > 0 {
            return peaks.map { $0 / maxPeak }
        }

        return peaks
    }

    // MARK: - Fast Waveform (Lower Resolution)
    /// Generate fast waveform with fewer samples (for thumbnails)
    func generateFastWaveform(from url: URL) async throws -> WaveformData {
        try await generateWaveform(from: url, targetSampleCount: 100)
    }

    /// Generate high-resolution waveform (for detailed view)
    func generateHighResWaveform(from url: URL) async throws -> WaveformData {
        try await generateWaveform(from: url, targetSampleCount: 1000)
    }

    // MARK: - Batch Generation
    func generateWaveforms(for samples: [Sample], onProgress: @escaping (Int, Int) -> Void) async throws -> [UUID: Data] {
        var waveformMap: [UUID: Data] = [:]
        var processed = 0

        for sample in samples {
            do {
                let waveformData = try await generateWaveform(from: sample.bookmarkData)
                let encodedData = try waveformData.encode()
                waveformMap[sample.id] = encodedData

                processed += 1
                if processed % 10 == 0 {
                    await MainActor.run {
                        onProgress(processed, samples.count)
                    }
                }
            } catch {
                print("Failed to generate waveform for \(sample.filename): \(error)")
                // Continue with next sample
            }
        }

        return waveformMap
    }
}

// MARK: - Errors
enum WaveformError: Error, LocalizedError {
    case formatCreationFailed
    case bufferCreationFailed
    case noChannelData
    case invalidData

    var errorDescription: String? {
        switch self {
        case .formatCreationFailed:
            return "Failed to create audio format"
        case .bufferCreationFailed:
            return "Failed to create audio buffer"
        case .noChannelData:
            return "No channel data available"
        case .invalidData:
            return "Invalid waveform data"
        }
    }
}

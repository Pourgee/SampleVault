//
//  AudioAnalyzer.swift
//  SampleVault
//
//  Audio analysis service for BPM and key detection
//

import Foundation
import AVFoundation
import Accelerate
import AudioKit

/// Actor responsible for analyzing audio files to detect BPM and musical key
actor AudioAnalyzer {
    static let shared = AudioAnalyzer()

    private init() {}

    // MARK: - BPM Detection

    /// Detects BPM (beats per minute) of an audio file
    /// - Parameter url: URL of the audio file to analyze
    /// - Returns: Detected BPM or nil if detection fails
    func detectBPM(url: URL) async throws -> Int? {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        try file.read(into: buffer)

        // Use onset detection for BPM estimation
        let bpm = detectBPMFromBuffer(buffer: buffer, sampleRate: format.sampleRate)
        return bpm
    }

    private func detectBPMFromBuffer(buffer: AVAudioPCMBuffer, sampleRate: Double) -> Int? {
        guard let channelData = buffer.floatChannelData else { return nil }
        let frameLength = Int(buffer.frameLength)

        // Convert to mono if stereo
        var monoData = [Float](repeating: 0, count: frameLength)
        if buffer.format.channelCount == 2 {
            let leftChannel = channelData[0]
            let rightChannel = channelData[1]
            for i in 0..<frameLength {
                monoData[i] = (leftChannel[i] + rightChannel[i]) / 2.0
            }
        } else {
            let channel = channelData[0]
            for i in 0..<frameLength {
                monoData[i] = channel[i]
            }
        }

        // Calculate onset strength envelope
        let onsetStrength = calculateOnsetStrength(samples: monoData, sampleRate: sampleRate)

        // Estimate BPM from onset autocorrelation
        let bpm = estimateBPMFromOnsets(onsets: onsetStrength, sampleRate: sampleRate)

        return bpm
    }

    private func calculateOnsetStrength(samples: [Float], sampleRate: Double) -> [Float] {
        let hopSize = 512
        let fftSize = 2048
        let frameCount = (samples.count - fftSize) / hopSize

        var onsetStrength = [Float](repeating: 0, count: frameCount)
        var previousSpectrum = [Float](repeating: 0, count: fftSize / 2)

        // Setup FFT
        guard let fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            vDSP_Length(fftSize),
            vDSP_DFT_Direction.FORWARD
        ) else {
            return onsetStrength
        }

        defer { vDSP_DFT_DestroySetup(fftSetup) }

        for frame in 0..<frameCount {
            let startIndex = frame * hopSize
            let endIndex = min(startIndex + fftSize, samples.count)
            let frameData = Array(samples[startIndex..<endIndex])

            // Apply Hamming window
            var windowed = [Float](repeating: 0, count: fftSize)
            var window = [Float](repeating: 0, count: fftSize)
            vDSP_hamm_window(&window, vDSP_Length(fftSize), 0)
            vDSP_vmul(frameData, 1, window, 1, &windowed, 1, vDSP_Length(frameData.count))

            // Compute magnitude spectrum
            let spectrum = computeMagnitudeSpectrum(samples: windowed, fftSetup: fftSetup)

            // Calculate spectral flux (onset strength)
            var flux: Float = 0
            for i in 0..<spectrum.count {
                let diff = max(0, spectrum[i] - previousSpectrum[i])
                flux += diff
            }

            onsetStrength[frame] = flux
            previousSpectrum = spectrum
        }

        return onsetStrength
    }

    private func computeMagnitudeSpectrum(samples: [Float], fftSetup: OpaquePointer) -> [Float] {
        let fftSize = samples.count
        let halfSize = fftSize / 2

        var realIn = [Float](repeating: 0, count: fftSize)
        var imagIn = [Float](repeating: 0, count: fftSize)
        var realOut = [Float](repeating: 0, count: fftSize)
        var imagOut = [Float](repeating: 0, count: fftSize)

        // Copy input
        for i in 0..<fftSize {
            realIn[i] = samples[i]
        }

        // Perform FFT
        vDSP_DFT_Execute(fftSetup, &realIn, &imagIn, &realOut, &imagOut)

        // Calculate magnitudes
        var magnitudes = [Float](repeating: 0, count: halfSize)
        for i in 0..<halfSize {
            let real = realOut[i]
            let imag = imagOut[i]
            magnitudes[i] = sqrt(real * real + imag * imag)
        }

        return magnitudes
    }

    private func estimateBPMFromOnsets(onsets: [Float], sampleRate: Double) -> Int? {
        guard onsets.count > 0 else { return nil }

        let hopSize = 512
        let timePerFrame = Double(hopSize) / sampleRate

        // Autocorrelation to find periodicity
        let minBPM = 60.0
        let maxBPM = 200.0
        let minLag = Int((60.0 / maxBPM) / timePerFrame)
        let maxLag = Int((60.0 / minBPM) / timePerFrame)

        var bestBPM = 120
        var maxCorrelation: Float = 0

        for lag in minLag..<min(maxLag, onsets.count / 2) {
            var correlation: Float = 0
            for i in 0..<(onsets.count - lag) {
                correlation += onsets[i] * onsets[i + lag]
            }

            if correlation > maxCorrelation {
                maxCorrelation = correlation
                let bpm = 60.0 / (Double(lag) * timePerFrame)
                bestBPM = Int(round(bpm))
            }
        }

        // Validate BPM is in reasonable range
        if bestBPM >= Int(minBPM) && bestBPM <= Int(maxBPM) {
            return bestBPM
        }

        return nil
    }

    // MARK: - Key Detection

    /// Detects the musical key of an audio file
    /// - Parameter url: URL of the audio file to analyze
    /// - Returns: Detected key (e.g., "C", "Am", "F#") or nil if detection fails
    func detectKey(url: URL) async throws -> String? {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        try file.read(into: buffer)

        // Use chromagram analysis for key detection
        let key = detectKeyFromBuffer(buffer: buffer, sampleRate: format.sampleRate)
        return key
    }

    private func detectKeyFromBuffer(buffer: AVAudioPCMBuffer, sampleRate: Double) -> String? {
        guard let channelData = buffer.floatChannelData else { return nil }
        let frameLength = Int(buffer.frameLength)

        // Convert to mono
        var monoData = [Float](repeating: 0, count: frameLength)
        if buffer.format.channelCount == 2 {
            let leftChannel = channelData[0]
            let rightChannel = channelData[1]
            for i in 0..<frameLength {
                monoData[i] = (leftChannel[i] + rightChannel[i]) / 2.0
            }
        } else {
            let channel = channelData[0]
            for i in 0..<frameLength {
                monoData[i] = channel[i]
            }
        }

        // Calculate chromagram (pitch class distribution)
        let chromagram = calculateChromagram(samples: monoData, sampleRate: sampleRate)

        // Detect key from chromagram
        let key = detectKeyFromChromagram(chromagram: chromagram)

        return key
    }

    private func calculateChromagram(samples: [Float], sampleRate: Double) -> [Float] {
        let hopSize = 4096
        let fftSize = 8192
        let frameCount = (samples.count - fftSize) / hopSize
        let pitchClasses = 12 // 12 semitones in an octave

        var chromagram = [Float](repeating: 0, count: pitchClasses)

        // Setup FFT
        guard let fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            vDSP_Length(fftSize),
            vDSP_DFT_Direction.FORWARD
        ) else {
            return chromagram
        }

        defer { vDSP_DFT_DestroySetup(fftSetup) }

        for frame in 0..<frameCount {
            let startIndex = frame * hopSize
            let endIndex = min(startIndex + fftSize, samples.count)
            let frameData = Array(samples[startIndex..<endIndex])

            // Apply Hamming window
            var windowed = [Float](repeating: 0, count: fftSize)
            var window = [Float](repeating: 0, count: fftSize)
            vDSP_hamm_window(&window, vDSP_Length(fftSize), 0)
            vDSP_vmul(frameData, 1, window, 1, &windowed, 1, vDSP_Length(frameData.count))

            // Compute spectrum
            let spectrum = computeMagnitudeSpectrum(samples: windowed, fftSetup: fftSetup)

            // Map spectrum bins to pitch classes
            for i in 0..<spectrum.count {
                let frequency = Double(i) * sampleRate / Double(fftSize)
                if frequency > 20 && frequency < 5000 { // Focus on musical range
                    let pitchClass = frequencyToPitchClass(frequency: frequency)
                    chromagram[pitchClass] += spectrum[i]
                }
            }
        }

        // Normalize
        var sum: Float = 0
        vDSP_sve(chromagram, 1, &sum, vDSP_Length(pitchClasses))
        if sum > 0 {
            var normalized = [Float](repeating: 0, count: pitchClasses)
            vDSP_vsdiv(chromagram, 1, &sum, &normalized, 1, vDSP_Length(pitchClasses))
            return normalized
        }

        return chromagram
    }

    private func frequencyToPitchClass(frequency: Double) -> Int {
        // Convert frequency to MIDI note number
        let midiNote = 12 * log2(frequency / 440.0) + 69
        // Get pitch class (0-11, where 0 = C, 1 = C#, etc.)
        let pitchClass = Int(round(midiNote)) % 12
        return (pitchClass + 12) % 12 // Ensure positive
    }

    private func detectKeyFromChromagram(chromagram: [Float]) -> String? {
        // Major and minor key profiles (Krumhansl-Schmuckler)
        let majorProfile: [Float] = [6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]
        let minorProfile: [Float] = [6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]

        let pitchNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

        var bestKey = "C"
        var maxCorrelation: Float = -999999

        // Try all 24 keys (12 major + 12 minor)
        for root in 0..<12 {
            // Test major key
            var majorCorr: Float = 0
            for i in 0..<12 {
                let chromaticIndex = (i + root) % 12
                majorCorr += chromagram[chromaticIndex] * majorProfile[i]
            }

            if majorCorr > maxCorrelation {
                maxCorrelation = majorCorr
                bestKey = pitchNames[root]
            }

            // Test minor key
            var minorCorr: Float = 0
            for i in 0..<12 {
                let chromaticIndex = (i + root) % 12
                minorCorr += chromagram[chromaticIndex] * minorProfile[i]
            }

            if minorCorr > maxCorrelation {
                maxCorrelation = minorCorr
                bestKey = pitchNames[root] + "m"
            }
        }

        return bestKey
    }

    // MARK: - Combined Analysis

    /// Analyzes an audio file for both BPM and key
    /// - Parameter url: URL of the audio file to analyze
    /// - Returns: Tuple containing (BPM, Key) or nil values if detection fails
    func analyzeAudio(url: URL) async throws -> (bpm: Int?, key: String?) {
        async let bpm = detectBPM(url: url)
        async let key = detectKey(url: url)

        let results = try await (bpm, key)
        return results
    }
}

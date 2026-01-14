//
//  AudioPlayer.swift
//  SampleVault
//
//  Low-latency audio playback engine using AVAudioEngine
//

import Foundation
import AVFoundation

@MainActor
class AudioPlayer: ObservableObject {
    static let shared = AudioPlayer()

    // MARK: - Published State
    @Published var isPlaying = false
    @Published var currentSample: Sample?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.8
    @Published var isLooping = false

    // MARK: - Audio Engine
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    private var displayLink: CADisplayLink?

    // MARK: - Initialization
    private init() {
        setupAudioEngine()
        setupDisplayLink()
    }

    private func setupAudioEngine() {
        // Attach player node
        engine.attach(playerNode)

        // Connect to main mixer
        let mixer = engine.mainMixerNode
        let format = mixer.outputFormat(forBus: 0)
        engine.connect(playerNode, to: mixer, format: format)

        // Start engine
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updatePlaybackTime))
        displayLink?.add(to: .main, forMode: .common)
        displayLink?.isPaused = true
    }

    // MARK: - Playback Control
    func loadAndPlay(_ sample: Sample) async throws {
        // Stop current playback
        stop()

        // Load audio file using security-scoped bookmark
        try await BookmarkManager.shared.accessSecurityScopedResourceAsync(sample.bookmarkData) { url in
            self.audioFile = try AVAudioFile(forReading: url)

            guard let audioFile = self.audioFile else {
                throw AudioPlayerError.fileLoadFailed
            }

            self.currentSample = sample
            self.duration = sample.duration

            // Schedule playback
            self.schedulePlayback()

            // Start playing
            self.playerNode.volume = self.volume
            self.playerNode.play()
            self.isPlaying = true

            // Update play count in database
            Task {
                try? await DatabaseManager.shared.updatePlayCount(id: sample.id)
            }

            // Start display link for time updates
            self.displayLink?.isPaused = false
        }
    }

    func play() {
        guard !isPlaying, audioFile != nil else { return }

        if playerNode.isPlaying {
            // Resume from pause
            playerNode.play()
        } else {
            // Restart playback
            schedulePlayback()
            playerNode.play()
        }

        isPlaying = true
        displayLink?.isPaused = false
    }

    func pause() {
        guard isPlaying else { return }

        playerNode.pause()
        isPlaying = false
        displayLink?.isPaused = true
    }

    func stop() {
        playerNode.stop()
        isPlaying = false
        currentTime = 0
        displayLink?.isPaused = true
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: TimeInterval) {
        guard let audioFile = audioFile else { return }

        let wasPlaying = isPlaying
        playerNode.stop()

        // Calculate frame position
        let sampleRate = audioFile.processingFormat.sampleRate
        let frame = AVAudioFramePosition(time * sampleRate)

        // Ensure frame is within bounds
        let frameCount = audioFile.length
        let clampedFrame = min(max(frame, 0), frameCount - 1)

        currentTime = time

        // Schedule from new position
        schedulePlayback(from: clampedFrame)

        if wasPlaying {
            playerNode.play()
            isPlaying = true
            displayLink?.isPaused = false
        }
    }

    // MARK: - Private Helpers
    private func schedulePlayback(from frame: AVAudioFramePosition = 0) {
        guard let audioFile = audioFile else { return }

        let frameCount = audioFile.length - frame
        guard frameCount > 0 else { return }

        playerNode.scheduleSegment(
            audioFile,
            startingFrame: frame,
            frameCount: AVAudioFrameCount(frameCount),
            at: nil
        ) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if self.isLooping {
                    // Restart playback
                    self.currentTime = 0
                    self.schedulePlayback()
                    self.playerNode.play()
                } else {
                    // Stop at end
                    self.isPlaying = false
                    self.currentTime = 0
                    self.displayLink?.isPaused = true
                }
            }
        }
    }

    @objc private func updatePlaybackTime() {
        guard isPlaying,
              let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime),
              let audioFile = audioFile else {
            return
        }

        let sampleRate = audioFile.processingFormat.sampleRate
        let currentFrame = Double(playerTime.sampleTime)
        currentTime = currentFrame / sampleRate

        // Ensure we don't exceed duration
        if currentTime >= duration {
            currentTime = duration
        }
    }

    // MARK: - Volume Control
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume)) // Clamp 0-1
        playerNode.volume = volume
    }

    func toggleLoop() {
        isLooping.toggle()
    }

    // MARK: - Cleanup
    deinit {
        displayLink?.invalidate()
        engine.stop()
    }
}

// MARK: - Errors
enum AudioPlayerError: Error, LocalizedError {
    case fileLoadFailed
    case engineNotRunning
    case invalidSeekPosition

    var errorDescription: String? {
        switch self {
        case .fileLoadFailed:
            return "Failed to load audio file"
        case .engineNotRunning:
            return "Audio engine is not running"
        case .invalidSeekPosition:
            return "Invalid seek position"
        }
    }
}

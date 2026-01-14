//
//  PlaybackControlsView.swift
//  SampleVault
//
//  Audio playback controls with waveform display
//

import SwiftUI

struct PlaybackControlsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @ObservedObject var audioPlayer = AudioPlayer.shared

    var body: some View {
        VStack(spacing: 0) {
            if let sample = audioPlayer.currentSample {
                // Waveform with playhead
                VStack(spacing: 8) {
                    WaveformView(
                        waveformData: sample.waveformData,
                        currentTime: audioPlayer.currentTime,
                        duration: audioPlayer.duration,
                        height: 80
                    ) { seekTime in
                        audioPlayer.seek(to: seekTime)
                    }

                    // Time display
                    HStack {
                        Text(formatTime(audioPlayer.currentTime))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(formatTime(audioPlayer.duration))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()

                // Controls
                HStack(spacing: 16) {
                    // Sample info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sample.filename)
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            if let category = sample.category {
                                Text(category.icon)
                                    .font(.caption)
                                Text(category.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let bpm = sample.bpm {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text("\(bpm) BPM")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let key = sample.key {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(key)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Playback buttons
                    HStack(spacing: 12) {
                        // Play/Pause
                        Button(action: {
                            audioPlayer.togglePlayPause()
                        }) {
                            Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 32))
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.space, modifiers: [])
                        .help("Play/Pause (Space)")

                        // Stop
                        Button(action: {
                            audioPlayer.stop()
                        }) {
                            Image(systemName: "stop.circle")
                                .font(.system(size: 28))
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.escape, modifiers: [])
                        .help("Stop (Esc)")
                    }

                    Spacer()

                    // Additional controls
                    HStack(spacing: 12) {
                        // Loop toggle
                        Button(action: {
                            audioPlayer.toggleLoop()
                        }) {
                            Image(systemName: audioPlayer.isLooping ? "repeat.circle.fill" : "repeat.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(audioPlayer.isLooping ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Loop")

                        // Volume control
                        HStack(spacing: 8) {
                            Image(systemName: volumeIcon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 16)

                            Slider(
                                value: Binding(
                                    get: { audioPlayer.volume },
                                    set: { audioPlayer.setVolume($0) }
                                ),
                                in: 0...1
                            )
                            .frame(width: 80)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            } else {
                // Empty state
                HStack {
                    Image(systemName: "waveform")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Text("Select a sample to preview")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var volumeIcon: String {
        if audioPlayer.volume == 0 {
            return "speaker.slash"
        } else if audioPlayer.volume < 0.33 {
            return "speaker.wave.1"
        } else if audioPlayer.volume < 0.66 {
            return "speaker.wave.2"
        } else {
            return "speaker.wave.3"
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Compact Playback Controls (for inline display)
struct CompactPlaybackControls: View {
    let sample: Sample
    @ObservedObject var audioPlayer = AudioPlayer.shared

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                if audioPlayer.currentSample?.id == sample.id {
                    audioPlayer.togglePlayPause()
                } else {
                    Task {
                        try? await audioPlayer.loadAndPlay(sample)
                    }
                }
            }) {
                Image(systemName: isPlayingThisSample ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isPlayingThisSample ? .accentColor : .primary)
            }
            .buttonStyle(.plain)

            if isPlayingThisSample {
                ProgressView(value: audioPlayer.currentTime, total: audioPlayer.duration)
                    .progressViewStyle(.linear)
                    .frame(width: 60)
            }
        }
    }

    private var isPlayingThisSample: Bool {
        audioPlayer.currentSample?.id == sample.id && audioPlayer.isPlaying
    }
}

// MARK: - Preview
#Preview {
    let sample = Sample(
        filename: "kick_808_hard.wav",
        path: "/Users/test/Samples/kick_808_hard.wav",
        bookmarkData: Data(),
        duration: 42.5,
        bpm: 120,
        key: "C",
        category: .drums,
        subcategory: "Kicks"
    )

    let audioPlayer = AudioPlayer.shared
    audioPlayer.currentSample = sample
    audioPlayer.duration = 42.5
    audioPlayer.currentTime = 15.0

    return VStack {
        PlaybackControlsView()
            .environmentObject(AppViewModel())

        Divider()

        HStack {
            CompactPlaybackControls(sample: sample)
            Spacer()
        }
        .padding()
    }
    .frame(width: 800)
}

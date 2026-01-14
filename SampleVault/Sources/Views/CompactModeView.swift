//
//  CompactModeView.swift
//  SampleVault
//
//  Compact/mini mode UI for minimal window footprint
//

import SwiftUI

struct CompactModeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @ObservedObject var audioPlayer = AudioPlayer.shared
    @AppStorage("compactMode") private var compactMode = false

    var body: some View {
        VStack(spacing: 0) {
            // Compact search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Search...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.body)

                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()

            // Compact sample list
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(viewModel.filteredSamples) { sample in
                        CompactSampleRow(sample: sample)
                            .background(
                                viewModel.selectedSample?.id == sample.id ?
                                    Color.accentColor.opacity(0.2) : Color.clear
                            )
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))

            // Compact playback controls
            Divider()

            if AudioPlayer.shared.currentSample != nil {
                CompactPlaybackControlsView()
                    .environmentObject(viewModel)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - Compact Sample Row
struct CompactSampleRow: View {
    @EnvironmentObject var viewModel: AppViewModel
    let sample: Sample
    @ObservedObject var audioPlayer = AudioPlayer.shared

    var isPlayingThisSample: Bool {
        audioPlayer.currentSample?.id == sample.id && audioPlayer.isPlaying
    }

    var body: some View {
        HStack(spacing: 8) {
            // Play indicator
            Circle()
                .fill(isPlayingThisSample ? Color.accentColor.opacity(0.2) : Color.clear)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: isPlayingThisSample ? "waveform" : (sample.category?.icon.first.map(String.init) ?? ""))
                        .font(.caption)
                        .foregroundStyle(isPlayingThisSample ? .accentColor : .secondary)
                        .symbolEffect(.variableColor.iterative, isActive: isPlayingThisSample)
                )

            // File name
            Text(sample.filename)
                .font(.callout)
                .lineLimit(1)

            Spacer()

            // Compact metadata
            HStack(spacing: 8) {
                if let bpm = sample.bpm {
                    Text("\(bpm)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let key = sample.key {
                    Text(key)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(sample.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Play button
            Button(action: {
                Task {
                    do {
                        try await AudioPlayer.shared.loadAndPlay(sample)
                    } catch {
                        print("Failed to play sample: \(error)")
                    }
                }
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            viewModel.selectedSample?.id == sample.id ?
                Color.accentColor.opacity(0.2) : Color.clear
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectedSample = sample
        }
    }
}

// MARK: - Compact Playback Controls
struct CompactPlaybackControlsView: View {
    @ObservedObject var audioPlayer = AudioPlayer.shared

    var body: some View {
        VStack(spacing: 4) {
            if let sample = audioPlayer.currentSample {
                // Now playing info
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundStyle(.accentColor)
                        .symbolEffect(.variableColor.iterative, isActive: audioPlayer.isPlaying)

                    Text(sample.filename)
                        .font(.caption)
                        .lineLimit(1)

                    Spacer()

                    Text(audioPlayer.formattedTime)
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)

                // Compact playback controls
                HStack(spacing: 16) {
                    Button(action: {
                        audioPlayer.togglePlayPause()
                    }) {
                        Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        audioPlayer.stop()
                    }) {
                        Image(systemName: "stop.circle")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Volume
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Slider(value: $audioPlayer.volume, in: 0...1)
                            .frame(width: 80)
                    }
                }
                .padding(.horizontal, 8)
            } else {
                Text("No sample playing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

#Preview {
    CompactModeView()
        .environmentObject(AppViewModel())
        .frame(width: 400, height: 600)
}

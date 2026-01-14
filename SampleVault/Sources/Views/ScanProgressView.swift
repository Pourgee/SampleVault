//
//  ScanProgressView.swift
//  SampleVault
//
//  Progress indicator for folder scanning
//

import SwiftUI

struct ScanProgressView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Animated progress indicator
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .controlSize(.large)

                if let progress = viewModel.scanProgress {
                    VStack(spacing: 8) {
                        Text("Scanning for audio files...")
                            .font(.headline)

                        if !progress.currentFile.isEmpty {
                            Text(progress.currentFile)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: 400)
                        }

                        // Progress stats
                        HStack(spacing: 16) {
                            StatLabel(
                                title: "Found",
                                value: "\(progress.filesFound)",
                                icon: "doc.text.magnifyingglass"
                            )

                            Divider()
                                .frame(height: 30)

                            StatLabel(
                                title: "Processed",
                                value: "\(progress.filesProcessed)",
                                icon: "checkmark.circle"
                            )

                            if progress.filesFound > 0 {
                                Divider()
                                    .frame(height: 30)

                                StatLabel(
                                    title: "Progress",
                                    value: "\(Int(Double(progress.filesProcessed) / Double(progress.filesFound) * 100))%",
                                    icon: "chart.bar"
                                )
                            }
                        }
                        .padding(.top, 8)

                        // Progress bar
                        if progress.filesFound > 0 {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 6)
                                        .cornerRadius(3)

                                    Rectangle()
                                        .fill(Color.accentColor)
                                        .frame(
                                            width: geometry.size.width * (Double(progress.filesProcessed) / Double(progress.filesFound)),
                                            height: 6
                                        )
                                        .cornerRadius(3)
                                        .animation(.linear(duration: 0.3), value: progress.filesProcessed)
                                }
                            }
                            .frame(height: 6)
                            .frame(maxWidth: 400)
                        }
                    }
                } else {
                    Text("Preparing to scan...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Cancel button
            Button("Cancel") {
                viewModel.cancelImport()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatLabel: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    ScanProgressView()
        .environmentObject({
            let vm = AppViewModel()
            vm.isScanning = true
            vm.scanProgress = FileScanner.ScanProgress(
                filesFound: 1000,
                filesProcessed: 350,
                currentFile: "kick_808_hard.wav",
                isComplete: false
            )
            return vm
        }())
        .frame(width: 800, height: 600)
}

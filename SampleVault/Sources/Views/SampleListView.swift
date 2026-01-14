//
//  SampleListView.swift
//  SampleVault
//
//  Main list view for displaying samples
//

import SwiftUI

struct SampleListView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(viewModel.filteredSamples) { sample in
                    SampleRow(sample: sample)
                        .background(
                            viewModel.selectedSample?.id == sample.id ?
                                Color.accentColor.opacity(0.2) : Color.clear
                        )
                        .onTapGesture {
                            viewModel.selectedSample = sample
                        }
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct SampleRow: View {
    @EnvironmentObject var viewModel: AppViewModel
    let sample: Sample

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Play indicator / category icon
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 36, height: 36)

                if let category = sample.category {
                    Text(category.icon)
                        .font(.title3)
                } else {
                    Image(systemName: "waveform")
                        .foregroundStyle(.secondary)
                }
            }

            // File info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sample.filename)
                        .font(.body)
                        .lineLimit(1)

                    if sample.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }

                    Spacer()

                    // Metadata badges
                    if let key = sample.key {
                        MetadataBadge(text: key, icon: "music.note")
                    }

                    if let bpm = sample.bpm {
                        MetadataBadge(text: "\(bpm)", icon: "metronome")
                    }

                    MetadataBadge(text: sample.formattedDuration, icon: "clock")
                }

                // Tags
                if !sample.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(sample.tags, id: \.self) { tag in
                                TagChip(tag: tag)
                            }
                        }
                    }
                }

                // File path (when hovering)
                if isHovering {
                    Text(sample.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            // Actions (visible on hover)
            if isHovering {
                HStack(spacing: 8) {
                    Button(action: {
                        Task {
                            await viewModel.toggleFavorite(sample)
                        }
                    }) {
                        Image(systemName: sample.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(sample.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        // Play sample (will implement in Phase 2)
                    }) {
                        Image(systemName: "play.circle")
                    }
                    .buttonStyle(.plain)

                    Menu {
                        Button("Show in Finder") {
                            // Show in Finder
                            NSWorkspace.shared.selectFile(
                                sample.path,
                                inFileViewerRootedAtPath: ""
                            )
                        }

                        Button("Add Tags...") {
                            // Show tag editor
                        }

                        Divider()

                        Button("Delete", role: .destructive) {
                            Task {
                                await viewModel.deleteSample(sample)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onDrag {
            // Provide file URL for drag-and-drop to Logic Pro
            let provider = NSItemProvider()
            provider.suggestedName = sample.filename

            // Add file URL
            if let url = URL(string: "file://\(sample.path)") {
                provider.registerFileRepresentation(
                    forTypeIdentifier: "public.file-url",
                    visibility: .all
                ) { completion in
                    completion(url, true, nil)
                    return nil
                }
            }

            return provider
        }
    }
}

struct MetadataBadge: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(4)
    }
}

struct TagChip: View {
    let tag: String

    var body: some View {
        Text(tag)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.2))
            .foregroundStyle(.accentColor)
            .cornerRadius(10)
    }
}

#Preview {
    let sample = Sample(
        filename: "kick_808_hard.wav",
        path: "/Users/test/Samples/Drums/kick_808_hard.wav",
        bookmarkData: Data(),
        fileSize: 1024000,
        duration: 42,
        bpm: 120,
        key: "C",
        category: .drums,
        subcategory: "Kicks",
        tags: ["punchy", "808"],
        isFavorite: true
    )

    return SampleRow(sample: sample)
        .environmentObject(AppViewModel())
        .padding()
        .frame(width: 800)
}

//
//  EmptyStateView.swift
//  SampleVault
//
//  Empty state when no samples are found
//

import SwiftUI

struct EmptyStateView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "music.note.list")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)

            // Message
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Action button
            if viewModel.samples.isEmpty {
                Button(action: {
                    Task {
                        await viewModel.importFolder()
                    }
                }) {
                    Label("Import Folder", systemImage: "folder.badge.plus")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button(action: {
                    viewModel.clearFilters()
                }) {
                    Label("Clear Filters", systemImage: "line.3.horizontal.decrease.circle")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            // Help text
            if viewModel.samples.isEmpty {
                VStack(spacing: 8) {
                    Text("Supported formats:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(Array(Sample.supportedExtensions), id: \.self) { ext in
                            Text(ext.uppercased())
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private var emptyStateTitle: String {
        if viewModel.samples.isEmpty {
            return "No Samples Yet"
        } else if !viewModel.searchQuery.isEmpty {
            return "No Results Found"
        } else {
            return "No Samples Match Filters"
        }
    }

    private var emptyStateMessage: String {
        if viewModel.samples.isEmpty {
            return "Import a folder containing audio samples to get started.\nSampleVault will automatically scan and organize your library."
        } else if !viewModel.searchQuery.isEmpty {
            return "Try adjusting your search query or clearing filters."
        } else {
            return "No samples match the current filters.\nTry adjusting or clearing your filters."
        }
    }
}

#Preview("No Samples") {
    EmptyStateView()
        .environmentObject(AppViewModel())
        .frame(width: 800, height: 600)
}

#Preview("No Results") {
    EmptyStateView()
        .environmentObject({
            let vm = AppViewModel()
            vm.searchQuery = "test search"
            return vm
        }())
        .frame(width: 800, height: 600)
}

//
//  ContentView.swift
//  SampleVault
//
//  Main application view
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Main content
            NavigationSplitView {
                // Sidebar
                CategorySidebar()
                    .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
            } detail: {
                // Main content area
                VStack(spacing: 0) {
                    // Search and filter bar
                    SearchBar()
                        .padding()

                    Divider()

                    // Sample list
                    if viewModel.isScanning {
                        ScanProgressView()
                    } else if viewModel.filteredSamples.isEmpty {
                        EmptyStateView()
                    } else {
                        SampleListView()
                    }
                }
            }
            .navigationTitle("SampleVault")
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button(action: {
                        Task {
                            await viewModel.importFolder()
                        }
                    }) {
                        Label("Import Folder", systemImage: "folder.badge.plus")
                    }

                    Divider()

                    Button(action: {
                        viewModel.clearFilters()
                    }) {
                        Label("Clear Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .disabled(viewModel.searchQuery.isEmpty &&
                             viewModel.selectedCategory == nil &&
                             !viewModel.filterFavoritesOnly)
                }
            }

            // Playback controls at bottom
            Divider()
            PlaybackControlsView()
                .environmentObject(viewModel)
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

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(AppViewModel())
        .frame(width: 1200, height: 800)
}

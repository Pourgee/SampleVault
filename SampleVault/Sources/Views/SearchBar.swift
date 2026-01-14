//
//  SearchBar.swift
//  SampleVault
//
//  Search and filter controls
//

import SwiftUI

struct SearchBar: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showFilters = false

    var body: some View {
        HStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search samples...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)

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

            // Filter button
            Button(action: {
                showFilters.toggle()
            }) {
                Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    .symbolVariant(showFilters ? .fill : .none)
            }
            .popover(isPresented: $showFilters, arrowEdge: .bottom) {
                FilterPanel()
                    .environmentObject(viewModel)
                    .frame(width: 300)
                    .padding()
            }

            // Sort menu
            Menu {
                Picker("Sort By", selection: $viewModel.sortOption) {
                    Label("Date Added", systemImage: "calendar").tag(SortOption.dateAdded)
                    Label("Name", systemImage: "textformat").tag(SortOption.name)
                    Label("Duration", systemImage: "clock").tag(SortOption.duration)
                    Label("BPM", systemImage: "metronome").tag(SortOption.bpm)
                    Label("Last Played", systemImage: "play.circle").tag(SortOption.lastPlayed)
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
        }
    }
}

struct FilterPanel: View {
    @EnvironmentObject var viewModel: AppViewModel

    @State private var bpmMin: Double = 60
    @State private var bpmMax: Double = 200
    @State private var useBPMFilter = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filters")
                .font(.headline)

            Divider()

            // BPM Range
            VStack(alignment: .leading, spacing: 8) {
                Toggle("BPM Range", isOn: $useBPMFilter)
                    .onChange(of: useBPMFilter) { _, enabled in
                        if enabled {
                            viewModel.filterBPMRange = Int(bpmMin)...Int(bpmMax)
                        } else {
                            viewModel.filterBPMRange = nil
                        }
                    }

                if useBPMFilter {
                    HStack {
                        Text("\(Int(bpmMin))")
                            .font(.caption)
                            .frame(width: 40)

                        Slider(value: $bpmMin, in: 60...200)
                            .onChange(of: bpmMin) { _, value in
                                if value > bpmMax {
                                    bpmMax = value
                                }
                                viewModel.filterBPMRange = Int(value)...Int(bpmMax)
                            }

                        Text("\(Int(bpmMax))")
                            .font(.caption)
                            .frame(width: 40)

                        Slider(value: $bpmMax, in: 60...200)
                            .onChange(of: bpmMax) { _, value in
                                if value < bpmMin {
                                    bpmMin = value
                                }
                                viewModel.filterBPMRange = Int(bpmMin)...Int(value)
                            }
                    }
                }
            }

            Divider()

            // Key filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Key")
                    .font(.subheadline)

                Picker("Key", selection: $viewModel.filterKey) {
                    Text("Any").tag(nil as String?)
                    Divider()
                    ForEach(musicKeys, id: \.self) { key in
                        Text(key).tag(key as String?)
                    }
                }
                .pickerStyle(.menu)
            }

            Divider()

            // Clear filters
            Button("Clear All Filters") {
                viewModel.clearFilters()
                useBPMFilter = false
                bpmMin = 60
                bpmMax = 200
            }
            .disabled(viewModel.searchQuery.isEmpty &&
                     viewModel.selectedCategory == nil &&
                     !viewModel.filterFavoritesOnly &&
                     viewModel.filterBPMRange == nil &&
                     viewModel.filterKey == nil)
        }
    }

    private let musicKeys = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
        "Cm", "C#m", "Dm", "D#m", "Em", "Fm", "F#m", "Gm", "G#m", "Am", "A#m", "Bm"
    ]
}

#Preview {
    SearchBar()
        .environmentObject(AppViewModel())
        .padding()
        .frame(width: 600)
}

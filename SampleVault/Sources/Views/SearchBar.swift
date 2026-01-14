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
    @State private var showRecentSearches = false
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Search field with recent searches dropdown
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search samples...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                        .focused($isSearchFieldFocused)
                        .onSubmit {
                            Task {
                                await viewModel.trackSearch()
                            }
                        }

                    if !viewModel.searchQuery.isEmpty {
                        Button(action: {
                            viewModel.searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    // Recent searches menu button
                    if !viewModel.recentSearches.isEmpty {
                        Button(action: {
                            showRecentSearches.toggle()
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showRecentSearches, arrowEdge: .bottom) {
                            RecentSearchesView()
                                .environmentObject(viewModel)
                                .frame(width: 350)
                        }
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
            }

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

struct RecentSearchesView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Recent Searches")
                    .font(.headline)

                Spacer()

                Button(action: {
                    Task {
                        await viewModel.clearRecentSearches()
                    }
                }) {
                    Text("Clear All")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Recent searches list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentSearches) { search in
                        Button(action: {
                            Task {
                                await viewModel.applyRecentSearch(search)
                                dismiss()
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)

                                    Text(search.query)
                                        .font(.body)
                                        .lineLimit(1)

                                    Spacer()

                                    Text("\(search.resultCount)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if !search.filters.description.isEmpty {
                                    Text(search.filters.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(
                            Color.accentColor.opacity(0)
                        )
                        .onHover { isHovered in
                            if isHovered {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }

                        if search.id != viewModel.recentSearches.last?.id {
                            Divider()
                                .padding(.leading)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }
}

#Preview {
    SearchBar()
        .environmentObject(AppViewModel())
        .padding()
        .frame(width: 600)
}

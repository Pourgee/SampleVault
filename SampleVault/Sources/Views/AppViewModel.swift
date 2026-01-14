//
//  AppViewModel.swift
//  SampleVault
//
//  Main view model managing app state
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppViewModel: ObservableObject {
    // MARK: - Published State
    @Published var samples: [Sample] = []
    @Published var filteredSamples: [Sample] = []
    @Published var selectedCategory: CategoryType?
    @Published var selectedSample: Sample?
    @Published var searchQuery: String = ""
    @Published var isScanning: Bool = false
    @Published var scanProgress: FileScanner.ScanProgress?
    @Published var availableTags: [Tag] = []
    @Published var filterBPMRange: ClosedRange<Int>?
    @Published var filterKey: String?
    @Published var filterFavoritesOnly: Bool = false
    @Published var sortOption: SortOption = .dateAdded
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let database = DatabaseManager.shared
    private let scanner = FileScanner.shared
    private let bookmarkManager = BookmarkManager.shared

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupObservers()
        Task {
            await initializeDatabase()
            await loadInitialData()
        }
    }

    // MARK: - Setup
    private func setupObservers() {
        // Auto-filter when search or filters change
        Publishers.CombineLatest4(
            $searchQuery,
            $selectedCategory,
            $filterFavoritesOnly,
            $sortOption
        )
        .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
        .sink { [weak self] _, _, _, _ in
            Task { @MainActor in
                await self?.applyFilters()
            }
        }
        .store(in: &cancellables)
    }

    private func initializeDatabase() async {
        do {
            try await database.initialize()
        } catch {
            errorMessage = "Failed to initialize database: \(error.localizedDescription)"
        }
    }

    private func loadInitialData() async {
        do {
            samples = try await database.getAllSamples()
            availableTags = try await database.getAllTags()
            await applyFilters()
        } catch {
            errorMessage = "Failed to load samples: \(error.localizedDescription)"
        }
    }

    // MARK: - Import Operations
    func importFolder() async {
        guard let folderURL = await bookmarkManager.selectFolder() else {
            return
        }

        do {
            let bookmarkData = try await bookmarkManager.createBookmark(for: folderURL)
            isScanning = true

            let newSamples = try await scanner.scanFolder(folderURL, bookmarkData: bookmarkData) { progress in
                Task { @MainActor in
                    self.scanProgress = progress
                }
            }

            // Insert into database
            try await database.insertSamples(newSamples)

            // Reload all samples
            samples = try await database.getAllSamples()
            await applyFilters()

            isScanning = false
            scanProgress = nil

        } catch {
            isScanning = false
            scanProgress = nil
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    func cancelImport() {
        Task {
            await scanner.cancelScan()
            isScanning = false
            scanProgress = nil
        }
    }

    // MARK: - Search and Filter
    private func applyFilters() async {
        do {
            filteredSamples = try await database.searchSamples(
                query: searchQuery.isEmpty ? nil : searchQuery,
                category: selectedCategory,
                isFavorite: filterFavoritesOnly ? true : nil,
                bpmRange: filterBPMRange,
                key: filterKey,
                sortBy: sortOption
            )
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
    }

    func selectCategory(_ category: CategoryType?) {
        selectedCategory = category
    }

    func clearFilters() {
        searchQuery = ""
        selectedCategory = nil
        filterBPMRange = nil
        filterKey = nil
        filterFavoritesOnly = false
    }

    // MARK: - Sample Operations
    func toggleFavorite(_ sample: Sample) async {
        var updatedSample = sample
        updatedSample.isFavorite.toggle()

        do {
            try await database.updateSample(updatedSample)

            // Update local state
            if let index = samples.firstIndex(where: { $0.id == sample.id }) {
                samples[index] = updatedSample
            }
            await applyFilters()
        } catch {
            errorMessage = "Failed to update favorite: \(error.localizedDescription)"
        }
    }

    func addTag(_ tagName: String, to sample: Sample) async {
        var updatedSample = sample
        if !updatedSample.tags.contains(tagName) {
            updatedSample.tags.append(tagName)

            do {
                try await database.updateSample(updatedSample)

                if let index = samples.firstIndex(where: { $0.id == sample.id }) {
                    samples[index] = updatedSample
                }
                await applyFilters()
            } catch {
                errorMessage = "Failed to add tag: \(error.localizedDescription)"
            }
        }
    }

    func removeTag(_ tagName: String, from sample: Sample) async {
        var updatedSample = sample
        updatedSample.tags.removeAll { $0 == tagName }

        do {
            try await database.updateSample(updatedSample)

            if let index = samples.firstIndex(where: { $0.id == sample.id }) {
                samples[index] = updatedSample
            }
            await applyFilters()
        } catch {
            errorMessage = "Failed to remove tag: \(error.localizedDescription)"
        }
    }

    func deleteSample(_ sample: Sample) async {
        do {
            try await database.deleteSample(id: sample.id)
            samples.removeAll { $0.id == sample.id }
            await applyFilters()
        } catch {
            errorMessage = "Failed to delete sample: \(error.localizedDescription)"
        }
    }

    func incrementPlayCount(for sample: Sample) async {
        do {
            try await database.updatePlayCount(id: sample.id)
        } catch {
            print("Failed to update play count: \(error)")
        }
    }

    // MARK: - Statistics
    var totalSampleCount: Int {
        samples.count
    }

    var favoritesCount: Int {
        samples.filter { $0.isFavorite }.count
    }

    func categoryCount(_ category: CategoryType) -> Int {
        samples.filter { $0.category == category }.count
    }
}

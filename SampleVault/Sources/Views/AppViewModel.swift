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

    // Batch selection
    @Published var isSelectionMode: Bool = false
    @Published var selectedSamples: Set<UUID> = []

    // Smart folders and recent searches
    @Published var smartFolders: [SmartFolder] = []
    @Published var recentSearches: [RecentSearch] = []
    @Published var selectedSmartFolder: SmartFolder?

    // Analysis
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: AnalysisProgress?
    @Published var analysisStats: (analyzed: Int, unanalyzed: Int, total: Int) = (0, 0, 0)

    // MARK: - Dependencies
    private let database = DatabaseManager.shared
    private let scanner = FileScanner.shared
    private let bookmarkManager = BookmarkManager.shared
    private let analysisQueue = AnalysisQueue.shared

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
            smartFolders = try await database.getAllSmartFolders()
            recentSearches = try await database.getRecentSearches()
            await applyFilters()
            await updateAnalysisStats()
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
    func applyFilters() async {
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

    // MARK: - Batch Operations
    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedSamples.removeAll()
        }
    }

    func toggleSampleSelection(_ sampleId: UUID) {
        if selectedSamples.contains(sampleId) {
            selectedSamples.remove(sampleId)
        } else {
            selectedSamples.insert(sampleId)
        }
    }

    func selectAll() {
        selectedSamples = Set(filteredSamples.map { $0.id })
    }

    func deselectAll() {
        selectedSamples.removeAll()
    }

    var selectedSampleObjects: [Sample] {
        samples.filter { selectedSamples.contains($0.id) }
    }

    func batchAddTags(_ tagNames: [String]) async {
        let samplesToUpdate = selectedSampleObjects

        for sample in samplesToUpdate {
            var updatedSample = sample
            for tagName in tagNames {
                if !updatedSample.tags.contains(tagName) {
                    updatedSample.tags.append(tagName)
                }
            }

            do {
                try await database.updateSample(updatedSample)
                if let index = samples.firstIndex(where: { $0.id == sample.id }) {
                    samples[index] = updatedSample
                }
            } catch {
                print("Failed to update sample: \(error)")
            }
        }

        await applyFilters()
    }

    func batchRemoveTags(_ tagNames: [String]) async {
        let samplesToUpdate = selectedSampleObjects

        for sample in samplesToUpdate {
            var updatedSample = sample
            updatedSample.tags.removeAll { tagNames.contains($0) }

            do {
                try await database.updateSample(updatedSample)
                if let index = samples.firstIndex(where: { $0.id == sample.id }) {
                    samples[index] = updatedSample
                }
            } catch {
                print("Failed to update sample: \(error)")
            }
        }

        await applyFilters()
    }

    func batchSetCategory(_ category: CategoryType?, subcategory: String? = nil) async {
        let samplesToUpdate = selectedSampleObjects

        for sample in samplesToUpdate {
            var updatedSample = sample
            updatedSample.category = category
            updatedSample.subcategory = subcategory

            do {
                try await database.updateSample(updatedSample)
                if let index = samples.firstIndex(where: { $0.id == sample.id }) {
                    samples[index] = updatedSample
                }
            } catch {
                print("Failed to update sample: \(error)")
            }
        }

        await applyFilters()
    }

    func batchToggleFavorite() async {
        let samplesToUpdate = selectedSampleObjects

        for sample in samplesToUpdate {
            var updatedSample = sample
            updatedSample.isFavorite.toggle()

            do {
                try await database.updateSample(updatedSample)
                if let index = samples.firstIndex(where: { $0.id == sample.id }) {
                    samples[index] = updatedSample
                }
            } catch {
                print("Failed to update sample: \(error)")
            }
        }

        await applyFilters()
    }

    func batchDelete() async {
        let samplesToDelete = selectedSampleObjects

        for sample in samplesToDelete {
            do {
                try await database.deleteSample(id: sample.id)
                samples.removeAll { $0.id == sample.id }
            } catch {
                print("Failed to delete sample: \(error)")
            }
        }

        selectedSamples.removeAll()
        await applyFilters()
    }

    // MARK: - Smart Folder Operations
    func getCurrentFilters() -> SearchFilters {
        SearchFilters(
            query: searchQuery.isEmpty ? nil : searchQuery,
            category: selectedCategory,
            tags: nil, // Would need UI for tag filtering
            isFavorite: filterFavoritesOnly ? true : nil,
            bpmMin: filterBPMRange?.lowerBound,
            bpmMax: filterBPMRange?.upperBound,
            key: filterKey,
            sortBy: sortOption
        )
    }

    func createSmartFolder(name: String, icon: String = "folder.badge.gearshape") async {
        let filters = getCurrentFilters()
        let smartFolder = SmartFolder(name: name, icon: icon, filters: filters)

        do {
            try await database.insertSmartFolder(smartFolder)
            smartFolders = try await database.getAllSmartFolders()
        } catch {
            errorMessage = "Failed to create smart folder: \(error.localizedDescription)"
        }
    }

    func applySmartFolder(_ folder: SmartFolder) async {
        selectedSmartFolder = folder

        // Apply all filters from the smart folder
        searchQuery = folder.filters.query ?? ""
        selectedCategory = folder.filters.category
        filterFavoritesOnly = folder.filters.isFavorite ?? false

        if let bpmMin = folder.filters.bpmMin, let bpmMax = folder.filters.bpmMax {
            filterBPMRange = bpmMin...bpmMax
        } else {
            filterBPMRange = nil
        }

        filterKey = folder.filters.key
        sortOption = folder.filters.sortBy ?? .dateAdded

        await applyFilters()
    }

    func deleteSmartFolder(_ folder: SmartFolder) async {
        do {
            try await database.deleteSmartFolder(id: folder.id)
            smartFolders = try await database.getAllSmartFolders()
            if selectedSmartFolder?.id == folder.id {
                selectedSmartFolder = nil
            }
        } catch {
            errorMessage = "Failed to delete smart folder: \(error.localizedDescription)"
        }
    }

    // MARK: - Recent Search Operations
    func trackSearch() async {
        guard !searchQuery.isEmpty || selectedCategory != nil || filterFavoritesOnly else {
            return
        }

        let filters = getCurrentFilters()
        let search = RecentSearch(
            query: searchQuery.isEmpty ? "Filter search" : searchQuery,
            filters: filters,
            resultCount: filteredSamples.count
        )

        do {
            try await database.insertRecentSearch(search)
            recentSearches = try await database.getRecentSearches()
        } catch {
            print("Failed to track search: \(error)")
        }
    }

    func applyRecentSearch(_ search: RecentSearch) async {
        searchQuery = search.query == "Filter search" ? "" : search.query
        selectedCategory = search.filters.category
        filterFavoritesOnly = search.filters.isFavorite ?? false

        if let bpmMin = search.filters.bpmMin, let bpmMax = search.filters.bpmMax {
            filterBPMRange = bpmMin...bpmMax
        } else {
            filterBPMRange = nil
        }

        filterKey = search.filters.key
        sortOption = search.filters.sortBy ?? .dateAdded

        await applyFilters()
    }

    func clearRecentSearches() async {
        do {
            try await database.clearRecentSearches()
            recentSearches = []
        } catch {
            errorMessage = "Failed to clear recent searches: \(error.localizedDescription)"
        }
    }

    // MARK: - Audio Analysis Operations
    func startAnalysis() async {
        // Observe analysis queue progress
        Task {
            for await _ in Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().values {
                if analysisQueue.isAnalyzing {
                    isAnalyzing = true
                    analysisProgress = analysisQueue.progress
                } else {
                    isAnalyzing = false
                    analysisProgress = nil
                    // Reload samples to get updated BPM/key data
                    do {
                        samples = try await database.getAllSamples()
                        await applyFilters()
                        await updateAnalysisStats()
                    } catch {
                        print("Failed to reload samples after analysis: \(error)")
                    }
                    break
                }
            }
        }

        await analysisQueue.analyzeUnanalyzedSamples()
    }

    func reanalyzeSelected() async {
        let samplesToAnalyze = selectedSampleObjects

        // Observe analysis queue progress
        Task {
            for await _ in Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().values {
                if analysisQueue.isAnalyzing {
                    isAnalyzing = true
                    analysisProgress = analysisQueue.progress
                } else {
                    isAnalyzing = false
                    analysisProgress = nil
                    // Reload samples
                    do {
                        samples = try await database.getAllSamples()
                        await applyFilters()
                        await updateAnalysisStats()
                    } catch {
                        print("Failed to reload samples after analysis: \(error)")
                    }
                    break
                }
            }
        }

        await analysisQueue.reanalyzeSamples(samplesToAnalyze)
    }

    func cancelAnalysis() {
        analysisQueue.cancelAnalysis()
        isAnalyzing = false
        analysisProgress = nil
    }

    func updateAnalysisStats() async {
        analysisStats = await analysisQueue.getAnalysisStats()
    }
}

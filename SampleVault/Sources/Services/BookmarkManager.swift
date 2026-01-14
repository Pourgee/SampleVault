//
//  BookmarkManager.swift
//  SampleVault
//
//  Handles security-scoped bookmarks for sandboxed access to user files
//

import Foundation
import AppKit

actor BookmarkManager {
    static let shared = BookmarkManager()

    private var activeBookmarks: [URL: Data] = [:]

    private init() {}

    // MARK: - Bookmark Creation
    func createBookmark(for url: URL) throws -> Data {
        let options: URL.BookmarkCreationOptions = [.withSecurityScope, .securityScopeAllowOnlyReadAccess]

        do {
            let bookmarkData = try url.bookmarkData(
                options: options,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            activeBookmarks[url] = bookmarkData
            return bookmarkData
        } catch {
            throw BookmarkError.creationFailed(error)
        }
    }

    // MARK: - Bookmark Resolution
    func resolveBookmark(_ bookmarkData: Data) throws -> URL {
        var isStale = false
        let options: URL.BookmarkResolutionOptions = [.withSecurityScope]

        do {
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: options,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                // Recreate bookmark if stale
                let newBookmarkData = try createBookmark(for: url)
                activeBookmarks[url] = newBookmarkData
                throw BookmarkError.staleBookmark(url)
            }

            activeBookmarks[url] = bookmarkData
            return url
        } catch {
            throw BookmarkError.resolutionFailed(error)
        }
    }

    // MARK: - Security-Scoped Access
    func accessSecurityScopedResource<T>(
        _ bookmarkData: Data,
        _ block: (URL) throws -> T
    ) throws -> T {
        let url = try resolveBookmark(bookmarkData)

        guard url.startAccessingSecurityScopedResource() else {
            throw BookmarkError.accessDenied(url)
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        do {
            return try block(url)
        } catch {
            throw BookmarkError.operationFailed(error)
        }
    }

    func accessSecurityScopedResourceAsync<T>(
        _ bookmarkData: Data,
        _ block: (URL) async throws -> T
    ) async throws -> T {
        let url = try resolveBookmark(bookmarkData)

        guard url.startAccessingSecurityScopedResource() else {
            throw BookmarkError.accessDenied(url)
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        do {
            return try await block(url)
        } catch {
            throw BookmarkError.operationFailed(error)
        }
    }

    // MARK: - Folder Selection
    @MainActor
    func selectFolder() async -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.message = "Select a folder containing audio samples"
        panel.prompt = "Select Folder"

        let response = await panel.beginSheetModal(for: NSApp.mainWindow!)

        guard response == .OK, let url = panel.url else {
            return nil
        }

        return url
    }

    // MARK: - Cleanup
    func releaseBookmark(for url: URL) {
        activeBookmarks.removeValue(forKey: url)
    }

    func releaseAllBookmarks() {
        activeBookmarks.removeAll()
    }
}

// MARK: - Errors
enum BookmarkError: Error, LocalizedError {
    case creationFailed(Error)
    case resolutionFailed(Error)
    case staleBookmark(URL)
    case accessDenied(URL)
    case operationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .creationFailed(let error):
            return "Failed to create bookmark: \(error.localizedDescription)"
        case .resolutionFailed(let error):
            return "Failed to resolve bookmark: \(error.localizedDescription)"
        case .staleBookmark(let url):
            return "Bookmark is stale for: \(url.path)"
        case .accessDenied(let url):
            return "Access denied to: \(url.path)"
        case .operationFailed(let error):
            return "Operation failed: \(error.localizedDescription)"
        }
    }
}

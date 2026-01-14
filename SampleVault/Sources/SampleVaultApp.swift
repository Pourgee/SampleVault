//
//  SampleVaultApp.swift
//  SampleVault
//
//  Main app entry point
//

import SwiftUI

@main
struct SampleVaultApp: App {
    @StateObject private var viewModel = AppViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Import Folder...") {
                    Task {
                        await viewModel.importFolder()
                    }
                }
                .keyboardShortcut("i", modifiers: [.command])
            }

            CommandGroup(replacing: .help) {
                Button("SampleVault Help") {
                    // Open help
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app appearance
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

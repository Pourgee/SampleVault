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
    @AppStorage("compactMode") private var compactMode = false

    var body: some Scene {
        WindowGroup {
            Group {
                if compactMode {
                    CompactModeView()
                        .environmentObject(viewModel)
                        .frame(minWidth: 400, minHeight: 300)
                } else {
                    ContentView()
                        .environmentObject(viewModel)
                        .frame(minWidth: 900, minHeight: 600)
                }
            }
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
    private let hotkeyManager = HotkeyManager.shared
    @AppStorage("floatOnTop") private var floatOnTop = false
    @AppStorage("compactMode") private var compactMode = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app appearance
        NSApp.appearance = NSAppearance(named: .darkAqua)

        // Register global hotkey for show/hide window
        Task { @MainActor in
            hotkeyManager.registerShowHideHotkey { [weak self] in
                self?.toggleMainWindow()
            }
        }

        // Apply float-on-top setting
        applyFloatOnTopSetting()

        // Observe preference changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregisterAllHotkeys()
    }

    // MARK: - Window Management

    @objc private func toggleMainWindow() {
        if let window = NSApp.windows.first {
            if window.isVisible {
                window.orderOut(nil)
                NSApp.hide(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    @objc private func settingsChanged() {
        applyFloatOnTopSetting()
        applyCompactModeSetting()
    }

    private func applyFloatOnTopSetting() {
        guard let window = NSApp.windows.first else { return }

        if floatOnTop {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        } else {
            window.level = .normal
            window.collectionBehavior = [.managed, .fullScreenPrimary]
        }
    }

    private func applyCompactModeSetting() {
        guard let window = NSApp.windows.first else { return }

        // Adjust window size based on compact mode
        if compactMode {
            let newFrame = NSRect(
                x: window.frame.origin.x,
                y: window.frame.origin.y,
                width: 400,
                height: 600
            )
            window.setFrame(newFrame, display: true, animate: true)
        }
    }
}

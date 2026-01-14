//
//  HotkeyManager.swift
//  SampleVault
//
//  Global hotkey management service
//

import Foundation
import AppKit
import Carbon

/// Manager for registering and handling global keyboard shortcuts
@MainActor
class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()

    private var eventMonitor: Any?
    private var hotKeyRef: EventHotKeyRef?
    private var hotkeyHandler: (() -> Void)?

    private init() {}

    // MARK: - Hotkey Registration

    /// Registers a global hotkey (default: Option+Command+S)
    func registerShowHideHotkey(handler: @escaping () -> Void) {
        self.hotkeyHandler = handler

        // Use local event monitor for now (global requires accessibility permissions)
        // Command+Option+S
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Command (⌘) + Option (⌥) + S
            if event.modifierFlags.contains([.command, .option]) &&
               event.charactersIgnoringModifiers == "s" {
                self?.hotkeyHandler?()
                return nil // Consume event
            }
            return event
        }
    }

    /// Registers space bar for play/pause when app is active
    func registerPlayPauseHotkey(handler: @escaping () -> Void) {
        // Space bar is handled in PlaybackControlsView via .onKeyPress
        // This is a placeholder for future global hotkey support
    }

    /// Unregisters all hotkeys
    func unregisterAllHotkeys() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        if hotKeyRef != nil {
            // Unregister Carbon hotkey if used
            hotKeyRef = nil
        }

        hotkeyHandler = nil
    }

    deinit {
        unregisterAllHotkeys()
    }

    // MARK: - Global Event Monitor (requires accessibility permissions)

    /// Registers a truly global hotkey using NSEvent.addGlobalMonitorForEvents
    /// Note: This requires accessibility permissions from the user
    func registerGlobalHotkey(handler: @escaping () -> Void) {
        self.hotkeyHandler = handler

        // Check if we have accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)

        if accessibilityEnabled {
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                // Command (⌘) + Option (⌥) + S
                if event.modifierFlags.contains([.command, .option]) &&
                   event.charactersIgnoringModifiers == "s" {
                    self?.hotkeyHandler?()
                }
            }
        } else {
            print("Accessibility permissions not granted for global hotkeys")
            // Fall back to local monitor
            registerShowHideHotkey(handler: handler)
        }
    }

    // MARK: - Helper Methods

    /// Checks if accessibility permissions are granted
    func hasAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Requests accessibility permissions from the user
    func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }
}

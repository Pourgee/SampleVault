//
//  SettingsView.swift
//  SampleVault
//
//  Application settings
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @AppStorage("floatOnTop") private var floatOnTop = false
    @AppStorage("compactMode") private var compactMode = false
    @AppStorage("autoAnalyze") private var autoAnalyze = true
    @AppStorage("showWaveforms") private var showWaveforms = true

    var body: some View {
        TabView {
            GeneralSettings(
                floatOnTop: $floatOnTop,
                compactMode: $compactMode
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }

            AnalysisSettings(
                autoAnalyze: $autoAnalyze
            )
            .tabItem {
                Label("Analysis", systemImage: "waveform.path")
            }

            AppearanceSettings(
                showWaveforms: $showWaveforms
            )
            .tabItem {
                Label("Appearance", systemImage: "paintbrush")
            }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettings: View {
    @Binding var floatOnTop: Bool
    @Binding var compactMode: Bool

    var body: some View {
        Form {
            Section("Window") {
                Toggle("Float on top of other windows", isOn: $floatOnTop)
                    .help("Keep SampleVault visible above other applications")

                Toggle("Compact mode", isOn: $compactMode)
                    .help("Minimize window footprint for better workflow")
            }

            Section("Global Shortcuts") {
                LabeledContent("Show/Hide Window") {
                    Text("⌥⌘S")
                        .font(.body.monospaced())
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Play/Pause") {
                    Text("Space")
                        .font(.body.monospaced())
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Stop") {
                    Text("Esc")
                        .font(.body.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AnalysisSettings: View {
    @Binding var autoAnalyze: Bool

    var body: some View {
        Form {
            Section("Audio Analysis") {
                Toggle("Auto-analyze BPM and key", isOn: $autoAnalyze)
                    .help("Automatically detect BPM and musical key when importing samples")

                Text("Analysis runs in the background and may take time for large libraries.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Performance") {
                LabeledContent("Cache waveforms") {
                    Text("Enabled")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Database optimization") {
                    Button("Optimize Now") {
                        // Run VACUUM on database
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AppearanceSettings: View {
    @Binding var showWaveforms: Bool

    var body: some View {
        Form {
            Section("Display") {
                Toggle("Show waveforms in sample list", isOn: $showWaveforms)

                Picker("Theme", selection: .constant("dark")) {
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                    Text("Auto").tag("auto")
                }
                .disabled(true)
                .help("Currently locked to Dark mode (matches Logic Pro)")
            }

            Section("Sample List") {
                Picker("Row height", selection: .constant("medium")) {
                    Text("Compact").tag("compact")
                    Text("Medium").tag("medium")
                    Text("Large").tag("large")
                }

                Toggle("Show file paths on hover", isOn: .constant(true))
                    .disabled(true)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.accentColor)

            VStack(spacing: 4) {
                Text("SampleVault")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("A native macOS application for music producers\nto catalog, search, and preview audio samples.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .padding(.horizontal, 40)

            VStack(spacing: 8) {
                Link("Documentation", destination: URL(string: "https://github.com/samplevault")!)
                Link("Report an Issue", destination: URL(string: "https://github.com/samplevault/issues")!)
            }
            .font(.callout)

            Spacer()

            Text("© 2026 SampleVault. All rights reserved.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
}

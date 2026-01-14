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

            TagManagementView()
                .tabItem {
                    Label("Tags", systemImage: "tag")
                }
                .environmentObject(viewModel)

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 600, height: 500)
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
    @EnvironmentObject var viewModel: AppViewModel
    @State private var stats: (analyzed: Int, unanalyzed: Int, total: Int) = (0, 0, 0)

    var body: some View {
        Form {
            Section("Audio Analysis") {
                Toggle("Auto-analyze BPM and key", isOn: $autoAnalyze)
                    .help("Automatically detect BPM and musical key when importing samples")

                Text("Analysis runs in the background and may take time for large libraries.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Analysis Status") {
                LabeledContent("Total Samples") {
                    Text("\(stats.total)")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Analyzed") {
                    HStack {
                        Text("\(stats.analyzed)")
                            .foregroundStyle(.secondary)
                        if stats.total > 0 {
                            Text("(\(Int(Double(stats.analyzed) / Double(stats.total) * 100))%)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                LabeledContent("Unanalyzed") {
                    Text("\(stats.unanalyzed)")
                        .foregroundStyle(stats.unanalyzed > 0 ? .orange : .secondary)
                }
            }

            Section("Actions") {
                Button(action: {
                    Task {
                        await viewModel.startAnalysis()
                        await refreshStats()
                    }
                }) {
                    Label("Analyze Unanalyzed Samples", systemImage: "waveform.circle")
                }
                .disabled(stats.unanalyzed == 0 || viewModel.isAnalyzing)

                Button(action: {
                    Task {
                        if viewModel.isSelectionMode && !viewModel.selectedSamples.isEmpty {
                            await viewModel.reanalyzeSelected()
                        }
                        await refreshStats()
                    }
                }) {
                    Label("Re-analyze Selected Samples", systemImage: "arrow.clockwise")
                }
                .disabled(!viewModel.isSelectionMode || viewModel.selectedSamples.isEmpty || viewModel.isAnalyzing)

                if viewModel.isAnalyzing {
                    Button(action: {
                        viewModel.cancelAnalysis()
                    }) {
                        Label("Cancel Analysis", systemImage: "xmark.circle")
                    }
                    .foregroundStyle(.red)
                }
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
        .onAppear {
            Task {
                await refreshStats()
            }
        }
    }

    private func refreshStats() async {
        stats = await AnalysisQueue.shared.getAnalysisStats()
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

struct TagManagementView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var tags: [Tag] = []
    @State private var newTagName: String = ""
    @State private var newTagColor: Color = .blue
    @State private var showingNewTag: Bool = false
    @State private var tagToDelete: Tag?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tag Management")
                .font(.headline)
                .padding(.bottom, 4)

            Text("Manage your sample tags. Tags help organize and find samples quickly.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            // Tag list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(tags, id: \.id) { tag in
                        HStack {
                            Circle()
                                .fill(tag.color.flatMap { Color(hex: $0) } ?? .gray)
                                .frame(width: 12, height: 12)

                            Text(tag.name)
                                .font(.body)

                            if !tag.isUserCreated {
                                Text("Default")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                            }

                            Spacer()

                            // Usage count
                            Text("\(tagUsageCount(tag.name)) samples")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            // Delete button (only for user-created tags)
                            if tag.isUserCreated {
                                Button(action: {
                                    tagToDelete = tag
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(6)
                    }
                }
            }

            Divider()

            // Add new tag
            if showingNewTag {
                HStack {
                    ColorPicker("", selection: $newTagColor)
                        .labelsHidden()
                        .frame(width: 40)

                    TextField("Tag name", text: $newTagName)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        createNewTag()
                    }
                    .buttonStyle(.bordered)
                    .disabled(newTagName.isEmpty)

                    Button("Cancel") {
                        showingNewTag = false
                        newTagName = ""
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Button(action: {
                    showingNewTag = true
                }) {
                    Label("Create New Tag", systemImage: "plus.circle")
                }
            }
        }
        .padding()
        .onAppear {
            loadTags()
        }
        .alert("Delete Tag", isPresented: .constant(tagToDelete != nil)) {
            Button("Cancel", role: .cancel) {
                tagToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let tag = tagToDelete {
                    deleteTag(tag)
                }
            }
        } message: {
            if let tag = tagToDelete {
                Text("Are you sure you want to delete the tag '\(tag.name)'? This will remove it from all samples.")
            }
        }
    }

    private func loadTags() {
        Task {
            tags = try await DatabaseManager.shared.getAllTags()
        }
    }

    private func createNewTag() {
        guard !newTagName.isEmpty else { return }

        let tag = Tag(
            name: newTagName.lowercased(),
            color: newTagColor.toHex(),
            isUserCreated: true
        )

        Task {
            do {
                try await DatabaseManager.shared.insertTag(tag)
                loadTags()

                newTagName = ""
                showingNewTag = false
            } catch {
                print("Failed to create tag: \(error)")
            }
        }
    }

    private func deleteTag(_ tag: Tag) {
        Task {
            do {
                try await DatabaseManager.shared.deleteTag(name: tag.name)
                loadTags()
                tagToDelete = nil
            } catch {
                print("Failed to delete tag: \(error)")
            }
        }
    }

    private func tagUsageCount(_ tagName: String) -> Int {
        viewModel.samples.filter { $0.tags.contains(tagName) }.count
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
}
